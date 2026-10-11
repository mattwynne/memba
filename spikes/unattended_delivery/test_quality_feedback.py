"""Failed quality gates are feedback, never zero-execution proof or edit authority."""
import unittest
from unittest.mock import patch
from candidate import Blocked
import test_focused_units as focused


class QualityFeedbackTest(unittest.TestCase):
    def setUp(self):
        f = focused.FocusedUnitsTest(); f.setUp(); self.addCleanup(f.doCleanups)
        self.job = f.job
        spec = self.job.c['obligations'][0]
        spec.update(kind='domain', script='mix format --check-formatted && mix test')
        self.id = spec['id']; f.seal()

    def observe(self, code, output):
        with patch('memba_runtime.run', return_value=(code, output)):
            return self.job.observe('obligation', self.id, 'actual technical gate feedback')

    def test_failed_pretest_quality_gate_returns_failed_receipt_without_repair_authority(self):
        result = self.observe(1, '** (Mix) mix format failed due to --check-formatted.\n')
        receipt = result['receipt']
        self.assertEqual((receipt['exit'], receipt['count']), (1, 0))
        self.assertEqual(self.job.s['status'], 'running')
        self.assertIsNone(receipt['unit_development'])
        self.assertFalse(receipt['behavioral_red'])
        self.assertIn('not proof', result['development_guidance'])
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'False', 'True')
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'False', 'True', refactor=True)

    def test_zero_success_and_real_infrastructure_still_block(self):
        for code, output in [(0, '0 tests, 0 failures\n'),
                             (1, 'bwrap: Creating namespace failed: Permission denied\n'),
                             (1, '** (DBConnection.ConnectionError) connection refused\n')]:
            with self.subTest(code=code, output=output):
                self.job.s.update(status='running', active_attempt='current', phase='builder'); self.job.persist()
                with self.assertRaisesRegex(Blocked, 'Infrastructure/selection'):
                    self.observe(code, output)

    def test_final_failed_quality_check_routes_to_builder_not_reviewer_or_acceptance(self):
        calls = []
        def run(root, kind, script, *args, **kwargs):
            return (1, '** (Mix) mix format failed due to --check-formatted.\n') if kind == 'obligation' else (0, 'Ran 1 test in 0.01s\nOK\n')
        def model(role, feedback):
            calls.append(role)
            self.assertEqual(role, 'builder')
            self.assertEqual(self.job.s['status'], 'running')
            raise Blocked('fixture stops for real builder correction')
        self.job.model = model
        with patch('memba_runtime.run', side_effect=run):
            with self.assertRaisesRegex(Blocked, 'real builder correction'): self.job.run()
        self.assertEqual(calls, ['builder'])
        self.assertNotEqual(self.job.s['status'], 'candidate-accepted-non-production')


if __name__ == '__main__': unittest.main()
