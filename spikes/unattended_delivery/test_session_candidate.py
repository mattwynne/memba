import json
import os
import time
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from candidate import Blocked, command, digest
from session_candidate import Job, create, selected_count


class SessionCandidateTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'trial'
        subprocess.run([sys.executable, str(Path(__file__).with_name('prepare_session_canary.py')),
                        str(self.root), '/usr/bin/true'], check=True, stdout=subprocess.DEVNULL)
        c = json.loads((self.root / 'contract.json').read_text())
        create(self.root / 'job', self.root / 'source', self.root / 'contract.json', digest(c))
        self.job = Job(self.root / 'job')
        self.job.s['active_attempt'] = 'current'
        self.job.persist()

    def test_audit_first_edits_require_independent_repair_and_keep_tdd_guard(self):
        c = dict(self.job.c, review_before_edits=True)
        contract = self.root / 'audit-contract.json'
        contract.write_text(json.dumps(c))
        create(self.root / 'audit-job', self.root / 'source', contract, digest(c))
        job = Job(self.root / 'audit-job')
        identity = job.s['builder_session']
        for refactor in (False, True):
            with self.assertRaisesRegex(Blocked, 'independent review'):
                job.edit('test_unit.py', 'import unittest', 'import unittest\n# proof', refactor)
        self.assertEqual(job.s['operations'], 0)
        job.s['phase'] = 'reviewer'
        job.persist()
        roles = []
        def model(role, feedback):
            roles.append(role)
            if role == 'reviewer':
                return json.dumps({'verdict': 'repair', 'findings': ['Missing ownership regression'],
                                   'candidate': job.s['candidate'], 'contract': job.s['contract']})
            restored = Job(job.path)
            self.assertTrue(restored.s['repair_authorized'])
            self.assertEqual(restored.s['builder_session'], identity)
            restored.edit('test_unit.py', 'import unittest', 'import unittest\n# proof')
            with self.assertRaisesRegex(Blocked, 'ACTUAL'):
                restored.edit('stock.py', 'return False', 'return True')
            raise Blocked('routing test finished')
        job.model = model
        with self.assertRaisesRegex(Blocked, 'routing test finished'):
            job.run()
        self.assertEqual(roles, ['reviewer', 'builder'])

    def test_audit_first_capability_must_be_boolean(self):
        c = dict(self.job.c, review_before_edits='false')
        contract = self.root / 'invalid-contract.json'
        contract.write_text(json.dumps(c))
        with self.assertRaisesRegex(Blocked, 'boolean'):
            create(self.root / 'invalid-job', self.root / 'source', contract, digest(c))

    def test_zero_execution_is_terminal_not_an_agent_retry_loop(self):
        # The /usr/bin/true sandbox double produces no framework execution.
        with patch('session_candidate.subprocess.run', wraps=subprocess.run) as invoked:
            with self.assertRaisesRegex(Blocked, 'Infrastructure/selection'):
                self.job.observe('example', self.job.c['examples'][0]['id'], 'no selected tests')
            self.assertEqual(invoked.call_args.kwargs['stdin'], subprocess.DEVNULL)
        restored = Job(self.job.path)
        self.assertEqual(restored.s['status'], 'blocked')
        self.assertEqual(restored.s['operations'], 1)
        with self.assertRaisesRegex(Blocked, 'Stale'):
            restored.tool('inspect', {}, 'current')

    def test_admission_rejects_host_import_shadowing_and_git_metadata(self):
        source = self.root / 'source'
        (source / '__init__.py').write_text('raise RuntimeError("untrusted package initializer")\n')
        command(['git', 'add', '__init__.py'], source)
        command(['git', '-c', 'user.name=Test', '-c', 'user.email=test@invalid', 'commit', '-qm', 'Package fixture'], source)
        for index, name in enumerate(['__init__.py', '.git/config']):
            with self.subTest(name=name):
                c = dict(self.job.c)
                c['source_sha'] = command(['git', 'rev-parse', 'HEAD'], source)
                c['editable'] = c['editable'] + [name]
                contract = self.root / 'unsafe-contract.json'
                contract.write_text(json.dumps(c))
                with self.assertRaisesRegex(Blocked, 'Reserved control-plane'):
                    create(self.root / f'unsafe-job-{index}', source, contract, digest(c))
        # Full-source admission must check the archive too, even if the root
        # initializer was not listed among editable/context files.
        c = dict(self.job.c)
        c['source_sha'] = command(['git', 'rev-parse', 'HEAD'], source)
        runtime = self.root / 'runtime'
        runtime.mkdir()
        (runtime / 'runtime.json').write_text(json.dumps({'source_sha': c['source_sha']}))
        c['runtime_root'] = str(runtime)
        contract.write_text(json.dumps(c))
        with self.assertRaisesRegex(Blocked, 'Reserved control-plane'):
            create(self.root / 'unsafe-archive', source, contract, digest(c))

    def test_repeated_checkpoint_preserves_existing_source_symlinks(self):
        link = self.job.source / 'alias.py'
        link.symlink_to('stock.py')
        self.job.checkpoint()
        before = self.job.s['candidate']
        self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# next checkpoint')
        copied = self.job.path / 'checkpoints/alias.py'
        self.assertTrue(copied.is_symlink())
        self.assertEqual(os.readlink(copied), 'stock.py')
        self.assertNotEqual(self.job.s['candidate'], before)
        self.assertIsNone(self.job.s['pending'])
        self.assertEqual(command(['git', 'show', self.job.s['candidate'] + ':alias.py'],
                                 self.job.path / 'checkpoints'), 'stock.py')

    def test_checkpoint_preserves_new_files_even_when_gitignored(self):
        (self.job.source / '.gitignore').write_text('new.py\n')
        (self.job.source / 'new.py').write_text('preserved\n')
        self.job.checkpoint()
        content = subprocess.check_output(['git', 'show', self.job.s['candidate'] + ':new.py'],
                                          cwd=self.job.path / 'checkpoints', text=True)
        self.assertEqual(content, 'preserved\n')

    def test_exunit_runtime_feedback_and_actual_setup_failure_are_distinct(self):
        runtime = self.root / 'runtime-probe'
        runtime.mkdir()
        (runtime / 'runtime.json').write_text('{}')
        self.job.c.update(runtime_root=str(runtime), runtime_digest=digest({}),
                          unit_kind='domain', unit_script='approved mix test')
        assertion = '  1) test behavior (Probe)\n     test_unit.py:10: (test)\n     Assertion with == failed\n1 test, 1 failure\n'
        runtime_error = '  1) test behavior (Probe)\n     ** (UndefinedFunctionError) missing\n1 test, 1 failure\n'
        mixed = assertion.replace('1 test, 1 failure', '') + runtime_error.replace('1)', '2)').replace('1 test, 1 failure', '2 tests, 2 failures')
        for code, output, expected, development in [(2, assertion, True, True), (2, runtime_error, False, True),
                                       (1, runtime_error, False, True), (2, mixed, False, True),
                                       (2, assertion + '__ex_unit_setup_0/1', False, False)]:
            with self.subTest(code=code, output=output):
                with patch('memba_runtime.run', return_value=(code, output)):
                    receipt = self.job.observe('unit', None, 'classification probe')['receipt']
                self.assertEqual(receipt['exit'], code)
                self.assertEqual(receipt['behavioral_red'], expected)
                self.assertEqual(receipt['unit_development'] is not None, development)
                if development:
                    self.job.edit('stock.py', 'def reserve(self, item, quantity):',
                                  'def reserve(self, item, quantity):')
                else:
                    with self.assertRaisesRegex(Blocked, 'ACTUAL'):
                        self.job.edit('stock.py', 'def reserve(self, item, quantity):',
                                      'def reserve(self, item, quantity):')

    def test_python_error_is_not_behavioral_red(self):
        result = subprocess.CompletedProcess([], 1)
        def execute(*args, **kwargs):
            kwargs['stdout'].write('ERROR: test_setup\nRan 1 test in 0.01s\nFAILED (errors=1)\n')
            return result
        with patch('session_candidate.subprocess.run', side_effect=execute):
            receipt = self.job.observe('unit', None, 'setup must not authorize implementation')['receipt']
        self.assertFalse(receipt['behavioral_red'])

    def test_dispatch_accepts_authorized_six_gib_limit(self):
        stub = self.root / 'bin'
        stub.mkdir()
        sudo = stub / 'sudo'
        sudo.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        sudo.chmod(0o755)
        self.job.c['memory_mb'] = 6144
        (self.job.path / 'contract.json').write_text(json.dumps(self.job.c))
        self.job.s['deadline'] = time.time() + 60
        self.job.persist()
        result = subprocess.run(['bash', str(Path(__file__).with_name('dispatch_session.sh')),
                                 str(self.job.path)], capture_output=True, text=True,
                                env={**os.environ, 'PATH': str(stub) + ':' + os.environ['PATH']})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('MemoryMax=6144M', result.stdout)
        self.job.c['memory_mb'] = 6145
        (self.job.path / 'contract.json').write_text(json.dumps(self.job.c))
        result = subprocess.run(['bash', str(Path(__file__).with_name('dispatch_session.sh')),
                                 str(self.job.path)], capture_output=True, text=True,
                                env={**os.environ, 'PATH': str(stub) + ':' + os.environ['PATH']})
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('systemd-run', result.stdout)

    def test_model_visits_remain_spent_after_reload(self):
        self.job.s['visits'] = self.job.c['max_visits']
        self.job.persist()
        with self.assertRaisesRegex(Blocked, 'visit budget'):
            Job(self.job.path).model('builder', 'do not run')

    def test_selection_counts_reject_zero_and_excluded_tests(self):
        self.assertEqual(selected_count('128 tests, 0 failures, 127 excluded', 'domain'), 1)
        self.assertEqual(selected_count('128 tests, 0 failures, 128 excluded', 'domain'), 0)
        self.assertEqual(selected_count('1 scenario (1 passed)', 'browser'), 1)
        self.assertEqual(selected_count('Ran 0 tests in 0.01s', 'unittest'), 0)
        self.assertEqual(selected_count('# tests 4\n# skipped 1\n# todo 1\n', 'node'), 2)
        self.assertEqual(selected_count('# tests 1\n# skipped 1\n# todo 0\n', 'node'), 0)
        self.assertEqual(selected_count('# tests 1\n# tests 2\n', 'node'), 0)

    def test_server_enforces_capabilities_not_just_advisory_mcp_schema(self):
        with self.assertRaisesRegex(Blocked, 'Unknown observation'):
            self.job.observe('../../state', self.job.c['obligations'][0]['id'], 'malicious')
        with self.assertRaisesRegex(Blocked, 'argument types'):
            self.job.edit('stock.py', 'return False', 'return True', refactor='false')
        self.assertEqual(self.job.s['operations'], 0)

    def test_reviewer_is_read_only_even_if_it_calls_edit(self):
        self.job.s['phase'] = 'reviewer'
        self.job.persist()
        with self.assertRaisesRegex(Blocked, 'read-only'):
            self.job.tool('edit', {'path': 'stock.py', 'old': 'return False', 'new': 'return True'}, 'current')

    def test_stale_broker_is_fenced(self):
        with self.assertRaisesRegex(Blocked, 'Stale'):
            self.job.tool('inspect', {}, 'old-attempt')

    def test_approved_proof_cannot_be_edited(self):
        with self.assertRaisesRegex(Blocked, 'outside approved'):
            self.job.edit('test_acceptance.py', 'assertIs', 'assertIsNot')

    def test_tool_edit_saves_real_checkpoint(self):
        before = self.job.s['candidate']
        self.job.s['observed']['unit'] = {'candidate': before, 'contract': self.job.s['contract'],
                                        'kind': 'unit', 'exit': 1, 'assertion_failure': True,
                                        'unit_development': {'classification': 'unit-development-failure', 'executed_tests': 1}}
        self.job.persist()
        self.job.tool('edit', {'path': 'stock.py', 'old': 'def reserve(self, item, quantity):\n        return False',
                              'new': 'def reserve(self, item, quantity):\n        return True'}, 'current')
        self.assertNotEqual(before, self.job.s['candidate'])
        self.assertEqual(self.job.s['operations'], 1)
        self.assertIsNone(self.job.s['pending'])

    def test_implementation_without_actual_unit_red_is_refused(self):
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'return False', 'return True')
        self.assertEqual(self.job.s['operations'], 0)

    def test_unit_green_requires_same_acceptance_before_more_edits(self):
        self.job.s['needs_outer_observation'] = True
        with self.assertRaisesRegex(Blocked, 'rerun the SAME'):
            self.job.edit('test_unit.py', 'self.assertEqual', 'self.assertEqual')

    def test_pending_patch_replays_without_refunding_work(self):
        self.job.s['operations'] = 7
        self.job.s['pending'] = {'path': 'stock.py', 'text': 'complete\n', 'implementation': True}
        self.job.persist()
        (self.job.source / 'stock.py').write_text('partial')
        restored = Job(self.job.path)
        restored.apply_pending()
        self.assertEqual((restored.source / 'stock.py').read_text(), 'complete\n')
        self.assertEqual(restored.s['operations'], 7)
        self.assertTrue(restored.s['implementation_pending'])
        self.assertIsNone(restored.s['pending'])

    def test_interrupted_review_does_not_reinvoke_builder(self):
        self.job.s['phase'] = 'reviewer'
        self.job.persist()
        roles = []
        def review(role, feedback):
            roles.append(role)
            return json.dumps({'verdict': 'accept', 'candidate': self.job.s['candidate'],
                               'contract': self.job.s['contract'], 'findings': []})
        self.job.model = review
        self.job.run()
        self.assertEqual(roles, ['reviewer'])
        self.assertEqual(self.job.s['status'], 'candidate-accepted-non-production')

    def test_second_red_example_cannot_steal_active_selection(self):
        self.job.s['active_example'] = self.job.c['examples'][0]['id']
        with self.assertRaisesRegex(Blocked, 'active red'):
            self.job.observe('example', self.job.c['examples'][1]['id'], 'expected red')

    def test_unit_and_acceptance_operations_do_not_spawn_model_sessions(self):
        # Tools consume operations, never additional provider handoffs.
        self.job.edit('test_unit.py', "self.assertEqual", "self.assertEqual")
        self.assertEqual(self.job.s['visits'], 0)


if __name__ == '__main__':
    unittest.main()
