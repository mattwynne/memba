"""Offline Sol gates and process doubles; no provider calls."""
import copy
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from candidate import Blocked, digest
from sol_provider import runtime_digest, validate_provider, model_command
import test_session_candidate as fixture_module


class SolProviderTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.sdk = self.root / 'sdk'; self.sdk.mkdir()
        (self.sdk / 'index.js').write_text('// fixed SDK double')
        self.node = self.root / 'node'; self.node.write_text('node-double')
        self.c = {'model_backend': 'pi-sol', 'model': 'gpt-6.1-sol', 'visit_usd': None,
                  'sol_provider': {'provider': 'openai-codex', 'api': 'openai-codex-responses',
                    'base_url': 'https://chatgpt.com/backend-api', 'sdk_root': str(self.sdk),
                    'sdk_digest': runtime_digest(self.sdk), 'node': str(self.node),
                    'node_sha256': hashlib.sha256(self.node.read_bytes()).hexdigest(),
                    'model_digest': 'a' * 64, 'max_turns': 12, 'visit_token_limit': 10000, 'thinking': 'low'}}

    def test_exact_explicit_identity_no_dollar_cap_or_fallback(self):
        validate_provider(self.c, verify=True)
        for key, value in [('model', 'gpt-6-astra'), ('claude', '/bin/claude'), ('visit_usd', 10)]:
            with self.subTest(key=key):
                c = dict(self.c, **{key: value})
                with self.assertRaises(Blocked): validate_provider(c)
        for key, value in [('provider', 'openai'), ('base_url', 'http://proxy'),
                           ('thinking', 'ultra'), ('max_turns', 0), ('max_turns', True),
                           ('visit_token_limit', float('inf'))]:
            with self.subTest(key=key):
                c = copy.deepcopy(self.c); c['sol_provider'][key] = value
                with self.assertRaises(Blocked): validate_provider(c)

    def test_new_explicit_accounting_only_contract_and_legacy_no_migration(self):
        before = copy.deepcopy(self.c)
        validate_provider(self.c)
        self.assertEqual(self.c, before)
        c = copy.deepcopy(self.c)
        del c['sol_provider']['visit_token_limit']
        c['sol_provider'].update(token_policy='accounting-only', max_turns=160)
        validate_provider(c, verify=True)
        for changes in [{'visit_token_limit': 2000000}, {'token_policy': 'unlimited'},
                        {'max_turns': 161}, {'max_turns': 0}, {'max_turns': True}]:
            bad = copy.deepcopy(c); bad['sol_provider'].update(changes)
            with self.subTest(changes=changes), self.assertRaises(Blocked): validate_provider(bad)
        del c['sol_provider']['token_policy']
        with self.assertRaises(Blocked): validate_provider(c)

    def test_full_runtime_and_node_fingerprint_fail_closed(self):
        (self.sdk / 'index.js').write_text('// mutation')
        with self.assertRaisesRegex(Blocked, 'SDK runtime changed'): validate_provider(self.c, True)
        self.c['sol_provider']['sdk_digest'] = runtime_digest(self.sdk)
        self.node.write_text('other-node')
        with self.assertRaisesRegex(Blocked, 'Node runtime changed'): validate_provider(self.c, True)

    def test_fixed_adapter_command_no_native_shell_or_provider_flags(self):
        cmd = model_command(self.c, self.root, 'attempt', 'reviewer', self.root / 'evidence', 'system', False)
        self.assertEqual(cmd[:2], [str(self.node), str(self.root / 'sol_adapter.mjs')])
        self.assertEqual(cmd[4:7], ['reviewer', str(self.root / 'evidence'), 'new'])
        self.assertNotIn('--dangerously-bypass-approvals-and-sandbox', cmd)
        self.assertNotIn('--max-budget-usd', cmd)

    def test_sdk_offline_scope_resume_review_suite(self):
        script = Path(__file__).with_name('test_sol_adapter.mjs')
        result = subprocess.run(['node', '--test', str(script)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_unknown_subscription_dollars_and_actual_tokens_survive_error(self):
        fixture = fixture_module.SessionCandidateTest(); fixture.setUp(); self.addCleanup(fixture.doCleanups)
        job = fixture.job; job.c.update(self.c)
        fake = fixture.root / 'sol-double'
        fake.write_text('#!' + sys.executable + '\n' + '''
import json, pathlib, sys
sys.stdin.read()
p=pathlib.Path(sys.argv[1])
p.with_suffix('.usage.json').write_text(json.dumps({'session_id':'sol-builder','usage':{'input':19,'cacheRead':3000000,'cacheWrite':0,'output':7,'totalTokens':3000026},'usage_complete':False,'reported_cost_usd':None,'estimated_cost_usd':0.0001}))
print(json.dumps({'provider':'openai-codex','model':'gpt-6.1-sol','is_error':True,'subtype':'error','result':'provider refusal','total_cost_usd':None}))
sys.exit(1)
'''); fake.chmod(0o755)
        with patch('sol_provider.model_command', side_effect=lambda c, p, a, r, prefix, s, resume: [str(fake), str(prefix)]):
            with self.assertRaisesRegex(Blocked, 'Model executor error'): job.model('builder', 'observe')
        self.assertEqual(job.s['visits'], 1)
        self.assertIsNone(job.s['reported_cost_usd']); self.assertFalse(job.s['reported_cost_complete'])
        self.assertEqual(job.s['known_reported_cost_usd'], 0)
        self.assertEqual(job.s['provider_usage'][0]['usage'], {'input':19,'cacheRead':3000000,'cacheWrite':0,'output':7,'totalTokens':3000026})
        context = job.inspect('@evidence/model-01-builder.context.json')['content']
        self.assertEqual(json.loads(context), {'feedback': 'observe'})
        prompt = (job.path / 'evidence/model-01-builder.prompt').read_text()
        self.assertIn('@evidence/model-01-builder.context.json', prompt)
        self.assertNotIn('"feedback": "observe"', prompt)
        self.assertEqual(job.s['sol_builder_session'], 'sol-builder')
        self.assertTrue(json.loads((job.path / 'evidence/model-01-builder.visit.json').read_text())['reaped'])

    def test_fake_success_with_other_model_is_blocked(self):
        fixture = fixture_module.SessionCandidateTest(); fixture.setUp(); self.addCleanup(fixture.doCleanups)
        job = fixture.job; job.c.update(self.c)
        fake = fixture.root / 'sol-double'
        fake.write_text('#!' + sys.executable + '\nimport json,sys\nsys.stdin.read()\nprint(json.dumps({"provider":"openai-codex","model":"gpt-6-astra","subtype":"success","is_error":False,"result":"ok"}))\n')
        fake.chmod(0o755)
        with patch('sol_provider.model_command', return_value=[str(fake)]):
            with self.assertRaisesRegex(Blocked, 'identity mismatch'): job.model('builder', 'observe')


if __name__ == '__main__': unittest.main()
