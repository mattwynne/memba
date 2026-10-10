"""Opt-in actual systemd fencing/restart test for the session controller.

The model executable is a labelled double, NOT judgment or live-resume evidence.
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

from candidate import digest
from session_candidate import create


@unittest.skipUnless(os.environ.get('RUN_SYSTEMD_CANDIDATE_TEST') == '1',
                     'Explicit opt-in required for a transient system service')
class SessionRecoveryTest(unittest.TestCase):
    def test_controller_kill_fences_tree_and_resumes_same_builder_identity(self):
        with tempfile.TemporaryDirectory(prefix='session-crash-') as tmp:
            root = Path(tmp) / 'trial'
            here = Path(__file__).parent
            subprocess.run([sys.executable, str(here / 'prepare_session_canary.py'), str(root), '/usr/bin/true'],
                           check=True, stdout=subprocess.DEVNULL)
            model = root / 'model-double.py'
            model.write_text('''#!/usr/bin/python3
import json,pathlib,subprocess,time
p=pathlib.Path.cwd().parent
counter=p/'fixture-count'
n=int(counter.read_text())+1 if counter.exists() else 1
counter.write_text(str(n))
if n==1:
    child=subprocess.Popen(['/usr/bin/sleep','90'],start_new_session=True)
    (p/'fixture-child').write_text(str(child.pid))
    time.sleep(90)
else:
    print(json.dumps({'is_error':True,'subtype':'fixture-stop'}))
''')
            model.chmod(0o700)
            c = json.loads((root / 'contract.json').read_text())
            c['claude'] = str(model)
            (root / 'contract.json').write_text(json.dumps(c))
            job = root / 'job'
            create(job, root / 'source', root / 'contract.json', digest(c))
            unit = 'memba-session-' + hashlib.sha256(str(job).encode()).hexdigest()[:16] + '.service'
            subprocess.run(['bash', str(here / 'dispatch_session.sh'), str(job)], check=True, capture_output=True)
            try:
                deadline = time.monotonic() + 30
                while not (job / 'fixture-child').exists():
                    if time.monotonic() > deadline:
                        self.fail('Fixture did not start')
                    time.sleep(0.1)
                child = int((job / 'fixture-child').read_text())
                before = json.loads((job / 'state.json').read_text())
                subprocess.run(['sudo', '-n', 'systemctl', 'kill', '--kill-whom=main', '--signal=KILL', unit], check=True)
                while True:
                    after = json.loads((job / 'state.json').read_text())
                    if after['status'] == 'blocked':
                        break
                    if time.monotonic() > deadline:
                        self.fail('Autonomous recovery did not complete')
                    time.sleep(0.1)
                self.assertEqual(after['starts'], 2)
                self.assertEqual(after['visits'], 2)
                for key in ['deadline', 'contract', 'candidate', 'builder_session']:
                    self.assertEqual(after[key], before[key])
                self.assertTrue(after['builder_started'])
                self.assertFalse(Path(f'/proc/{child}').exists())
                self.assertIn('fixture-stop', after['blocker'])
                self.assertTrue((job / 'evidence/model-01-builder.stdout').exists())
                Path('/tmp/memba-session-crash-receipt.json').write_text(json.dumps({
                    'before': before, 'after': after, 'killed_descendant': child,
                    'unit': unit, 'model_is_double': True}, indent=2))
            finally:
                subprocess.run(['sudo', '-n', 'systemctl', 'stop', unit], capture_output=True, check=False)


if __name__ == '__main__':
    unittest.main()
