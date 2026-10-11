"""Workflow fixtures: retained real failure, simulated diagnostics, real ExUnit cycles."""
import json
import os
from pathlib import Path
import shutil
import time
import unittest
from unittest.mock import patch

from candidate import Blocked, digest
import test_session_candidate as fixture_module


class UnitDevelopmentTest(unittest.TestCase):
    def setUp(self):
        fixture = fixture_module.SessionCandidateTest()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.job = fixture.job
        self.unit = 'web/test/memba/membership/person_rename_test.exs'
        self.product = 'web/lib/memba/membership/commands/rename_person.ex'
        self.module = 'Memba.Membership.Commands.RenamePerson'
        self.job.c['unit_files'].append(self.unit)
        self.job.c['editable'] += [self.unit, self.product]
        target = self.job.source / self.unit
        target.parent.mkdir(parents=True)
        target.write_text('alias ' + self.module + '\n%RenamePerson{person_id: "p", name: "A", expected_name: "B"}\n')
        self.job.checkpoint()
        runtime = fixture.root / 'runtime'
        runtime.mkdir()
        (runtime / 'runtime.json').write_text('{}')
        self.job.c.update(runtime_root=str(runtime), runtime_digest=digest({}),
                          unit_kind='domain', unit_script='approved unit gate')
        for spec in self.job.c['examples']: spec['script'] = 'approved outer command'
        self.compile_error = Path(__file__).with_name('fixtures').joinpath('unit_compile_error.txt').read_text()
        self.scaffold = ('defmodule ' + self.module + ' do\n'
                         '  defstruct [:person_id, :name, :expected_name]\nend\n')

    def observe(self, code, output, kind='unit', identity=None):
        with patch('memba_runtime.run', return_value=(code, output)):
            return self.job.observe(kind, identity, 'workflow regression observation')

    def test_exact_live_dead_end_is_actionable_not_behavioral_red(self):
        result = self.observe(1, self.compile_error)
        self.assertEqual(self.job.s['status'], 'running')
        self.assertEqual(result['receipt']['count'], 0)
        self.assertEqual(result['receipt']['exit'], 1)
        self.assertFalse(result['receipt']['behavioral_red'])
        self.assertEqual(result['receipt']['unit_development']['repair_paths'], [self.product])
        self.assertIn('cannot expand struct', result['output'])
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'return False', 'return True')
        self.job.edit(self.product, '', self.scaffold)
        with self.assertRaisesRegex(Blocked, 'Rerun.*unit'):
            self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# later')
        with self.assertRaisesRegex(Blocked, 'Rerun.*unit'):
            self.observe(0, 'Ran 1 test in 0.01s\nOK', 'example', self.job.c['examples'][0]['id'])

    def test_scaffold_to_executed_unit_red_fix_and_same_outer_rerun(self):
        outer = self.job.c['examples'][0]['id']
        self.observe(1, 'FAIL: current behavior\nRan 1 test in 0.01s\n', 'example', outer)
        self.observe(1, self.compile_error)
        self.job.edit(self.product, '', self.scaffold)
        red = self.observe(2, '  1) test behavior (Unit)\n     test_unit.py:10: (test)\n     Assertion with == failed\n1 test, 1 failure\n')
        self.assertTrue(red['receipt']['behavioral_red'])
        self.job.edit('stock.py', 'def reserve(self, item, quantity):\n        return False',
                      'def reserve(self, item, quantity):\n        return True')
        self.observe(0, '1 test, 0 failures\n')
        with self.assertRaisesRegex(Blocked, 'SAME'):
            self.observe(0, 'Ran 1 test in 0.01s\nOK', 'example', self.job.c['examples'][1]['id'])
        self.observe(0, 'Ran 1 test in 0.01s\nOK', 'example', outer)
        self.assertFalse(self.job.s['needs_outer_observation'])
        self.assertEqual(self.job.s['visits'], 0)

    def test_unrelated_missing_interface_does_not_grant_product_edits(self):
        output = self.compile_error.replace(self.module, 'Outside.Scope.Unknown')
        result = self.observe(1, output)
        self.assertEqual(result['receipt']['unit_development']['repair_paths'], [])
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit(self.product, '', self.scaffold)
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'return False', 'return True')

    def test_diagnostics_are_snapshot_and_contract_bound(self):
        self.observe(1, self.compile_error)
        self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# new snapshot')
        with self.assertRaisesRegex(Blocked, 'current-snapshot'):
            self.job.edit(self.product, '', self.scaffold)
        self.observe(1, self.compile_error)
        contract = self.job.path / 'contract.json'
        data = json.loads(contract.read_text()); data['outcome'] += ' changed'
        contract.write_text(json.dumps(data))
        with self.assertRaisesRegex(Blocked, 'Contract changed'):
            self.job.edit(self.product, '', self.scaffold)
        self.assertFalse((self.job.source / self.product).exists())

    def test_foreign_source_change_cannot_use_diagnostic(self):
        self.observe(1, self.compile_error)
        (self.job.source / self.unit).write_text('changed outside broker')
        with self.assertRaisesRegex(Blocked, 'Foreign source mutation'):
            self.job.edit(self.product, '', self.scaffold)

    def test_missing_module_function_allows_relevant_repair_not_forced_nil_placeholder(self):
        output = ('  1) test behavior (Unit)\n'
                  '** (UndefinedFunctionError) function ' + self.module + '.build/1 is undefined (module is not available)\n'
                  '     ' + self.unit.removeprefix('web/') + ':22: (test)\n1 test, 1 failure\n')
        result = self.observe(2, output)
        self.assertFalse(result['receipt']['behavioral_red'])
        self.assertIn(self.product, result['receipt']['unit_development']['repair_paths'])
        self.job.edit(self.product, '', 'defmodule ' + self.module + ' do\n  def build(value), do: value\nend\n')
        self.assertTrue(self.job.s['needs_unit_observation'])

    def test_generic_module_not_a_product_specific_exception(self):
        target = 'lib/warehouse/requests/place_order.ex'
        self.job.c['editable'].append(target)
        (self.job.source / self.unit).write_text('alias Warehouse.Requests.PlaceOrder\n%PlaceOrder{sku: "x", quantity: 2}\n')
        self.job.checkpoint()
        output = self.compile_error.replace(self.module, 'Warehouse.Requests.PlaceOrder')
        result = self.observe(1, output)
        self.assertEqual(result['receipt']['unit_development']['repair_paths'], [target])
        self.job.edit(target, '', 'defmodule Warehouse.Requests.PlaceOrder do\n  defstruct [:sku, :quantity]\nend\n')

    def test_real_zero_selection_infrastructure_and_final_checks_stay_terminal(self):
        for code, output, phase, kind in [
            (0, '0 tests, 0 failures\n', 'builder', 'unit'),
            (1, '** (DBConnection.ConnectionError) connection refused\n', 'builder', 'unit'),
            (1, 'bwrap: Creating namespace failed: Permission denied\n' + self.compile_error, 'builder', 'unit'),
            (1, '** (Postgrex.Error) ERROR 28P01 (invalid_password) password authentication failed\n' + self.compile_error, 'builder', 'unit'),
            (1, self.compile_error, 'checking', 'unit'),
            (1, self.compile_error, 'builder', 'example'),
            (1, '** (Cucumber.StepError) No matching step definition\n', 'builder', 'unit')]:
            with self.subTest(code=code, phase=phase, kind=kind):
                self.job.s.update(status='running', active_attempt='current', phase=phase)
                self.job.persist()
                identity = self.job.c['examples'][0]['id'] if kind == 'example' else None
                with self.assertRaisesRegex(Blocked, 'Infrastructure/selection'):
                    self.observe(code, output, kind, identity)
                self.assertEqual(self.job.s['status'], 'blocked')

    def test_executed_infrastructure_and_setup_errors_grant_no_implementation(self):
        for error, message in [('DBConnection.ConnectionError', 'connection refused'),
                               ('Postgrex.Error', 'ERROR 08006 (connection_failure) connection lost'),
                               ('RuntimeError', 'setup callback failed'),
                               ('Cucumber.StepError', 'No matching step definition'),
                               ('ExUnit.TimeoutError', 'test timed out'),
                               ('File.Error', 'could not write to file: permission denied')]:
            extra = '__ex_unit_setup_0/1' if error == 'RuntimeError' else ''
            output = ('  1) test behavior (Unit)\n** (' + error + ') ' + message + '\n'
                      + self.unit + ':22: (test)\n' + self.product + ':1: (function)\n'
                      + extra + '\n1 test, 1 failure\n')
            result = self.observe(2, output)
            self.assertIsNone(result['receipt']['unit_development'])
            with self.assertRaisesRegex(Blocked, 'ACTUAL'):
                self.job.edit(self.product, '', self.scaffold)

    def test_business_values_and_test_names_are_not_infrastructure_diagnostics(self):
        for title, expected in [('self-only authorization', '{:error, :unauthorized}'),
                                ('timeout preserves draft', '{:error, :timeout}'),
                                ('forbidden expected business value', '{:error, :forbidden}'),
                                ('Ecto.QueryError is data here', '%Ecto.QueryError{}')]:
            with self.subTest(title=title):
                output = ('  1) test ' + title + ' (PersonRenameTest)\n'
                          '     ' + self.unit.removeprefix('web/') + ':12\n'
                          '     Assertion with == failed\n'
                          '     code: assert result == ' + expected + '\n'
                          '     left: :ok\n     right: ' + expected + '\n1 test, 1 failure\n')
                result = self.observe(2, output)
                self.assertTrue(result['receipt']['behavioral_red'])
                self.assertEqual(result['receipt']['unit_development']['repair_paths'], [self.product])

    def test_application_query_and_constraint_errors_are_development_feedback(self):
        for error, message in [('Ecto.QueryError', 'invalid query'),
                               ('Ecto.ConstraintError', 'constraint error when attempting to insert'),
                               ('Postgrex.Error', 'ERROR 23505 (unique_violation) duplicate key value')]:
            with self.subTest(error=error):
                output = ('  1) test application query (Unit)\n** (' + error + ') ' + message + '\n'
                          + self.unit + ':22: (test)\n' + self.product + ':1: (function)\n'
                          '1 test, 1 failure\n')
                result = self.observe(2, output)
                self.assertFalse(result['receipt']['behavioral_red'])
                self.assertIn(self.product, result['receipt']['unit_development']['repair_paths'])

    def real_fixture(self, missing_clause=False):
        # Synthetic application fixture, REAL framework/runtime, NO provider.
        from memba_runtime import CACHES
        approved = Path(os.environ['WORKFLOW_ELIXIR_RUNTIME'])
        runtime = self.job.path.parent / 'real-exunit-runtime'
        runtime.mkdir()
        config = json.loads((approved / 'runtime.json').read_text())
        shutil.copytree(approved / 'etc', runtime / 'etc', symlinks=True)
        (runtime / 'home').mkdir()
        for name in CACHES: (runtime / 'source' / name).mkdir(parents=True)
        config = {k: config[k] for k in ['bwrap', 'env', 'etc_digest']}
        config.update(source_sha='0' * 40, files={}, retain_execution_copies=False)
        (runtime / 'runtime.json').write_text(json.dumps(config))
        self.job.c.update(runtime_root=str(runtime), runtime_digest=digest(config), check_seconds=60,
                          unit_script='elixir -r "lib/workflow/*.ex" web/test/workflow_test.exs')
        self.job.s['deadline'] = time.time() + 300
        unit, impl, request = 'web/test/workflow_test.exs', 'lib/workflow/amount.ex', 'lib/workflow/request.ex'
        self.job.c['editable'] += [unit, impl, request]
        self.job.c['unit_files'].append(unit)
        (self.job.source / impl).parent.mkdir(parents=True)
        implementation = ('def double(%{ready: true}), do: 0' if missing_clause else 'def double(_request), do: nil')
        (self.job.source / impl).write_text('defmodule Workflow.Amount do\n  ' + implementation + '\nend\n')
        argument = '%{value: 2}' if missing_clause else '%Workflow.Request{value: 2}'
        body = '    assert Workflow.Amount.double(' + argument + ') == 4\n'
        extra = '  test "existing clause" do\n    assert Workflow.Amount.double(%{ready: true}) == 0\n  end\n' if missing_clause else ''
        (self.job.source / unit).write_text('ExUnit.start()\ndefmodule Unit do\n  use ExUnit.Case\n  test "double" do\n' + body + '  end\n' + extra + 'end\n')
        outer_body = body if missing_clause else '    assert Code.ensure_loaded?(Workflow.Request)\n    assert Workflow.Amount.double(struct(Workflow.Request, value: 2)) == 4\n'
        (self.job.source / 'outer.exs').write_text('ExUnit.start()\ndefmodule Outer do\n  use ExUnit.Case\n  test "amount journey" do\n' + outer_body + '  end\nend\n')
        spec = self.job.c['examples'][0]
        spec.update(kind='domain', script='elixir -r "lib/workflow/*.ex" outer.exs')
        self.job.checkpoint()
        def observe(kind):
            return self.job.observe(kind, spec['id'] if kind == 'example' else None, 'real isolated fixture observation')['receipt']
        self.assertNotEqual(observe('example')['exit'], 0)
        red = observe('unit')
        if missing_clause:
            self.assertEqual(red['count'], 2)
            self.assertFalse(red['behavioral_red'])
        else:
            self.assertFalse(red['behavioral_red'])
            self.assertEqual(red['count'], 0)
            self.job.edit(request, '', 'defmodule Workflow.Request do\n  defstruct [:value]\nend\n')
            red = observe('unit')
            self.assertTrue(red['behavioral_red'])
        self.assertIn(impl, red['unit_development']['repair_paths'])
        repair = implementation + '\n  def double(%{value: value}), do: value * 2' if missing_clause else 'def double(request), do: request.value * 2'
        self.job.edit(impl, implementation, repair)
        self.assertEqual(observe('unit')['exit'], 0)
        self.assertTrue(self.job.s['needs_outer_observation'])
        self.assertEqual(observe('example')['exit'], 0)
        self.assertFalse(self.job.s['needs_outer_observation'])
        if os.environ.get('WORKFLOW_TEST_EVIDENCE'):
            dest = Path(os.environ['WORKFLOW_TEST_EVIDENCE']) / ('real-exunit-' + ('clause-' if missing_clause else 'compile-') + str(time.time_ns()))
            shutil.copytree(self.job.path / 'evidence', dest)
            print('Real ExUnit fixture evidence (no provider):', dest)

    @unittest.skipUnless(os.environ.get('WORKFLOW_ELIXIR_RUNTIME'), 'Set WORKFLOW_ELIXIR_RUNTIME for real isolated ExUnit fixture')
    def test_real_isolated_exunit_compile_scaffold_red_fix_green_outer(self):
        self.real_fixture()

    @unittest.skipUnless(os.environ.get('WORKFLOW_ELIXIR_RUNTIME'), 'Set WORKFLOW_ELIXIR_RUNTIME for real isolated ExUnit fixture')
    def test_real_missing_clause_unit_failure_repair_green_same_outer(self):
        self.real_fixture(missing_clause=True)
