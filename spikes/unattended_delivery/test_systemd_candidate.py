"""Opt-in real supervisor crash test. The model is explicitly a routing double.

RUN_SYSTEMD_CANDIDATE_TEST=1 python3 -m unittest discover \
  -s spikes/unattended_delivery -p test_systemd_candidate.py -v
Needs pre-existing noninteractive sudo for systemd; never changes that authority.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

from candidate import create, digest


@unittest.skipUnless(os.environ.get('RUN_SYSTEMD_CANDIDATE_TEST') == '1',
                     'Explicit opt-in required for a transient system service')
class SystemdRecoveryTest(unittest.TestCase):
    def test_actual_controller_kill_fences_descendant_and_preserves_budget(self):
        with tempfile.TemporaryDirectory(prefix='candidate-crash-') as tmp:
            root = Path(tmp) / 'rehearsal'
            here = Path(__file__).parent
            subprocess.run([sys.executable, str(here / 'prepare_canary.py'), str(root)],
                           check=True, stdout=subprocess.DEVNULL)
            model = root / 'fixture_model.py'
            model.write_text('''#!/usr/bin/python3
import json, os, pathlib, subprocess, time
p = pathlib.Path.cwd().parent
counter = p / 'fixture-count'
n = int(counter.read_text()) + 1 if counter.exists() else 1
counter.write_text(str(n))
if n == 1:
    child = subprocess.Popen(['/usr/bin/sleep', '90'], start_new_session=True)
    (p / 'fixture-child').write_text(str(child.pid))
    time.sleep(90)
else:
    print(json.dumps({'is_error': True, 'subtype': 'fixture_stop'}))
''')
            model.chmod(0o700)
            c = json.loads((root / 'contract.json').read_text())
            job = root / 'job'
            create(job, root / 'source', root / 'contract.json', digest(c),
                   '/usr/bin/true', model)
            unit = 'memba-candidate-' + hashlib.sha256(str(job).encode()).hexdigest()[:16] + '.service'
            subprocess.run(['bash', str(here / 'dispatch.sh'), str(job)], check=True,
                           capture_output=True, text=True)
            try:
                deadline = time.monotonic() + 30
                while not (job / 'fixture-child').exists():
                    if time.monotonic() > deadline:
                        self.fail('Fixture did not start')
                    time.sleep(0.1)
                child = int((job / 'fixture-child').read_text())
                before = json.loads((job / 'state.json').read_text())
                subprocess.run(['sudo', '-n', 'systemctl', 'kill', '--kill-whom=main',
                                '--signal=KILL', unit], check=True)
                while True:
                    state = json.loads((job / 'state.json').read_text())
                    if state['status'] == 'blocked':
                        break
                    if time.monotonic() > deadline:
                        self.fail('Service did not recover autonomously')
                    time.sleep(0.1)
                self.assertEqual(state['calls'], 2)
                self.assertEqual(state['starts'], 2)
                self.assertEqual(state['candidate'], before['candidate'])
                self.assertEqual(state['deadline'], before['deadline'])
                self.assertEqual(state['contract'], before['contract'])
                self.assertFalse(Path(f'/proc/{child}').exists(), 'Escaped descendant survived')
                self.assertTrue(list((job / 'evidence').glob('0001-builder.stdout')))
                self.assertIn('Invalid model response', state['blocker'])
                # Keep an independently inspectable minimal result outside temp cleanup.
                receipt = {'test': self.id(), 'unit': unit, 'killed_descendant': child,
                           'before': before, 'after': state,
                           'service_log': (job / 'service.log').read_text()}
                destination = Path(os.environ.get('CANDIDATE_CRASH_RECEIPT',
                                                  '/tmp/memba-candidate-crash-receipt.json'))
                destination.write_text(json.dumps(receipt, indent=2))
            finally:
                subprocess.run(['sudo', '-n', 'systemctl', 'stop', unit], check=False)


if __name__ == '__main__':
    unittest.main()
