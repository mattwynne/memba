"""Trusted selector/feedback-routing regressions; no provider or product edits."""
import copy
import json
import unittest
from unittest.mock import patch

from candidate import Blocked, digest
from session_candidate import Job, create
import test_session_candidate as fixtures


class FocusedUnitsTest(unittest.TestCase):
    def setUp(self):
        f = fixtures.SessionCandidateTest()
        f.setUp()
        self.addCleanup(f.doCleanups)
        self.f, self.job = f, f.job
        runtime = f.root / 'runtime'
        runtime.mkdir()
        (runtime / 'runtime.json').write_text('{}')
        self.job.c.update(runtime_root=str(runtime), runtime_digest=digest({}),
                          unit_kind='domain', unit_script='broad approved command',
                          focused_units=[{'id': 'stock', 'paths': ['test_unit.py'],
                                          'kind': 'domain', 'script': 'focused approved command'},
                                         {'id': 'other', 'paths': ['test_other.py'],
                                          'kind': 'domain', 'script': 'other approved command'}],
                          acceptance_support_files=['driver.py'])
        for spec in self.job.c['examples'] + self.job.c['obligations']:
            spec['script'] = 'approved command ' + spec['id']
        self.job.c['unit_files'] += ['test_other.py', 'driver.py']
        self.job.c['editable'] += ['test_other.py', 'driver.py']
        (self.job.source / 'test_other.py').write_text('import stock\n')
        (self.job.source / 'driver.py').write_text('driver = 1\n')
        self.job.checkpoint()
        self.seal()
        self.outer = self.job.c['examples'][0]['id']
        self.red = '  1) test reserve (Unit)\n     test_unit.py:10: (test)\n     Assertion with == failed\n1 test, 1 failure\n'

    def repair_stock(self, refactor=False):
        return self.job.edit('stock.py', 'def reserve(self, item, quantity):\n        return False',
                             'def reserve(self, item, quantity):\n        return True', refactor)

    def seal(self):
        (self.job.path / 'contract.json').write_text(json.dumps(self.job.c))
        self.job.s['contract'] = digest(self.job.c)
        self.job.persist()

    def observe(self, identity='stock', code=2, output=None, kind='unit'):
        with patch('memba_runtime.run', return_value=(code, self.red if output is None else output)) as run:
            result = self.job.observe(kind, identity, 'labelled regression prediction')
        return result, run

    def test_id_selects_only_the_declared_command_and_records_selection(self):
        result, run = self.observe()
        self.assertEqual(run.call_args.args[2], 'focused approved command')
        self.assertEqual(result['receipt']['unit_selector'], 'stock')
        self.assertEqual(result['receipt']['unit_paths'], ['test_unit.py'])
        self.assertEqual(self.job.s['observed']['unit'], result['receipt'])
        self.assertEqual(result['receipt']['unit_development']['classification'], 'unit-development-failure')

    def test_unknown_selection_and_caller_commands_have_no_capability(self):
        for identity in ['unknown', 'stock; touch /tmp/escape']:
            with self.assertRaisesRegex(Blocked, 'unit selection'):
                self.observe(identity)
        with self.assertRaisesRegex(Blocked, 'arguments'):
            self.job.tool('observe', {'kind': 'unit', 'id': 'stock', 'prediction': 'no',
                                      'script': 'arbitrary shell'}, 'current')
        self.assertEqual(self.job.s['operations'], 0)

    def test_product_repair_requires_the_same_focused_rerun_then_same_outer(self):
        self.observe(self.outer, kind='example', code=1, output='FAIL: outer\nRan 1 test in 0.01s\n')
        self.observe()
        self.repair_stock()
        for identity in ['other', 'unit', None]:
            with self.assertRaisesRegex(Blocked, 'SAME.*unit'):
                self.observe(identity, code=0, output='1 test, 0 failures\n')
        restored = Job(self.job.path)
        self.assertEqual(restored.s['required_unit_selector'], 'stock')
        self.job = restored
        self.observe(code=0, output='1 test, 0 failures\n')
        with self.assertRaisesRegex(Blocked, 'SAME'):
            self.observe(self.job.c['examples'][1]['id'], kind='example', code=0,
                         output='Ran 1 test in 0.01s\nOK\n')
        with self.assertRaisesRegex(Blocked, 'SAME'):
            self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# next')
        self.observe(self.outer, kind='example', code=0, output='Ran 1 test in 0.01s\nOK\n')
        self.assertFalse(self.job.s['needs_outer_observation'])

    def test_stale_out_of_scope_and_focused_green_cannot_authorize_product(self):
        self.observe()
        self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# changed')
        with self.assertRaisesRegex(Blocked, 'current-snapshot'):
            self.repair_stock()
        self.observe()
        with self.assertRaises(Blocked):
            self.job.edit('outside.py', '', 'unapproved')
        self.observe(code=0, output='1 test, 0 failures\n')
        with self.assertRaises(Blocked):
            self.repair_stock(refactor=True)

    def test_focused_compile_feedback_and_zero_success_are_distinct(self):
        output = '** (CompileError) test_unit.py:12: cannot compile module\n'
        result, _ = self.observe(code=1, output=output)
        self.assertEqual(result['receipt']['count'], 0)
        self.assertFalse(result['receipt']['behavioral_red'])
        self.assertIsNotNone(result['receipt']['unit_development'])
        with self.assertRaisesRegex(Blocked, 'Infrastructure/selection'):
            self.observe(code=0, output='0 tests, 0 failures\n')

    def test_driver_edits_require_direct_same_outer_but_can_be_coherent_batch(self):
        self.observe(self.outer, kind='example', code=1, output='FAIL: driver\nRan 1 test in 0.01s\n')
        reply = self.job.edit('driver.py', '1', '2')
        self.assertFalse(self.job.s.get('needs_unit_observation', False))
        self.assertIn('acceptance', reply['development_guidance'])
        self.job.edit('driver.py', '2', '3')
        with self.assertRaisesRegex(Blocked, 'acceptance'):
            self.observe('unit', code=0, output='1 test, 0 failures\n')
        with self.assertRaisesRegex(Blocked, 'acceptance'):
            self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# unrelated')
        with self.assertRaisesRegex(Blocked, 'SAME'):
            self.observe(self.job.c['examples'][1]['id'], kind='example', code=0,
                         output='Ran 1 test in 0.01s\nOK\n')
        self.observe(self.outer, kind='example', code=1, output='FAIL: next obstacle\nRan 1 test in 0.01s\n')
        self.assertFalse(self.job.s['support_observation_pending'])

    def test_driver_edit_cannot_skip_pending_product_unit_check(self):
        self.observe()
        self.repair_stock()
        with self.assertRaisesRegex(Blocked, 'Rerun.*unit'):
            self.job.edit('driver.py', '1', '2')

    def test_no_focus_in_final_phase_and_final_obligations_are_always_rerun(self):
        self.observe(code=0, output='1 test, 0 failures\n')
        self.job.s['phase'] = 'checking'
        self.job.persist()
        with self.assertRaisesRegex(Blocked, 'builder'):
            self.observe()
        calls = []
        def run(root, kind, script, *args, **kwargs):
            calls.append((kind, script))
            return (0 if kind == 'example' else 1, 'Ran 1 test in 0.01s\n')
        def model(role, feedback):
            self.assertEqual(role, 'builder', 'Failed broad obligations must not reach reviewer')
            raise Blocked('broad regression failed; fixture stop')
        self.job.model = model
        with patch('memba_runtime.run', side_effect=run):
            with self.assertRaisesRegex(Blocked, 'broad regression failed'):
                self.job.run()
        self.assertEqual([k for k, _ in calls], ['example'] * len(self.job.c['examples']) +
                         ['obligation'] * len(self.job.c['obligations']))
        self.assertNotEqual(self.job.s['status'], 'candidate-accepted-non-production')

    def test_focused_runtime_failure_is_not_limited_to_assertion_red(self):
        result, _ = self.observe(output='  1) test reserve (Unit)\n'
                                '** (FunctionClauseError) no function clause\n'
                                '     stock.py:3: (function)\n     test_unit.py:10: (test)\n'
                                '1 test, 1 failure\n')
        self.assertFalse(result['receipt']['behavioral_red'])
        self.assertEqual(result['receipt']['unit_development']['classification'], 'unit-development-failure')
        self.repair_stock()
        self.assertEqual(self.job.s['required_unit_selector'], 'stock')

    def test_focused_infrastructure_failure_cannot_authorize_product(self):
        result, _ = self.observe(output='  1) test reserve (Unit)\n'
                                '** (DBConnection.ConnectionError) connection refused\n'
                                '     stock.py:3: (function)\n     test_unit.py:10: (test)\n'
                                '1 test, 1 failure\n')
        self.assertIsNone(result['receipt']['unit_development'])
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.repair_stock()

    def test_focused_command_is_contract_bound_before_invocation(self):
        c = copy.deepcopy(self.job.c)
        c['focused_units'][0]['script'] = 'changed command'
        (self.job.path / 'contract.json').write_text(json.dumps(c))
        with patch('memba_runtime.run') as run:
            with self.assertRaisesRegex(Blocked, 'Contract changed'):
                self.job.observe('unit', 'stock', 'contract tamper fixture')
        run.assert_not_called()

    def test_focused_selection_cannot_follow_a_symlink_to_another_test(self):
        target = self.job.source / 'test_unit.py'
        target.unlink()
        target.symlink_to('test_other.py')
        # Prepare the synthetic mirror too; real model edits cannot create links.
        (self.job.path / 'checkpoints/test_unit.py').unlink()
        self.job.checkpoint()
        with patch('memba_runtime.run') as run:
            with self.assertRaisesRegex(Blocked, 'Unsafe file'):
                self.job.observe('unit', 'stock', 'symlink selection fixture')
        run.assert_not_called()

    def test_focused_observation_is_source_bound_before_invocation(self):
        (self.job.source / 'stock.py').write_text('changed outside broker')
        with patch('memba_runtime.run') as run:
            with self.assertRaisesRegex(Blocked, 'Foreign source mutation'):
                self.job.observe('unit', 'stock', 'source tamper fixture')
        run.assert_not_called()

    def test_support_route_survives_reload_and_handles_first_driver_creation(self):
        self.job.edit('driver.py', '1', '2')
        self.job = Job(self.job.path)
        with self.assertRaisesRegex(Blocked, 'acceptance'):
            self.observe()
        self.observe(self.outer, kind='example', code=1, output='FAIL: driver\nRan 1 test in 0.01s\n')
        self.assertFalse(self.job.s['support_observation_pending'])

    def test_all_final_checks_and_independent_review_still_required_after_focus_green(self):
        # Satisfy, rather than remove, this synthetic canary's extra red-history rule.
        for identity, minimum in self.job.c.get('outer_red_proof', {}).items():
            for number in range(minimum):
                output = ('FAIL: canary fixture\n  File "test_examples.py", line ' + str(number + 1) +
                          ', in test_canary\n    self.assertTrue(result)\nAssertionError: fixture ' +
                          str(number) + '\nRan 1 test in 0.01s\n')
                self.observe(identity, kind='example', code=1, output=output)
        self.observe(code=0, output='1 test, 0 failures\n')
        self.job.s['phase'] = 'checking'
        self.job.persist()
        calls, roles = [], []
        def run(root, kind, script, *args, **kwargs):
            calls.append((kind, script))
            return 0, 'Ran 1 test in 0.01s\nOK\n'
        def model(role, feedback):
            roles.append(role)
            self.assertEqual(role, 'reviewer')
            with self.assertRaisesRegex(Blocked, 'read-only'):
                self.job.tool('edit', {'path': 'driver.py', 'old': '1', 'new': '2'}, 'current')
            return json.dumps({'verdict': 'accept', 'candidate': self.job.s['candidate'],
                               'contract': self.job.s['contract'], 'findings': []})
        self.job.model = model
        with patch('memba_runtime.run', side_effect=run):
            self.job.run()
        self.assertEqual(calls, [('example', s['script']) for s in self.job.c['examples']] +
                         [('obligation', s['script']) for s in self.job.c['obligations']])
        self.assertEqual(roles, ['reviewer'])
        self.assertEqual(self.job.s['status'], 'candidate-accepted-non-production')

    def test_valid_declared_selector_can_be_admitted_without_new_file_authority(self):
        c = json.loads((self.f.root / 'contract.json').read_text())
        original_editable = c['editable'][:]
        c['focused_units'] = [{'id': 'stock', 'paths': ['test_unit.py'], 'kind': 'unittest',
                               'command': c['unit_command']}]
        contract = self.f.root / 'valid-focused.json'; contract.write_text(json.dumps(c))
        create(self.f.root / 'valid-focused', self.f.root / 'source', contract, digest(c))
        admitted = Job(self.f.root / 'valid-focused')
        self.assertEqual(admitted.c['editable'], original_editable)
        self.assertEqual(admitted.c['obligations'], c['obligations'])

    def test_admission_rejects_undeclared_paths_collisions_and_ambiguous_commands(self):
        base = copy.deepcopy(self.job.c)
        # Use ordinary canary admission (no full runtime archive) for validation.
        for key in ['runtime_root', 'runtime_digest']: base.pop(key)
        for spec in base['focused_units']:
            spec.pop('script'); spec['command'] = ['python3', '-m', 'unittest', 'test_unit.py']
        variants = []
        for change in [lambda c: c['focused_units'][0].update(paths=['outside.py']),
                       lambda c: c['focused_units'][0].update(id=c['examples'][0]['id']),
                       lambda c: c['focused_units'][0].update(id='unit'),
                       lambda c: c['focused_units'][0].update(paths=['driver.py']),
                       lambda c: c['focused_units'][0].update(script='shell'),
                       lambda c: c['focused_units'][0].update(paths=[]),
                       lambda c: c['focused_units'][0].update(kind='browser'),
                       lambda c: c['focused_units'].append(copy.deepcopy(c['focused_units'][0])),
                       lambda c: c['focused_units'][0].update(command='untrusted string'),
                       lambda c: c.update(acceptance_support_files=['stock.py'])]:
            c = copy.deepcopy(base); change(c); variants.append(c)
        for index, c in enumerate(variants):
            with self.subTest(index=index):
                contract = self.f.root / 'bad-focused.json'; contract.write_text(json.dumps(c))
                with self.assertRaises(Blocked):
                    create(self.f.root / f'bad-focused-{index}', self.f.root / 'source', contract, digest(c))
