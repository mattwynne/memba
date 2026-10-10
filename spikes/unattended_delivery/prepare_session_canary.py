#!/usr/bin/env python3
"""New declared experiment, not a reset/resume of the preserved 0/3 jobs."""
import json
from pathlib import Path
import shutil
import sys

from candidate import command, digest, save

root = Path(sys.argv[1]).resolve()
root.mkdir()
source = root / 'source'
shutil.copytree(Path(__file__).parent / 'canary', source, ignore=shutil.ignore_patterns('__pycache__'))
with (source / 'stock.py').open('a') as stream:
    stream.write('\n    def release(self, item, quantity):\n        return False\n')
with (source / 'test_acceptance.py').open('a') as stream:
    stream.write('''
        self.assertIs(stock.release('tea', 1), True)
        self.assertEqual(stock.available('tea'), 4)

    def test_invalid_reservations_are_atomic(self):
        for quantity in [0, -1, 1.5, True, "2", None]:
            with self.subTest(quantity=quantity):
                stock = Stock({'tea': 5})
                with self.assertRaises(ValueError):
                    stock.reserve('tea', quantity)
                self.assertEqual(stock.available('tea'), 5)
        stock = Stock({'tea': 5})
        with self.assertRaises(ValueError):
            stock.reserve('unknown', 1)
        self.assertEqual(stock.available('tea'), 5)
        self.assertNotIn('unknown', stock.counts)
''')
command(['git', 'init', '-q'], source)
command(['git', 'add', '.'], source)
command(['git', '-c', 'user.name=Canary preparation', '-c', 'user.email=canary@invalid',
         'commit', '-qm', 'Two-example non-production contract, including explicit invalid input policy'], source)
examples = ['test_reserve_then_refuse_oversell', 'test_invalid_reservations_are_atomic']
c = {'source_sha': command(['git', 'rev-parse', 'HEAD'], source),
     'authority': 'non-production-candidate-only',
     'outcome': 'Reserve positive integer quantities of known items, deduct stock, and return True. Refuse overselling and invalid quantities with ValueError without mutation. Python bool is not an accepted integer quantity. A separate release(item, quantity) command restores a positive integer quantity to a known item and returns True; it rejects invalid quantities and unknown items with ValueError without mutation. Stock owns its own copy of caller counts: neither later caller mutations nor reservations may affect the other. No persistence, concurrency, UI, publication or Memba product changes.',
     'examples': [{'id': name, 'kind': 'unittest', 'command': ['/usr/bin/python3', '-m', 'unittest', '-v',
                    'test_acceptance.ReservationExample.' + name]} for name in examples],
     'obligations': [
        {'id': 'dependency-independence', 'proof': 'AST check, no runtime dependencies',
         'command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_architecture']},
        {'id': 'regressions-and-ownership', 'proof': 'Accumulated unit tests plus independent inspection of caller ownership',
         'command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_unit']}],
     'editable': ['stock.py', 'test_unit.py'], 'unit_files': ['test_unit.py'],
     'context_files': ['test_acceptance.py', 'test_architecture.py'],
     'unit_command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_unit'],
     'model': sys.argv[3] if len(sys.argv) > 3 else 'claude-sonnet-4-6', 'effort': 'high',
     'outer_red_proof': {'test_reserve_then_refuse_oversell': 2},
     'claude': str(Path(shutil.which('claude')).resolve()),
     'bwrap': sys.argv[2], 'max_visits': 6, 'max_operations': 100, 'visit_seconds': 600,
     'check_seconds': 30, 'visit_usd': 4, 'deadline_seconds': 1800, 'max_restarts': 2,
     'budget_basis': 'Previous job spent 17 isolated visits on tiny edits and reviews. Now at most three coherent builder/reviewer pairs; ten minutes per tool-capable visit includes all local test loops. 100 actual operations bounds tool use, 30 seconds per tiny check, 30 minutes overall. No prior job limits changed.'}
save(root / 'contract.json', c)
print(digest(c))
