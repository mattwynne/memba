"""Offline Node runtime containment/routing checks; never product proof."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import test_focused_units as focused

import memba_runtime


class NodeRuntimeTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.work = self.root / 'work'; self.work.mkdir()
        self.home = self.root / 'home'; self.home.mkdir()
        (self.root / 'etc').mkdir()
        self.modules = self.work / 'acceptance-tests/node_modules'
        (self.modules / 'installed').mkdir(parents=True)
        (self.modules / 'installed/package.json').write_text('{"frozen":true}')
        self.bwrap = '/nix/store/dk9qhjgg469lv6mriys7v4c59igarmvx-bubblewrap-0.11.1/bin/bwrap'
        (self.root / 'runtime.json').write_text(json.dumps({
            'bwrap': self.bwrap, 'env': {'PATH': '/usr/bin:/bin'}}))

    def test_node_fixture_root_writable_but_existing_dependencies_readonly(self):
        args = memba_runtime.argv(self.root, self.work, self.home, 'exit 7', node_checks=True)
        destination = '/work/acceptance-tests/node_modules'
        self.assertEqual(args[args.index(destination) - 1], '--tmpfs')
        source = str(self.modules / 'installed')
        self.assertEqual(args[args.index(source) - 1], '--ro-bind')
        self.assertIn('--unshare-all', args)
        self.assertNotIn('--share-net', args)
        self.assertNotIn('/run', args)
        self.assertNotIn(str(Path.home()), args)
        self.assertIn('ACCEPTANCE_SKIP_APP_START', args[-1])
        self.assertIn('BASE_URL', args[-1])
        self.assertIn('lifecycle.stop()', args[-1])
        self.assertIn('exit 7', args[-1])

    def test_non_node_mounts_and_script_unchanged(self):
        args = memba_runtime.argv(self.root, self.work, self.home, 'exit 9')
        self.assertNotIn('/work/acceptance-tests/node_modules', args)
        self.assertTrue(args[-1].endswith('exit 9'))
        self.assertNotIn('createBrowserAcceptanceLifecycle', args[-1])

    def test_declared_node_observation_routes_to_private_node_runtime_only(self):
        fixture = focused.FocusedUnitsTest(); fixture.setUp(); self.addCleanup(fixture.doCleanups)
        spec = fixture.job.c['obligations'][0]
        spec.update(kind='node', script='cd acceptance-tests; node --test test/*.test.js')
        fixture.seal()
        with patch('memba_runtime.run', return_value=(0, '# tests 3\n# pass 3\n')) as run:
            fixture.job.observe('obligation', spec['id'], 'frozen full Node check')
        self.assertTrue(run.call_args.kwargs['node_checks'])
        spec.update(kind='domain', script='mix test')
        fixture.seal()
        with patch('memba_runtime.run', return_value=(0, '3 tests, 0 failures\n')) as run:
            fixture.job.observe('obligation', spec['id'], 'non Node check retains previous runtime')
        self.assertFalse(run.call_args.kwargs['node_checks'])

    def test_real_private_fixture_creation_cannot_mutate_installed_deps(self):
        self.assertTrue(Path(self.bwrap).exists(), 'approved bwrap required; do not skip containment')
        self.assertTrue(Path('/usr/bin/node').exists(), 'real Node required; do not skip containment')
        args = memba_runtime.argv(self.root, self.work, self.home, 'exit 99', node_checks=True)
        # Test the actual OS mounts only; no fake lifecycle is product proof.
        args[-1] = '''node - <<'NODE'
const fs=require('node:fs');const assert=require('node:assert/strict');
const root='/work/acceptance-tests/node_modules';
const temp=fs.mkdtempSync(root+'/reachability-');
fs.writeFileSync(temp+'/fixture.js','fixture');
assert.equal(fs.readFileSync(root+'/installed/package.json','utf8'),'{"frozen":true}');
assert.throws(()=>fs.writeFileSync(root+'/installed/package.json','changed'),{code:'EROFS'});
assert.throws(()=>fs.writeFileSync('/work/tracked.txt','changed'),{code:'EROFS'});
assert.equal(fs.existsSync('/run'),false);
fs.rmSync(temp,{recursive:true});
NODE
'''
        result = subprocess.run(args, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.modules / 'installed/package.json').read_text(), '{"frozen":true}')
        self.assertEqual(list(self.modules.glob('reachability-*')), [])


if __name__ == '__main__':
    unittest.main()
