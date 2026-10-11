#!/usr/bin/env python3
"""Offline Nix/Phoenix/Postgres/browser execution; no host database or socket mounts.

Prepare from an immutable local source revision and *existing* warm dependencies.
Every invocation gets a disposable full copy, a private network/PID namespace and
new PostgreSQL cluster. Never evaluates Nix or downloads inside the sandbox.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import time

from candidate import Blocked, command, digest, save

CACHES = ['web/deps', 'web/_build', 'packages/live_query/deps',
          'packages/live_query/_build', 'acceptance-tests/node_modules']


def tracked_hashes(root, names):
    return {n: hashlib.sha256((root / n).read_bytes()).hexdigest() for n in names
            if (root / n).is_file()}


def cache_digest(source):
    return digest({name: tracked_hashes(source / name,
        [str(p.relative_to(source / name)) for p in (source / name).rglob('*') if p.is_file()])
        for name in CACHES})


def prepare(root, repository, sha, discovery, bwrap):
    root, repository = Path(root).resolve(), Path(repository).resolve()
    if command(['git', 'rev-parse', sha], repository) != sha:
        raise Blocked('Full source SHA required')
    root.mkdir()
    source = root / 'source'
    source.mkdir()
    archive = root / 'source.tar'
    with archive.open('wb') as stream:
        subprocess.run(['git', 'archive', sha], cwd=repository, stdout=stream, check=True)
    with tarfile.open(archive) as stream:
        stream.extractall(source, filter='data')
    names = command(['git', 'ls-tree', '-r', '--name-only', sha], repository).splitlines()
    for name in CACHES:
        shutil.copytree(repository / name, source / name, symlinks=True, dirs_exist_ok=True)
    home = root / 'home'
    home.mkdir()
    shutil.copytree('/tmp/home/.mix', home / '.mix', symlinks=True)
    env = json.loads(Path(discovery).read_text())
    env = {k: v for k, v in env.items() if v}
    env['PATH'] = ':'.join(p for p in env['PATH'].split(':') if p.startswith('/nix/store/')) + ':/usr/bin:/bin'
    env.update(HOME='/home/runner', USER='runner', MIX_HOME='/home/runner/.mix',
               HEX_HOME='/home/runner/.hex', MIX_ENV='test', LANG='C.UTF-8', LC_ALL='C.UTF-8',
               ELIXIR_ERL_OPTIONS='+S 4:4 +fnu', PGHOST='/tmp/pg', PGPORT='5432', PGUSER='runner',
               MEMBA_POSTGRES_PORT='5432', MEMBA_POSTGRES_OWNER='dev', MEMBA_DEVENV_SHELL='1',
               PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD='1', ACCEPTANCE_LOG_PROGRESS='true')
    etc = root / 'etc'
    etc.mkdir()
    (etc / 'passwd').write_text(f'runner:x:{os.getuid()}:{os.getgid()}:runner:/home/runner:/bin/bash\n')
    (etc / 'group').write_text(f'runner:x:{os.getgid()}:\n')
    (etc / 'hosts').write_text('127.0.0.1 candidate\n127.0.0.1 localhost lvh.me kmc.lvh.me npc.lvh.me nelson.lvh.me\n')
    (etc / 'nsswitch.conf').write_text('hosts: files\npasswd: files\ngroup: files\n')
    (etc / 'alternatives').mkdir()
    (etc / 'alternatives' / 'which').symlink_to('/usr/bin/which.debianutils')
    save(root / 'runtime.json', {'source_sha': sha, 'files': tracked_hashes(source, names),
                               'etc_digest': digest(tracked_hashes(etc, [str(p.relative_to(etc)) for p in etc.rglob('*') if p.is_file()])),
                               'cache_digest': cache_digest(source),
                               'env': env, 'bwrap': str(Path(bwrap).resolve()),
                               'dependency_policy': 'warm private copies, no network; no host secrets or services'})


def node_lifecycle_script(script):
    # Reuse the application's existing LOCAL lifecycle, never mock RPC success.
    # The parent owns startup/teardown; embedded Node test lifecycles use that
    # actual private server without dropping its database or starting a second.
    return '''export MEMBA_ACCEPTANCE_LOCAL_EMAIL=true
node - <<'MEMBA_NODE_CHECK'
const {spawn} = require('node:child_process');
const {createBrowserAcceptanceLifecycle} = require('/work/acceptance-tests/features/support/lifecycle');
const lifecycle = createBrowserAcceptanceLifecycle();
(async () => {
  let code = 1;
  try {
    await lifecycle.start();
    code = await new Promise((resolve, reject) => {
      const child = spawn('/bin/bash', ['-c', SCRIPT], {
        stdio: 'inherit',
        env: {...process.env, ACCEPTANCE_SKIP_APP_START: 'true', BASE_URL: lifecycle.baseUrl}
      });
      child.on('error', reject);
      child.on('exit', (status, signal) => resolve(signal ? 128 : status));
    });
  } finally { await lifecycle.stop(); }
  process.exitCode = code;
})().catch(error => { console.error(error); process.exitCode = 1; });
MEMBA_NODE_CHECK
'''.replace('SCRIPT', json.dumps(script))


def argv(root, work, home, script, node_checks=False):
    config = json.loads((root / 'runtime.json').read_text())
    args = [config['bwrap'], '--die-with-parent', '--unshare-all', '--new-session',
            '--hostname', 'candidate', '--ro-bind', '/usr', '/usr',
            '--symlink', 'usr/bin', '/bin', '--symlink', 'usr/lib', '/lib',
            '--symlink', 'usr/lib64', '/lib64', '--ro-bind', '/nix/store', '/nix/store',
            '--ro-bind', str(root / 'etc'), '/etc', '--proc', '/proc', '--dev', '/dev',
            '--tmpfs', '/tmp', '--bind', str(home), '/home/runner',
            '--ro-bind', str(work), '/work', '--chdir', '/work', '--clearenv']
    # Source/proof is mounted RO, not merely checked after execution. Only build
    # outputs are writable; dependencies, test drivers and feature files are RO.
    for name in ['web/_build', 'packages/live_query/_build', 'web/priv/static']:
        (work / name).mkdir(parents=True, exist_ok=True)
        args += ['--bind', str(work / name), '/work/' + name]
    # Mix's warm build priv link points back into RO source. Build artifacts
    # (e.g. git_sha) must write the disposable build copy, never source priv.
    build_priv = work / 'web/_build/test/lib/memba/priv'
    if build_priv.is_symlink():
        build_priv.unlink()
        shutil.copytree(work / 'web/priv', build_priv, symlinks=True)
    if node_checks:
        # Only the private EMPTY fixture root is writable. Every installed
        # dependency child remains RO; no host/cache dependency write authority.
        modules = work / 'acceptance-tests/node_modules'
        args += ['--tmpfs', '/work/acceptance-tests/node_modules']
        for child in sorted(modules.iterdir()):
            destination = '/work/acceptance-tests/node_modules/' + child.name
            if child.is_symlink():
                args += ['--symlink', str(child.readlink()), destination]
            else:
                args += ['--ro-bind', str(child), destination]
        script = node_lifecycle_script(script)
    for key, value in config['env'].items():
        args += ['--setenv', key, value]
    setup = '''set -euo pipefail
mkdir -p /tmp/pg
initdb -D /tmp/pg/data --no-locale --encoding=UTF8 -A trust -U runner >/tmp/initdb.log
pg_ctl -D /tmp/pg/data -l /tmp/postgres.log -o "-k /tmp/pg -h 127.0.0.1 -p 5432" -w start
trap 'pg_ctl -D /tmp/pg/data -m immediate -w stop >/dev/null' EXIT
'''
    return args + ['--', '/bin/bash', '-c', setup + script]


def run(root, label, script, seconds=300, candidate=None, capture=False, node_checks=False):
    root = Path(root).resolve()
    config = json.loads((root / 'runtime.json').read_text())
    etc = root / 'etc'
    if config.get('etc_digest') and digest(tracked_hashes(etc, [str(p.relative_to(etc)) for p in etc.rglob('*') if p.is_file()])) != config['etc_digest']:
        raise Blocked('Runtime namespace configuration changed')
    if config.get('cache_digest') and cache_digest(root / 'source') != config['cache_digest']:
        raise Blocked('Runtime dependency caches changed')
    op = root / f'{time.time_ns()}-{label}'
    op.mkdir()
    work = op / 'work'
    if candidate:
        candidate = Path(candidate)
        shutil.copytree(candidate, work, symlinks=True)
        for name in CACHES:
            shutil.copytree(root / 'source' / name, work / name, symlinks=True, dirs_exist_ok=True)
        expected = tracked_hashes(candidate, [str(p.relative_to(candidate)) for p in candidate.rglob('*') if p.is_file()])
    else:
        shutil.copytree(root / 'source', work, symlinks=True)
        expected = config['files']
    shutil.copytree(root / 'home', op / 'home', symlinks=True)
    started = time.time()
    with (op / 'stdout').open('w') as out, (op / 'stderr').open('w') as err:
        try:
            code = subprocess.run(argv(root, work, op / 'home', script, node_checks=node_checks), stdin=subprocess.DEVNULL,
                                  stdout=out, stderr=err, timeout=seconds).returncode
        except subprocess.TimeoutExpired:
            code = 124
    after = tracked_hashes(work, expected)
    receipt = {'source_sha': config['source_sha'], 'source_digest': digest(expected),
               'script': script, 'node_checks': node_checks, 'seconds_cap': seconds, 'exit': code,
               'source_unchanged': after == expected, 'started': started, 'finished': time.time(),
               'adapter_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
               'runtime_digest': digest(config)}
    save(op / 'receipt.json', receipt)
    if not capture:
        print(op)
    if not receipt['source_unchanged']:
        raise Blocked('Runtime changed tracked source; no exact-state evidence')
    # Opt-in for longer admitted jobs: checkpoints own candidate retention.
    # Keep observations/receipts, not hundreds of duplicate disposable caches.
    if config.get('retain_execution_copies', True) is False:
        shutil.rmtree(work)
        shutil.rmtree(op / 'home')
    if capture:
        return code, (op / 'stdout').read_text() + (op / 'stderr').read_text()
    return code


def main():
    parser = argparse.ArgumentParser(__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    p = sub.add_parser('prepare')
    for key in ['root', 'repository', 'sha', 'discovery', 'bwrap']:
        p.add_argument(key)
    p = sub.add_parser('run')
    for key in ['root', 'label', 'script']:
        p.add_argument(key)
    p.add_argument('--seconds', type=int, default=300)
    args = vars(parser.parse_args())
    action = args.pop('action')
    if action == 'prepare':
        prepare(**args)
    else:
        raise SystemExit(run(**args))


if __name__ == '__main__':
    main()
