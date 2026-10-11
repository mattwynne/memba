"""Offline controller cuts: readable truth, no path-inference authority, finite bounds."""
import time
import unittest

from candidate import Blocked
import test_focused_units as focused


class SimplificationTest(unittest.TestCase):
    def setUp(self):
        fixture = focused.FocusedUnitsTest(); fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.fixture, self.job = fixture, fixture.job

    def test_brief_start_resume_review_prompts_point_to_full_truth_not_copies(self):
        self.job.c['outcome'] = 'DO_NOT_EMBED_FULL_OUTCOME_' * 1000
        self.job.s['receipts'] = ['evidence/large.json'] * 1000
        self.job.s['feedback'] = 'DO_NOT_EMBED_FINDINGS_' * 1000
        self.job.s['observed'] = {'unit': {'large': 'x' * 100000}}
        for role in ['builder', 'reviewer']:
            prompt = self.job.model_prompt(role, '@evidence/current.context.json')
            self.assertLess(len(prompt.encode()), 2400)
            self.assertNotIn('DO_NOT_EMBED', prompt)
            self.assertNotIn('large.json', prompt)
            self.assertIn('@contract', prompt)
            self.assertIn('@evidence', prompt)
            self.assertIn(self.job.s['candidate'], prompt)
            self.assertIn(self.job.s['contract'], prompt)
        self.assertIn('whole', self.job.model_prompt('reviewer', '@evidence/current.context.json'))

    def test_approved_transitive_router_repair_needs_no_trace_or_test_alias(self):
        name = 'router.py'; (self.job.source / name).write_text('registered = False\n')
        self.job.c['editable'].append(name); self.job.checkpoint(); self.fixture.seal()
        self.assertNotIn('router', (self.job.source / 'test_unit.py').read_text())
        result, _ = self.fixture.observe()
        self.assertNotIn('repair_paths', result['receipt']['unit_development'])
        self.job.edit(name, 'False', 'True')
        self.assertEqual(self.job.s['required_unit_selector'], 'stock')
        with self.assertRaisesRegex(Blocked, 'SAME.*unit'):
            self.fixture.observe('other', code=0, output='1 test, 0 failures\n')
        self.fixture.observe('stock', code=0, output='1 test, 0 failures\n')
        self.assertEqual((self.job.source / name).read_text(), 'registered = True\n')

    def test_scope_stale_review_deadline_and_green_only_guards_survive(self):
        self.fixture.observe()
        with self.assertRaises(Blocked): self.job.edit('outside.py', '', 'unauthorized')
        with self.assertRaisesRegex(Blocked, 'Stale'):
            self.job.tool('inspect', {}, 'other-attempt')
        self.job.s['phase'] = 'reviewer'; self.job.persist()
        with self.assertRaisesRegex(Blocked, 'read-only'):
            self.job.tool('edit', {'path': 'stock.py', 'old': 'False', 'new': 'True'}, 'current')
        self.job.s.update(phase='builder', deadline=time.time()-1); self.job.persist()
        with self.assertRaisesRegex(Blocked, 'deadline'):
            self.job.tool('inspect', {}, 'current')

    def test_no_green_focus_or_stale_diagnostic_product_authority(self):
        self.fixture.observe(code=0, output='1 test, 0 failures\n')
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.fixture.repair_stock()
        self.fixture.observe()
        self.job.edit('test_unit.py', 'import unittest', 'import unittest\n# changed')
        with self.assertRaisesRegex(Blocked, 'current-snapshot'):
            self.fixture.repair_stock()


if __name__ == '__main__': unittest.main()
