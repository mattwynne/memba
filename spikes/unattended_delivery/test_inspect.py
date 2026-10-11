import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from candidate import Blocked, digest
from session_candidate import Job, create


class InspectTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        subprocess.run([sys.executable, str(Path(__file__).with_name('prepare_session_canary.py')),
                        str(self.root / 'trial'), '/usr/bin/true'], check=True, stdout=subprocess.DEVNULL)
        trial = self.root / 'trial'
        c = json.loads((trial / 'contract.json').read_text())
        create(trial / 'job', trial / 'source', trial / 'contract.json', digest(c))
        self.job = Job(trial / 'job')
        self.job.s['active_attempt'] = 'current'
        self.job.persist()
        self.evidence = self.job.path / 'evidence'
        self.text = ('alpha \U0001f984 café\r\n' + 'x' * 13000 + '\nneedle final\n') * 2
        (self.job.source / 'long.txt').write_bytes(self.text.encode())
        (self.evidence / '0001-unit.stdout').write_bytes(self.text.encode())
        (self.evidence / '0001-unit.json').write_text(json.dumps({'candidate': 'proof-sha', 'exit': 2}))

    def inspect(self, **args):
        return self.job.tool('inspect', args, 'current')

    def collect_text(self, path):
        offset, chunks, hashes = 0, [], set()
        while True:
            page = self.inspect(path=path, offset=offset, limit=700)
            self.assertEqual(page['offset'], offset)
            self.assertEqual(page['returned_chars'], len(page['content']))
            self.assertEqual(page['returned_utf8_bytes'], len(page['content'].encode()))
            self.assertLessEqual(len(page['content']), 700)
            chunks.append(page['content']); hashes.add(page['sha256'])
            if not page['truncated']:
                self.assertIsNone(page['next_offset']); break
            self.assertGreater(page['next_offset'], offset)
            offset = page['next_offset']
        self.assertEqual(len(hashes), 1)
        return ''.join(chunks)

    def test_default_relevant_inventory_not_full_repo_contract_or_receipt_dump(self):
        (self.job.source / 'unrelated.txt').write_text('still explicitly readable')
        declared = sorted(set(self.job.c['editable'] + self.job.c['context_files'] + self.job.c['unit_files']))
        result = self.inspect()
        self.assertEqual(result['files'], declared)
        self.assertEqual(result['total_items'], len(declared))
        self.assertNotIn('contract', result)
        self.assertNotIn('observations', result)
        self.assertEqual(result['contract_digest'], self.job.s['contract'])
        self.assertEqual(result['proof_ids']['obligation'], [o['id'] for o in self.job.c['obligations']])
        self.assertEqual(result['receipts_count'], 0)
        self.assertEqual(self.inspect(path='unrelated.txt')['content'], 'still explicitly readable')
        self.assertIn('unrelated.txt', self.inspect(path='@files')['files'])

    def test_inventory_pagination_is_sorted_complete_and_deterministic(self):
        names = sorted(set(self.job.c['editable'] + self.job.c['context_files'] + self.job.c['unit_files']))
        collected, offset = [], 0
        while True:
            page = self.inspect(offset=offset, limit=2)
            self.assertEqual(page, self.inspect(offset=offset, limit=2))
            self.assertEqual(page['total_items'], len(names))
            collected += page['files']
            if page['next_offset'] is None: break
            offset = page['next_offset']
        self.assertEqual(collected, names)
        self.assertFalse(page['truncated'])

    def test_long_unicode_and_single_line_source_is_losslessly_paged(self):
        self.assertEqual(self.collect_text('long.txt'), self.text)
        page = self.inspect(path='long.txt')
        self.assertEqual(page['total_chars'], len(self.text))
        self.assertEqual(page['total_utf8_bytes'], len(self.text.encode()))
        self.assertLessEqual(page['returned_chars'], 4000)
        self.assertTrue(page['truncated'])
        hit = self.inspect(path='long.txt', query='needle', limit=30)
        self.assertEqual(hit['offset'], self.text.index('needle'))
        self.assertEqual(hit['match_offset'], self.text.index('needle'))
        self.assertTrue(hit['content'].startswith('needle'))
        self.assertEqual(hit['match_line'], 3)
        absent = self.inspect(path='long.txt', query='not here')
        self.assertIsNone(absent['match_offset'])
        self.assertEqual(absent['content'], '')
        self.assertFalse(absent['truncated'])

    def test_full_contract_and_exact_evidence_remain_available_to_reviewer(self):
        self.job.s['phase'] = 'reviewer'; self.job.persist()
        self.assertEqual(json.loads(self.collect_text('@contract')), self.job.c)
        self.assertEqual(self.inspect(path='@contract')['sha256'], self.job.s['contract'])
        self.assertEqual(self.collect_text('@evidence/0001-unit.stdout'), self.text)
        old_receipt = json.loads(self.collect_text('@evidence/0001-unit.json'))
        self.assertEqual(old_receipt, {'candidate': 'proof-sha', 'exit': 2})
        page = self.inspect(path='@evidence/0001-unit.json')
        self.assertEqual(page['current_candidate'], self.job.s['candidate'])
        self.assertNotEqual(page['current_candidate'], old_receipt['candidate'])
        names = self.inspect(path='@evidence')['files']
        self.assertIn('0001-unit.json', names)
        self.assertIn('0001-unit.stdout', names)
        with self.assertRaisesRegex(Blocked, 'read-only'):
            self.job.tool('edit', {'path': 'test_unit.py', 'old': 'import unittest', 'new': '# nope'}, 'current')
        with self.assertRaisesRegex(Blocked, 'read-only'):
            self.job.tool('observe', {'kind': 'unit', 'id': 'unit', 'prediction': 'no'}, 'current')

    def test_no_read_scope_expansion_or_guard_bypass(self):
        secret = self.root / 'host-secret'; secret.write_text('never returned')
        (self.job.source / 'escape').symlink_to(secret)
        (self.evidence / 'escape').symlink_to(secret)
        for path in ['../state.json', str(secret), 'escape', '@evidence/escape',
                     '@evidence/../state.json', '@evidence/' + str(secret)]:
            with self.subTest(path=path), self.assertRaisesRegex(Blocked, 'Read outside'):
                self.inspect(path=path)
        for args in [{'offset': -1}, {'offset': True}, {'offset': 1.5}, {'limit': 0},
                     {'limit': True}, {'limit': 101}, {'path': 'long.txt', 'limit': 8001},
                     {'path': 'long.txt', 'offset': len(self.text) + 1}, {'path': 'long.txt', 'query': ''},
                     {'path': 'long.txt', 'query': 'x' * 257}, {'query': 'no'}, {'path': []}, {'shell': 'ls'}]:
            with self.subTest(args=args), self.assertRaises(Blocked): self.inspect(**args)
        with self.assertRaisesRegex(Blocked, 'Stale'):
            self.job.tool('inspect', {'path': '@contract'}, 'wrong')
        with self.assertRaisesRegex(Blocked, 'ACTUAL'):
            self.job.edit('stock.py', 'return False', 'return True')

    def test_real_broker_schema_and_paging_offline_no_worker_or_model(self):
        process = subprocess.Popen([sys.executable, str(Path(__file__).with_name('session_candidate.py')),
                                    'broker', str(self.job.path), 'current'], stdin=subprocess.PIPE,
                                   stdout=subprocess.PIPE, text=True)
        def request(method, params):
            process.stdin.write(json.dumps({'jsonrpc': '2.0', 'id': 1, 'method': method, 'params': params}) + '\n')
            process.stdin.flush()
            return json.loads(process.stdout.readline())['result']
        try:
            tools = request('tools/list', {})['tools']
            self.assertEqual({t['name'] for t in tools}, {'inspect', 'edit', 'observe'})
            schema = next(t for t in tools if t['name'] == 'inspect')['inputSchema']
            self.assertEqual(set(schema['properties']), {'path', 'offset', 'limit', 'query'})
            reply = request('tools/call', {'name': 'inspect', 'arguments': {'path': 'long.txt', 'limit': 80}})
            value = json.loads(reply['content'][0]['text'])
            self.assertEqual(value['returned_chars'], 80)
            self.assertTrue(value['truncated'])
        finally:
            process.stdin.close(); process.wait(timeout=5); process.stdout.close()
        self.assertEqual(process.returncode, 0)
        self.assertEqual(Job(self.job.path).s['operations'], 0)


if __name__ == '__main__': unittest.main()
