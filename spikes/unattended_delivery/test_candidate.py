"""Policy tests are doubles, not evidence of model judgment."""
import glob
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
import tempfile
import unittest

from candidate import (validate_contract, validate_files, transition, Blocked, digest,
                       save, create, Runner, sandbox_argv)


class CandidatePolicyTest(unittest.TestCase):
    def test_unit_red_must_precede_implementation(self):
        self.assertEqual(transition('unit_red', 1), 'implement')
        with self.assertRaises(Blocked):
            transition('unit_red', 0)
        with self.assertRaises(Blocked):
            transition('unit_red', 2)

    def test_same_acceptance_repeats_after_inner_loop(self):
        self.assertEqual(transition('acceptance', 1), 'unit_test')
        self.assertEqual(transition('unit_green', 0), 'refactor')
        self.assertEqual(transition('refactor_check', 0), 'acceptance')
        self.assertEqual(transition('acceptance', 0), 'obligations')

    def test_only_approved_regular_files_can_be_changed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'src.py').write_text('old')
            validate_files(root, {'src.py': 'new'}, ['src.py'])
            for name in ['../escape', '/tmp/escape', '.git/config', 'proof.py']:
                with self.assertRaises(Blocked):
                    validate_files(root, {name: 'new'}, ['src.py'])
            (root / 'link.py').symlink_to(root / 'src.py')
            with self.assertRaises(Blocked):
                validate_files(root, {'link.py': 'new'}, ['link.py'])

    def test_contract_requires_one_example_and_technical_proof(self):
        with self.assertRaises(Blocked):
            validate_contract({'examples': []})
        with self.assertRaises(Blocked):
            validate_contract({'examples': [{'id': 'a'}, {'id': 'b'}]})

    def test_atomic_document_and_stable_digest(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'state.json'
            save(path, {'z': 1, 'a': 2})
            self.assertEqual(digest(json.loads(path.read_text())), digest({'a': 2, 'z': 1}))


class CandidateExecutionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'run'
        subprocess.run([sys.executable, str(Path(__file__).with_name('prepare_canary.py')),
                        str(self.root)], check=True, stdout=subprocess.DEVNULL)
        self.c = json.loads((self.root / 'contract.json').read_text())
        self.job = self.root / 'job'
        # The executable identity is irrelevant to these policy doubles.
        create(self.job, self.root / 'source', self.root / 'contract.json',
               digest(self.c), '/usr/bin/true', '/usr/bin/true')
        self.runner = Runner(self.job)

    def test_duplicate_create_does_not_reset_budget(self):
        self.runner.s['calls'] = 4
        self.runner.persist()
        with self.assertRaises(FileExistsError):
            create(self.job, self.root / 'source', self.root / 'contract.json',
                   digest(self.c), '/usr/bin/true', '/usr/bin/true')
        self.assertEqual(Runner(self.job).s['calls'], 4)

    def test_contract_mutation_is_not_readmitted(self):
        self.c['outcome'] = 'weakened'
        save(self.job / 'contract.json', self.c)
        with self.assertRaisesRegex(Blocked, 'fingerprint'):
            Runner(self.job)

    def test_foreign_candidate_mutation_blocks(self):
        (self.job / 'candidate' / 'stock.py').write_text('tampered')
        with self.assertRaisesRegex(Blocked, 'outside write-ahead'):
            self.runner.run()

    def test_write_ahead_proposal_replays_after_partial_write(self):
        self.runner.s['pending'] = {'files': {'stock.py': 'complete\n'}, 'next': 'unit_green'}
        self.runner.persist()
        (self.job / 'candidate' / 'stock.py').write_text('part')
        resumed = Runner(self.job)
        resumed.apply_pending()
        self.assertEqual((self.job / 'candidate' / 'stock.py').read_text(), 'complete\n')
        self.assertEqual(resumed.s['phase'], 'unit_green')
        self.assertIsNone(resumed.s['pending'])

    def test_call_budget_cannot_reset_on_resume(self):
        self.runner.s['calls'] = self.c['max_calls']
        self.runner.persist()
        with self.assertRaisesRegex(Blocked, 'Cumulative'):
            Runner(self.job).model('builder', 'unused')

    def test_absolute_deadline_cannot_reset_on_resume(self):
        self.runner.s['deadline'] = time.time() - 1
        self.runner.persist()
        with self.assertRaisesRegex(Blocked, 'deadline'):
            Runner(self.job).run()

    def test_zero_selection_and_setup_error_are_not_green_or_red(self):
        self.runner.execute = lambda *_: (0, 'Ran 0 tests', '')
        with self.assertRaisesRegex(Blocked, 'count'):
            self.runner.test(['unused'], 'acceptance', 'Ran 1 test')
        self.runner.execute = lambda *_: (1, 'Ran 1 test\nERROR: import failed', '')
        with self.assertRaisesRegex(Blocked, 'assertion'):
            self.runner.test(['unused'], 'acceptance', 'Ran 1 test')

    def test_stale_review_cannot_accept(self):
        self.runner.s['phase'] = 'review'
        self.runner.model = lambda *_: {'verdict': 'accept', 'candidate': 'wrong',
                                       'contract_digest': self.runner.s['contract'], 'findings': []}
        with self.assertRaisesRegex(Blocked, 'Stale'):
            self.runner.run()
        self.assertEqual(self.runner.s['status'], 'running')

    def test_out_of_capability_proposal_is_not_applied_or_accepted(self):
        self.runner.s['phase'] = 'refactor'
        before = (self.job / 'candidate' / 'test_unit.py').read_text()
        self.runner.model = lambda *_: {'diagnosis': 'wrong phase',
                                        'files': {'test_unit.py': 'weakened'}}
        self.runner.propose('refactor')
        self.assertEqual((self.job / 'candidate' / 'test_unit.py').read_text(), before)
        self.assertEqual(self.runner.s['phase'], 'refactor')
        self.assertIn('permitted paths', self.runner.s['protocol_feedback'])

    def test_green_characterization_does_not_manufacture_a_red(self):
        self.runner.s.update(phase='unit_red', findings=['Missing regression proof'])
        def check(argv, label, marker=None):
            if label == 'refactor_check':
                raise Blocked('test stop')
            self.runner.s['last_observation'] = {'exit': 0}
            return 0
        self.runner.test = check
        with self.assertRaisesRegex(Blocked, 'test stop'):
            self.runner.run()
        self.assertEqual(self.runner.s['phase'], 'refactor_check')

    def test_technical_failure_routes_to_bounded_repair(self):
        self.runner.s['phase'] = 'obligations'
        def check(*_):
            self.runner.s['last_observation'] = {'exit': 1}
            return 1
        def stop(*_):
            raise Blocked('test stop')
        self.runner.test = check
        self.runner.model = stop
        with self.assertRaisesRegex(Blocked, 'test stop'):
            self.runner.run()
        self.assertEqual(self.runner.s['phase'], 'unit_test')
        self.assertIn('Failed technical obligation', self.runner.s['findings'][0])

    def test_model_cannot_accept_a_concurrently_changed_candidate(self):
        def mutate(*_, **kwargs):
            (self.job / 'candidate' / 'stock.py').write_text('foreign edit')
            return 0, '{}', ''
        self.runner.execute = mutate
        with self.assertRaisesRegex(Blocked, 'changed during'):
            self.runner.model('reviewer', 'review')

    def test_real_sandbox_denies_host_files_writes_and_network(self):
        paths = glob.glob(str(Path.home() / '.local/lib/node_modules/@openai/codex/**/bwrap'), recursive=True)
        binary = shutil.which('bwrap') or (paths[0] if paths else None)
        if not binary:
            self.skipTest('Bubblewrap unavailable; live isolation is unproved here')
        probe = '''import os, socket
assert not os.path.exists('/home')
assert not os.path.exists('/run')
assert not os.path.exists('/work/.git')
try:
    open('/work/stock.py', 'w')
except OSError:
    pass
else:
    raise AssertionError('candidate writable')
s = socket.socket()
s.settimeout(0.2)
assert s.connect_ex(('1.1.1.1', 443)) != 0
print('isolated')
'''
        result = subprocess.run(sandbox_argv(binary, self.job / 'candidate',
                                ['/usr/bin/python3', '-c', probe]), capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'isolated')


if __name__ == '__main__':
    unittest.main()
