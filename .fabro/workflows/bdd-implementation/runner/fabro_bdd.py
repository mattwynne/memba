#!/usr/bin/env python3
"""Trusted command stages for one non-production Fabro implementation run.

The worker owns implementation, checks and independent review. These stages only
admit once, supervise that exact job, and export verified evidence. No publisher.
"""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tarfile
import time
import uuid

from candidate import Blocked, command, digest, save
from session_candidate import Job, create, manifest
import memba_runtime
from sol_provider import runtime_digest

HERE = Path(__file__).resolve().parent


def validate_run_key(key):
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9-]{0,63}', key):
        raise Blocked('Invalid immutable run key')
    return key


def activate_examples(root, examples, tag):
    """Remove only selected scenario-level todo tags, preserving every line.

    Real Gherkin discovery/selection is independently checked before admission.
    Inherited iteration tags come from real Gherkin discovery. Never remove
    inherited todo tags (that would activate unselected siblings).
    """
    changes = {}
    for spec in examples:
        uri = Path(spec['uri'])
        if uri.is_absolute() or '..' in uri.parts or uri.parts[0] != 'features':
            raise Blocked('Unsafe feature URI')
        p = Path(root) / 'acceptance-tests' / uri
        original = p.read_text()
        lines = changes.get(p, original).splitlines(keepends=True)
        matches = [i for i, line in enumerate(lines)
                   if re.fullmatch(r'\s*Scenario:\s*' + re.escape(spec['name']) + r'\s*', line.rstrip('\n'))]
        if len(matches) != 1:
            raise Blocked('Activation needs one unambiguous scenario: ' + spec['name'])
        i = matches[0] - 1
        tags = []
        while i >= 0 and lines[i].lstrip().startswith('@'):
            tags.append(i); i -= 1
        if not any('@' + tag in lines[i].split() for i in tags) and '@' + tag not in spec.get('tags', []):
            raise Blocked('Selected scenario lacks its exact iteration tag')
        if '@todo' in spec.get('tags', []) and not any('@todo' in lines[i].split() for i in tags):
            raise Blocked('Refuse inherited todo activation of unselected siblings')
        for i in tags:
            lines[i] = re.sub(r'(?<!\S)@todo(?!\S)', '', lines[i])
        changes[p] = ''.join(lines)
    proof = []
    for p, text in changes.items():
        proof.append({'path': str(p.relative_to(root)),
                      'original_sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                      'activated_sha256': hashlib.sha256(text.encode()).hexdigest()})
    for p, text in changes.items():
        p.write_text(text)
    return proof


def focused_units(profile):
    selected = []
    for name in sorted(set(profile['unit_files']) - set(profile.get('acceptance_support_files', []))):
        if name.startswith('web/test/') and name.endswith('_test.exs'):
            kind, script = 'domain', 'cd web; mix test ' + shlex.quote(name[4:]) + ' --exclude domain_cucumber'
        elif name.startswith('acceptance-tests/test/') and name.endswith('.test.js'):
            kind, script = 'node', 'cd acceptance-tests; node --test --test-reporter=tap ' + shlex.quote(name[17:])
        else:
            raise Blocked('Unit file has no supported deterministic selector: ' + name)
        selected.append({'id': f'unit-{len(selected) + 1:03d}', 'kind': kind, 'paths': [name], 'script': script})
    return selected


def pin_sol():
    node = Path(shutil.which('node')).resolve()
    sdk = Path(os.environ.get('MEMBA_PI_SDK', str(Path.home() / '.local/lib/node_modules/@earendil-works/pi-coding-agent'))).resolve()
    code = ('import {ModelRuntime} from ' + json.dumps((sdk / 'dist/index.js').as_uri()) + ';'
            'const r=await ModelRuntime.create({allowModelNetwork:false});'
            'console.log(JSON.stringify(r.getModel("openai-codex","gpt-6.1-sol")));')
    model = json.loads(subprocess.check_output([str(node), '--input-type=module', '-e', code], text=True))
    if (model['id'], model['provider'], model['api'], model['baseUrl']) != (
            'gpt-6.1-sol', 'openai-codex', 'openai-codex-responses', 'https://chatgpt.com/backend-api'):
        raise Blocked('Required authenticated Sol catalog unavailable; no fallback')
    return {'sdk_root': str(sdk), 'sdk_digest': runtime_digest(sdk), 'node': str(node),
            'node_sha256': hashlib.sha256(node.read_bytes()).hexdigest(), 'model_digest': digest(model),
            'provider': model['provider'], 'api': model['api'], 'base_url': model['baseUrl'],
            'max_turns': 160, 'thinking': 'high', 'token_policy': 'accounting-only'}


def begin(repo, run_id):
    if not run_id or not re.fullmatch(r'[A-Za-z0-9-]{16,40}', run_id):
        raise Blocked('Real Fabro run identity required')
    path = Path(repo) / '.fabro/tmp/bdd/active-owner.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.with_suffix('.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if path.exists():
            previous = json.loads(path.read_text())
            if previous['run_id'] == run_id:
                return previous
            if previous['status'] == 'active':
                raise Blocked('Another Fabro implementation owns this checkout')
        record = {'run_id': run_id, 'status': 'active', 'started': time.time()}
        save(path, record)
        return record


def cleanup(repo, run_id):
    path = Path(repo) / '.fabro/tmp/bdd/active-owner.json'
    if not path.exists():
        return {'decision': 'proceed'}
    record = json.loads(path.read_text())
    if record['run_id'] != run_id:
        raise Blocked('Refuse another Fabro run cleanup')
    if record.get('run_key') and pointer(repo, record['run_key']).exists():
        admission, job = load_job(repo, record['run_key'])
        info = service(job)
        if info.get('ActiveState') in ('active', 'activating', 'deactivating', 'reloading'):
            subprocess.run(['sudo', '-n', 'systemctl', 'stop', unit_name(job)], check=True, timeout=20)
        job.reload()
        save(Path(admission['root']) / 'workflow-cleanup.json',
             {'run_id': run_id, 'finished': time.time(), 'candidate': job.s['candidate'],
              'visits': job.s['visits'], 'operations': job.s['operations'], 'status': job.s['status']})
    record.update(status='finished', finished=time.time())
    save(path, record)
    return {'decision': 'proceed'}


def pointer(repo, key):
    return Path(repo) / '.fabro/tmp/bdd' / (validate_run_key(key) + '.json')


def load_job(repo, key):
    record = json.loads(pointer(repo, key).read_text())
    job = Job(Path(record['root']) / 'job')
    if record['contract'] != job.s['contract'] or record['run_key'] != key:
        raise Blocked('Fabro job identity changed')
    return record, job


def unit_name(job):
    return 'memba-session-' + hashlib.sha256(str(job.path).encode()).hexdigest()[:16] + '.service'


def service(job):
    text = subprocess.check_output(['systemctl', 'show', unit_name(job), '-p', 'ActiveState',
                                    '-p', 'LoadState', '-p', 'ExecStart', '-p', 'InvocationID'], text=True)
    info = dict(line.split('=', 1) for line in text.splitlines() if '=' in line)
    if info.get('LoadState') == 'loaded' and str(job.path / 'session_candidate.py') not in info.get('ExecStart', ''):
        raise Blocked('Refuse foreign service ownership')
    return info


def prepare(repo, plan_path, source_sha, key):
    repo = Path(repo).resolve(); validate_run_key(key)
    if not re.fullmatch(r'docs/iterations/[0-9]{3}[A-Z]?-[a-z0-9-]+/plan\.md', plan_path):
        raise Blocked('Exact committed iteration plan path required')
    if not re.fullmatch(r'[0-9a-f]{40}', source_sha) or command(['git', 'rev-parse', 'HEAD'], repo) != source_sha:
        raise Blocked('Fabro source differs from admitted source SHA')
    owner_path = repo / '.fabro/tmp/bdd/active-owner.json'
    owner = json.loads(owner_path.read_text())
    if owner['status'] != 'active':
        raise Blocked('Live Fabro ownership required')
    plan = repo / plan_path
    if not re.search(r'^Status: (ready|validated)\s*$', plan.read_text(), re.M):
        raise Blocked('Ready or validated plan required')
    profile_path = plan.with_name('execution.json')
    profile = json.loads(profile_path.read_text())
    identity = {'run_key': key, 'source_sha': source_sha, 'plan_path': plan_path,
                'profile_digest': digest(profile), 'fabro_run_id': owner['run_id']}
    if owner.get('run_key', key) != key:
        raise Blocked('Fabro run cannot switch jobs or allowances')
    owner['run_key'] = key
    save(owner_path, owner)
    state = Path(os.environ.get('MEMBA_FABRO_STATE', str(Path.home() / '.local/state/memba/fabro-implementation')))
    root = state / key
    existing_pointer = pointer(repo, key)
    if existing_pointer.exists():
        previous = json.loads(existing_pointer.read_text())
        if any(previous.get(k) != v for k, v in identity.items()) or previous['root'] != str(root):
            raise Blocked('Existing run key cannot admit another job or allowance')
        load_job(repo, key)
        return previous
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (root / 'prepare.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        admitted = root / 'admission.json'
        if admitted.exists():
            record = json.loads(admitted.read_text())
            if any(record.get(k) != v for k, v in identity.items()):
                raise Blocked('Run key already belongs to another immutable admission')
            if record.get('contract'):
                job = Job(root / 'job')
                if job.s['contract'] != record['contract']:
                    raise Blocked('Prepared job changed')
                save(pointer(repo, key), record)
                load_job(repo, key)
                return record
        else:
            limits = profile.get('remaining_allowance', {})
            deadline = min(time.time() + 21600, limits.get('absolute_deadline_epoch', float('inf')))
            record = {**identity, 'root': str(root), 'deadline': deadline,
                      'authority': 'non-production-candidate-only', 'stage': 'preparing'}
            save(admitted, record)
        if time.time() >= record['deadline']:
            raise Blocked('Original preparation deadline exhausted')
        # Warm dependency/tool setup is trusted, before any worker is admitted.
        if not all((repo / n).exists() for n in memba_runtime.CACHES):
            with (root / 'bootstrap.log').open('a') as log:
                subprocess.run(['bin/dev', 'check'], cwd=repo, stdin=subprocess.DEVNULL,
                               stdout=log, stderr=subprocess.STDOUT, check=True,
                               timeout=min(1200, record['deadline'] - time.time()))
        discovery = root / 'discovery.json'
        if not discovery.exists():
            code = ('import os,json; keys=["PATH","FONTCONFIG_FILE","FONTCONFIG_PATH",'
                    '"PLAYWRIGHT_BROWSERS_PATH","LD_LIBRARY_PATH","PKG_CONFIG_PATH"];'
                    'd={k:os.environ.get(k,"") for k in keys};'
                    'candidates=[os.environ.get("MIX_HOME",""),os.path.join(os.environ["HOME"],".mix"),"/tmp/home/.mix"];'
                    'd["_MIX_CACHE_SOURCE"]=next(p for p in candidates if p and os.path.isdir(p));'
                    'import sys; from pathlib import Path;'
                    'p=Path(sys.argv[1]); t=p.with_suffix(".pending");'
                    't.write_text(json.dumps(d)); os.replace(t,p)')
            # Devenv's enter-shell banner is stdout, not JSON. The trusted
            # exporter writes an atomic file; preserve both streams as logs.
            with (root / 'discovery.stderr').open('a') as err, (root / 'discovery.stdout').open('a') as out:
                subprocess.run(['devenv', 'shell', '--', '/usr/bin/python3', '-c', code, str(discovery)],
                    cwd=repo, stdout=out, stderr=err, check=True, timeout=300)
            json.loads(discovery.read_text())
        env = json.loads(discovery.read_text())
        bwrap = shutil.which('bwrap', path=env['PATH'])
        if not bwrap or not bwrap.startswith('/nix/store/'):
            raise Blocked('Approved Nix bwrap required')
        runtime = root / 'runtime'
        if runtime.exists() and not (runtime / 'runtime.json').exists():
            runtime.rename(root / ('runtime-incomplete-' + uuid.uuid4().hex))
        if not runtime.exists():
            memba_runtime.prepare(runtime, repo, source_sha, discovery, bwrap)
            config = json.loads((runtime / 'runtime.json').read_text())
            config['retain_execution_copies'] = False
            save(runtime / 'runtime.json', config)
        activation = root / 'activation'
        if not activation.exists():
            activation.mkdir()
            with subprocess.Popen(['git', 'archive', source_sha], cwd=repo, stdout=subprocess.PIPE) as proc:
                with tarfile.open(fileobj=proc.stdout, mode='r|') as archive:
                    archive.extractall(activation, filter='data')
                if proc.wait(): raise Blocked('Activation archive failed')
            (activation / 'acceptance-tests/node_modules').symlink_to(runtime / 'source/acceptance-tests/node_modules')
        node = shutil.which('node')
        selected = json.loads(subprocess.check_output([node, str(HERE / 'select_examples.cjs'),
                         str(activation), '--discover', profile['iteration_tag']], text=True))
        activation_proof = activate_examples(activation, selected, profile['iteration_tag'])
        examples = json.loads(subprocess.check_output([node, str(HERE / 'select_examples.cjs'),
                              str(activation), json.dumps(selected)], text=True))
        for spec in examples:
            spec['script'] = ('cd web; mix test test/features/domain_cucumber_acceptance_test.exs --only ' +
                              shlex.quote('scenario_name:' + spec['name']) if spec['kind'] == 'domain' else
                              'cd acceptance-tests; node_modules/.bin/cucumber-js ' + shlex.quote(spec['uri'] + ':' + str(spec['line'])))
        contract_path = root / 'contract.json'
        if contract_path.exists():
            c = json.loads(contract_path.read_text())
        else:
            c = {**profile, 'source_sha': source_sha, 'examples': examples, 'focused_units': focused_units(profile),
                 'model_backend': 'pi-sol', 'model': 'gpt-6.1-sol', 'visit_usd': None, 'sol_provider': pin_sol(),
                 'runtime_root': str(runtime), 'runtime_digest': digest(json.loads((runtime / 'runtime.json').read_text())),
                 'automatic_continuation': True, 'max_provider_recoveries': 6, 'preserve_source_history': True,
                 'formatter': True, 'final_product_gate': True, 'product_gate_seconds': 1200,
                 'max_visits': 12, 'max_operations': 800, 'max_restarts': 4, 'visit_seconds': 4500,
                 'check_seconds': 600, 'deadline_seconds': 21600, 'absolute_deadline_epoch': record['deadline'],
                 'memory_mb': 6144, 'tasks_max': 512, 'file_size_mb': 128,
                 'source_integrity': {'activation': activation_proof}}
            # An explicitly carried task allowance can only reduce admission.
            # Earlier raw attempts and accounting remain immutable references.
            for name in ['max_visits', 'max_operations', 'max_restarts', 'max_provider_recoveries']:
                if name in profile.get('remaining_allowance', {}):
                    value = profile['remaining_allowance'][name]
                    if type(value) is not int or value < 0:
                        raise Blocked('Invalid remaining task allowance')
                    c[name] = min(c[name], value)
            c['context_files'] = sorted(set(c['context_files'] + [str(profile_path.relative_to(repo))]))
            c['source_integrity']['immutable_context_sha256'] = memba_runtime.tracked_hashes(activation, c['context_files'])
            save(contract_path, c)
        job_path = root / 'job'
        if job_path.exists() and not (job_path / 'state.json').exists():
            job_path.rename(root / ('job-incomplete-' + uuid.uuid4().hex))
        if not job_path.exists():
            create(job_path, repo, contract_path, digest(c))
        job = Job(job_path)
        if job.s['visits'] or job.s['operations']:
            raise Blocked('Preparation cannot rewrite an already spent job')
        for proof in c['source_integrity']['activation']:
            target = job.source / proof['path']; wanted = (activation / proof['path']).read_bytes()
            if hashlib.sha256(target.read_bytes()).hexdigest() not in (proof['original_sha256'], proof['activated_sha256']):
                raise Blocked('Foreign activation change')
            target.write_bytes(wanted)
        job.checkpoint()
        record.update(stage='prepared', contract=digest(c), initial_candidate=job.s['candidate'])
        save(admitted, record); save(pointer(repo, key), record)
        return record


def verified_result(path):
    if not all((Path(path) / n).is_file() for n in ['state.json', 'contract.json']):
        raise Blocked('No independently verifiable result')
    job = Job(path); s, c = job.s, job.c
    pair = {'candidate': s['candidate'], 'contract': s['contract']}
    review = s.get('review', {})
    if s['status'] != 'candidate-accepted-non-production' or any(review.get(k) != v for k, v in pair.items()) or review.get('verdict') != 'accept' or review.get('findings') != []:
        raise Blocked('No independent exact-state acceptance')
    if digest(manifest(job.source)) != s['tree']:
        raise Blocked('Accepted source changed')
    gate = s.get('product_gate', {})
    if any(gate.get(k) != v for k, v in pair.items()) or gate.get('exit') != 0 or gate.get('script') != 'bin/dev check' or not gate.get('source_unchanged'):
        raise Blocked('No exact committed full product gate')
    receipts = [json.loads((job.path / p).read_text()) for p in s['receipts']]
    for spec in c['examples'] + c['obligations']:
        r = s['observed'].get(spec['id'], {})
        if any(r.get(k) != v for k, v in pair.items()) or r.get('exit') != 0 or r.get('count', 0) < 1 or r not in receipts:
            raise Blocked('Missing final proof: ' + spec['id'])
    for relative in s['receipts'] + [gate['receipt']]:
        p = job.path / relative; r = json.loads(p.read_text())
        if hashlib.sha256(p.with_suffix('.stdout').read_bytes()).hexdigest() != r['output_sha256']:
            raise Blocked('Raw evidence changed: ' + relative)
    subprocess.run(['git', 'merge-base', '--is-ancestor', c['source_sha'], s['candidate']],
                   cwd=job.path / 'checkpoints', check=True)
    return {**pair, 'source_sha': c['source_sha'], 'tree': s['tree'], 'status': s['status'],
            'published': False, 'deployed': False, 'visits': s['visits'], 'operations': s['operations'],
            'restarts': s['starts'] - 1, 'deadline': s['deadline'], 'proof_counts': {p['id']: s['observed'][p['id']]['count'] for p in c['examples'] + c['obligations']},
            'review': review, 'product_gate': gate, 'reported_cost_usd': s['reported_cost_usd'],
            'provider_usage': s.get('provider_usage', []), 'job': str(job.path),
            'carried_task_accounting': c.get('remaining_allowance', {}).get('carry_in')}


def drive(repo, key, seconds=240):
    record, job = load_job(repo, key)
    info = service(job)
    started = Path(record['root']) / 'service-started.json'
    if job.s['status'] == 'running' and not started.exists():
        if info.get('LoadState') != 'loaded':
            with (Path(record['root']) / 'dispatch.log').open('a') as log:
                subprocess.run(['/bin/bash', str(HERE / 'dispatch_session.sh'), str(job.path)],
                               stdout=log, stderr=log, check=True)
        save(started, {'unit': unit_name(job), 'candidate': job.s['candidate'], 'deadline': job.s['deadline']})
    until = time.time() + seconds
    while time.time() < until:
        job.reload(); info = service(job)
        active = info.get('ActiveState') in ('active', 'activating', 'deactivating', 'reloading')
        if job.s['status'] == 'candidate-accepted-non-production' and not active:
            verified_result(job.path)
            return {'preferred_next_label': 'accepted', 'job': str(job.path)}
        if job.s['status'] != 'running' and job.s['status'] != 'candidate-accepted-non-production' or not active:
            raise Blocked('Worker stopped: ' + str(job.s.get('blocker', info)))
        time.sleep(2)
    return {'preferred_next_label': 'waiting', 'phase': job.s['phase'], 'candidate': job.s['candidate'],
            'visits': job.s['visits'], 'operations': job.s['operations'], 'job': str(job.path)}


def report(repo, key):
    record, job = load_job(repo, key); result = verified_result(job.path)
    target = 'refs/heads/fabro-candidates/' + validate_run_key(key)
    command(['git', 'fetch', '--no-tags', str(job.path / 'checkpoints'), result['candidate']], repo)
    existing = subprocess.run(['git', 'rev-parse', '--verify', target], cwd=repo, text=True, capture_output=True)
    if existing.returncode == 0 and existing.stdout.strip() != result['candidate']:
        raise Blocked('Candidate ref belongs to another result')
    command(['git', 'update-ref', target, result['candidate'], existing.stdout.strip() if existing.returncode == 0 else '0' * 40], repo)
    result['retained_ref'] = target
    output = Path(repo) / '.fabro/tmp/bdd' / key
    output.mkdir(parents=True, exist_ok=True); save(output / 'report.json', result)
    save(Path(record['root']) / 'result.json', result)
    return result


def main():
    parser = argparse.ArgumentParser(__doc__); sub = parser.add_subparsers(dest='action', required=True)
    p = sub.add_parser('prepare')
    for n in ['plan_path', 'source_sha', 'run_key']: p.add_argument(n)
    for name in ['drive', 'report']:
        p = sub.add_parser(name); p.add_argument('run_key')
    for name in ['begin', 'cleanup']:
        sub.add_parser(name)
    args = vars(parser.parse_args()); action = args.pop('action'); key = args.pop('run_key', None)
    repo = Path.cwd()
    try:
        if action in ('begin', 'cleanup'):
            result = begin(repo, os.environ.get('FABRO_RUN_ID')) if action == 'begin' else cleanup(repo, os.environ.get('FABRO_RUN_ID'))
            result['decision'] = 'proceed'
        else:
            result = prepare(repo, key=key, **args) if action == 'prepare' else drive(repo, key) if action == 'drive' else report(repo, key)
        print(json.dumps({'status': 'success', **result}))
    except (Blocked, OSError, ValueError, subprocess.SubprocessError) as exc:
        print(json.dumps({'status': 'fail', 'error': str(exc)})); raise SystemExit(1)


if __name__ == '__main__':
    main()
