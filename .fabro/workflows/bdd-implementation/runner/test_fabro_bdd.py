import json
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from candidate import Blocked, command, digest
from fabro_bdd import activate_examples, begin, cleanup, validate_run_key, verified_result
from session_candidate import Job, ResumeVisit, create


class ActivationTest(unittest.TestCase):
    def test_only_selected_iteration_is_activated_without_moving_lines(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            p = root / 'acceptance-tests/features/member.feature'
            p.parent.mkdir(parents=True)
            original = ('Feature: Member\n  @iteration-068 @todo\n  Scenario: Correct name\n'
                        '    Given Alice\n  @iteration-069 @todo\n  Scenario: Photo\n    Given Alice\n')
            p.write_text(original)
            examples = [{'uri': 'features/member.feature', 'name': 'Correct name'}]
            proof = activate_examples(root, examples, 'iteration-068')
            self.assertEqual(p.read_text(), original.replace('@iteration-068 @todo', '@iteration-068 '))
            self.assertEqual(len(p.read_text().splitlines()), len(original.splitlines()))
            self.assertEqual(proof[0]['original_sha256'], __import__('hashlib').sha256(original.encode()).hexdigest())
            self.assertNotEqual(proof[0]['activated_sha256'], proof[0]['original_sha256'])

    def test_missing_ambiguous_and_wrong_iteration_are_not_silently_selected(self):
        for body, name in [('Feature: Member\n', 'Missing'),
                           ('Feature: Member\n @iteration-069 @todo\n Scenario: Name\n Given Alice\n', 'Name'),
                           ('Feature: Member\n @iteration-068 @todo\n Scenario: Name\n Given Alice\n'
                            ' @iteration-068 @todo\n Scenario: Name\n Given Alice\n', 'Name')]:
            with self.subTest(body=body), tempfile.TemporaryDirectory() as d:
                root = Path(d); p = root / 'acceptance-tests/features/member.feature'
                p.parent.mkdir(parents=True); p.write_text(body)
                with self.assertRaises(Blocked):
                    activate_examples(root, [{'uri': 'features/member.feature', 'name': name}], 'iteration-068')
                self.assertEqual(p.read_text(), body)

    def test_activation_is_transactional_across_files(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); p = root / 'acceptance-tests/features/member.feature'
            p.parent.mkdir(parents=True); original = 'Feature: Member\n @iteration-068 @todo\n Scenario: Name\n Given Alice\n'
            p.write_text(original)
            with self.assertRaises(Blocked):
                activate_examples(root, [{'uri': 'features/member.feature', 'name': 'Name'},
                                         {'uri': 'features/member.feature', 'name': 'Missing'}], 'iteration-068')
            self.assertEqual(p.read_text(), original)

    def test_run_key_is_not_a_path_or_shell_program(self):
        for key in ['', '../old', '/tmp/job', "x'; touch /tmp/escape", 'a' * 100]:
            with self.subTest(key=key), self.assertRaises(Blocked):
                validate_run_key(key)
        self.assertEqual(validate_run_key('068-abc-123'), '068-abc-123')


class ResultTest(unittest.TestCase):
    def test_summary_alone_is_not_acceptance(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'state.json').write_text(json.dumps({'status': 'candidate-accepted-non-production',
                                                        'candidate': 'a' * 40, 'contract': 'b' * 64}))
            with self.assertRaises(Blocked):
                verified_result(root)


class RecoveryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(); self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        fixtures = Path(__file__).resolve().parents[4] / 'spikes/unattended_delivery'
        subprocess.run([sys.executable, str(fixtures / 'prepare_session_canary.py'),
                        str(self.root / 'trial'), '/usr/bin/true'], check=True, stdout=subprocess.DEVNULL)
        self.source = self.root / 'trial/source'
        self.c = json.loads((self.root / 'trial/contract.json').read_text())
        self.c.update(automatic_continuation=True, max_provider_recoveries=2, preserve_source_history=True)
        contract = self.root / 'contract.json'; contract.write_text(json.dumps(self.c))
        create(self.root / 'job', self.source, contract, digest(self.c))
        self.job = Job(self.root / 'job')

    def test_checkpoint_descends_from_original_source(self):
        self.assertEqual(subprocess.run(['git', 'merge-base', '--is-ancestor', self.c['source_sha'],
                                        self.job.s['candidate']], cwd=self.job.path / 'checkpoints').returncode, 0)
        self.assertEqual(command(['git', 'show', self.c['source_sha'] + ':stock.py'], self.job.path / 'checkpoints'),
                         (self.source / 'stock.py').read_text().rstrip())

    def test_provider_recovery_retains_session_candidate_deadline_and_spent_budget(self):
        identity = {k: self.job.s[k] for k in ['builder_session', 'candidate', 'contract', 'deadline']}
        calls = []
        def model(role, feedback):
            calls.append(role)
            self.job.s['visits'] += 1; self.job.persist()
            if len(calls) == 1: raise ResumeVisit('provider', 0, 'typed upstream failure')
            for k, value in identity.items(): self.assertEqual(self.job.s[k], value)
            self.assertEqual(self.job.s['visits'], 2)
            raise Blocked('test finished after automatic continuation')
        self.job.model = model
        with patch('session_candidate.time.sleep'), self.assertRaisesRegex(Blocked, 'test finished'):
            self.job.run()
        self.assertEqual(calls, ['builder', 'builder'])
        self.assertEqual(len(self.job.s['continuations']), 1)

    def test_review_interruption_does_not_restart_implementation(self):
        self.job.s['phase'] = 'reviewer'; self.job.persist(); calls = []
        def model(role, feedback):
            calls.append(role)
            if len(calls) == 1: raise ResumeVisit('provider', 0, 'typed review outage')
            raise Blocked('test review continued')
        self.job.model = model
        with patch('session_candidate.time.sleep'), self.assertRaisesRegex(Blocked, 'review continued'):
            self.job.run()
        self.assertEqual(calls, ['reviewer', 'reviewer'])
        self.assertEqual(self.job.s['review_retry_candidate'], self.job.s['candidate'])

    def test_recovery_limit_is_terminal_without_resetting_history(self):
        self.job.model = lambda *_: (_ for _ in ()).throw(ResumeVisit('provider', 0, 'outage'))
        with patch('session_candidate.time.sleep'), self.assertRaisesRegex(Blocked, 'recovery budget'):
            self.job.run()
        self.assertEqual(len(self.job.s['continuations']), 2)
        self.assertEqual(self.job.s['provider_recoveries'], 2)

    def test_full_gate_precedes_review_of_the_same_snapshot(self):
        # The current iteration contract has no learning-canary red quota.
        self.job.c['outer_red_proof'] = {}
        self.job.c['final_product_gate'] = True
        self.job.s['phase'] = 'checking'
        events = []
        self.job.observe = lambda *_: {'receipt': {'exit': 0}}
        def gate():
            events.append('gate')
            return {'exit': 0}
        def review(role, *_):
            events.append(role)
            return json.dumps({'verdict': 'accept', 'findings': [],
                               'candidate': self.job.s['candidate'], 'contract': self.job.s['contract']})
        self.job.product_gate = gate; self.job.model = review
        self.job.step()
        self.assertEqual(events, ['gate', 'reviewer'])
        self.assertEqual(self.job.s['status'], 'candidate-accepted-non-production')

    def test_failed_full_gate_returns_to_builder_without_review_or_acceptance(self):
        self.job.c['final_product_gate'] = True
        self.job.s.update(phase='product-gate', product_gate={'receipt': 'evidence/failed-gate.json'})
        self.job.product_gate = lambda: {'exit': 1}
        self.job.model = lambda *_: self.fail('No reviewer before full gate green')
        self.job.step()
        self.assertEqual(self.job.s['phase'], 'builder')
        self.assertEqual(self.job.s['status'], 'running')


class OwnershipTest(unittest.TestCase):
    def test_fabro_identity_is_exclusive_idempotent_and_cleanup_is_fenced(self):
        with tempfile.TemporaryDirectory() as d:
            first = begin(d, '01M4P49DJ09RBZZBK0YXMN2VBS')
            self.assertEqual(begin(d, first['run_id']), first)
            with self.assertRaises(Blocked): begin(d, '01M4P49DJ09RBZZBK0YXMN2VBZ')
            with self.assertRaises(Blocked): cleanup(d, '01M4P49DJ09RBZZBK0YXMN2VBZ')
            self.assertEqual(cleanup(d, first['run_id']), {'decision': 'proceed'})
            self.assertEqual(begin(d, '01M4P49DJ09RBZZBK0YXMN2VBZ')['status'], 'active')


class RuntimeCapabilitiesTest(unittest.TestCase):
    @unittest.skipUnless(os.environ.get('WORKFLOW_ELIXIR_RUNTIME'), 'Real private runtime required')
    def test_formatter_uses_actual_mix_and_never_writes_candidate(self):
        import memba_runtime
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); runtime = root / 'runtime'; source = root / 'candidate'
            runtime.mkdir(); (runtime / 'source').mkdir(); (runtime / 'home').mkdir()
            approved = Path(os.environ['WORKFLOW_ELIXIR_RUNTIME'])
            config = json.loads((approved / 'runtime.json').read_text())
            for name in memba_runtime.CACHES:
                shutil.copytree(approved / 'source' / name, runtime / 'source' / name, symlinks=True)
            shutil.copytree(approved / 'etc', runtime / 'etc', symlinks=True)
            shutil.copytree(approved / 'home', runtime / 'home', symlinks=True, dirs_exist_ok=True)
            config.update(retain_execution_copies=False)
            config['cache_digest'] = memba_runtime.cache_digest(runtime / 'source')
            (runtime / 'runtime.json').write_text(json.dumps(config))
            (source / 'web/lib').mkdir(parents=True)
            (source / 'web/mix.exs').write_text('defmodule Probe.MixProject do\n use Mix.Project\n def project, do: [app: :probe, version: "0.1.0"]\nend\n')
            raw = 'defmodule Allowed do\n def value,do: 1\nend\n'
            (source / 'web/lib/allowed.ex').write_text(raw)
            (source / 'web/lib/forbidden.ex').write_text('untouched\n')
            code, output, formatted = memba_runtime.run(runtime, 'format', 'cd web; mix format lib/allowed.ex',
                seconds=120, candidate=source, capture=True, format_paths=['web/lib/allowed.ex'])
            self.assertEqual(code, 0, output)
            self.assertNotEqual(formatted['web/lib/allowed.ex'], raw)
            self.assertEqual((source / 'web/lib/allowed.ex').read_text(), raw)
            self.assertEqual((source / 'web/lib/forbidden.ex').read_text(), 'untouched\n')
            receipts = list(runtime.glob('*/receipt.json'))
            self.assertEqual(len(receipts), 1)
            r = json.loads(receipts[0].read_text())
            self.assertFalse(r['source_unchanged'])
            self.assertFalse(r['unpermitted_source_changed'])

    @unittest.skipUnless(os.environ.get('WORKFLOW_ELIXIR_RUNTIME'), 'Real namespace probe required')
    def test_full_gate_fixture_root_is_writable_without_extra_server_lifecycle(self):
        import memba_runtime
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); work = root / 'work'; home = root / 'home'
            approved = Path(os.environ['WORKFLOW_ELIXIR_RUNTIME'])
            shutil.copytree(approved / 'etc', root / 'etc', symlinks=True)
            config = json.loads((approved / 'runtime.json').read_text()); (root / 'runtime.json').write_text(json.dumps(config))
            home.mkdir(); (work / 'acceptance-tests/node_modules/installed').mkdir(parents=True)
            (work / 'acceptance-tests/node_modules/installed/file').write_text('immutable\n')
            script = 'mkdir /work/acceptance-tests/node_modules/probe; printf screenshot > /work/tmp/report; test ! -w /work/acceptance-tests/node_modules/installed/file'
            args = memba_runtime.argv(root, work, home, script, node_fixtures=True)
            self.assertNotIn('MEMBA_NODE_CHECK', args[-1])
            args[-1] = script
            self.assertEqual(subprocess.run(args, capture_output=True).returncode, 0)
            self.assertFalse((work / 'acceptance-tests/node_modules/probe').exists())
            self.assertEqual((work / 'tmp/report').read_text(), 'screenshot')
