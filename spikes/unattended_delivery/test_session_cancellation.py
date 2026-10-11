"""Owned local model-process doubles, never provider/network calls."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unittest

from candidate import Blocked
import test_session_candidate as fixture_module


class TerminalVisitCancellationTest(unittest.TestCase):
    def setUp(self):
        fixture = fixture_module.SessionCandidateTest()
        fixture.setUp()
        self.addCleanup(fixture.doCleanups)
        self.job = fixture.job
        self.fake = fixture.root / 'model-double'
        self.job.c.update(claude=str(self.fake), visit_seconds=15)

    def test_terminal_broker_state_stops_and_reaps_only_owned_visit(self):
        self.fake.write_text('#!' + sys.executable + '\n' + '''
import json, os, pathlib, sys, time
sys.stdin.read()
root = pathlib.Path.cwd().parent
(root / 'model.pid').write_text(str(os.getpid()))
print('partial provider output', flush=True)
print('partial provider stderr', file=sys.stderr, flush=True)
s = json.loads((root / 'state.json').read_text())
s.update(status='blocked', blocker='terminal selection failure', active_attempt=None)
p = root / 'state.new'; p.write_text(json.dumps(s)); p.replace(root / 'state.json')
while True: time.sleep(60)
''')
        self.fake.chmod(0o755)
        unrelated = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'])
        try:
            start = time.monotonic()
            with self.assertRaisesRegex(Blocked, 'terminal selection failure'):
                self.job.model('builder', 'observe')
            self.assertLess(time.monotonic() - start, 5)
            self.assertIsNone(unrelated.poll())
            pid = int((self.job.path / 'model.pid').read_text())
            with self.assertRaises(ProcessLookupError): os.kill(pid, 0)
            self.assertEqual(self.job.s['status'], 'blocked')
            self.assertEqual(self.job.s['visits'], 1)
            self.assertEqual(self.job.s['starts'], 0)
            self.assertIsNone(self.job.s['reported_cost_usd'])
            self.assertFalse(self.job.s['reported_cost_complete'])
            prefix = self.job.path / 'evidence/model-01-builder'
            self.assertIn('partial provider output', prefix.with_suffix('.stdout').read_text())
            self.assertIn('partial provider stderr', prefix.with_suffix('.stderr').read_text())
            receipt = json.loads(prefix.with_suffix('.visit.json').read_text())
            self.assertEqual(receipt['cancelled'], 'terminal selection failure')
            self.assertIsNone(receipt['reported_cost_usd'])
            self.assertTrue(receipt['reaped'])
        finally:
            unrelated.terminate(); unrelated.wait(timeout=5)

    def test_error_envelope_cost_is_recorded_before_model_error(self):
        self.fake.write_text('#!' + sys.executable + '\n' + '''
import json, sys
sys.stdin.read()
print(json.dumps({'is_error':True, 'subtype':'error', 'total_cost_usd':0.125}))
sys.exit(1)
''')
        self.fake.chmod(0o755)
        with self.assertRaisesRegex(Blocked, 'Model executor error'):
            self.job.model('builder', 'observe')
        self.assertEqual(self.job.s['reported_cost_usd'], 0.125)
        self.assertTrue(self.job.s['reported_cost_complete'])
