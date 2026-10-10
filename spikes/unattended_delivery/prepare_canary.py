#!/usr/bin/env python3
"""Prepare a fresh source repo and contract; prints the exact admission command."""
import json
from pathlib import Path
import shlex
import shutil
import sys

from candidate import command, digest, save

root = Path(sys.argv[1]).resolve()
root.mkdir()
source = root / 'source'
shutil.copytree(Path(__file__).parent / 'canary', source, ignore=shutil.ignore_patterns('__pycache__'))
command(['git', 'init', '-q'], source)
command(['git', 'add', '.'], source)
command(['git', '-c', 'user.name=Canary preparation', '-c', 'user.email=canary@invalid',
         'commit', '-qm', 'Approved non-production canary baseline'], source)
c = {
    'source_sha': command(['git', 'rev-parse', 'HEAD'], source),
    'authority': 'non-production-candidate-only',
    'outcome': 'Reserve a positive integer quantity of a known item: return True and deduct stock. Refuse overselling with ValueError without changing counts. Stock owns a copy of the caller counts; later caller mutations and reservations must not affect each other. Invalid/nonpositive quantities and unknown items must raise ValueError without mutation. No persistence, concurrency, UI, production or Memba changes.',
    'examples': [{'id': 'ReservationExample.test_reserve_then_refuse_oversell',
                  'command': ['/usr/bin/python3', '-m', 'unittest', '-v',
                              'test_acceptance.ReservationExample.test_reserve_then_refuse_oversell'],
                  'selection_marker': 'Ran 1 test'}],
    'obligations': [
        {'id': 'dependency-independence', 'proof': 'AST check; no runtime dependencies',
         'command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_architecture']},
        {'id': 'unit-regression', 'proof': 'All accumulated unit tests pass; reviewer checks input ownership and invalid quantities',
         'command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_unit']}],
    'editable': ['stock.py', 'test_unit.py'], 'unit_files': ['test_unit.py'],
    'context_files': ['test_acceptance.py', 'test_architecture.py'],
    'unit_command': ['/usr/bin/python3', '-m', 'unittest', '-v', 'test_unit'],
    'model': 'claude-sonnet-4-6', 'max_calls': 24, 'call_seconds': 120,
    'call_usd': 0.75, 'deadline_seconds': 1800, 'max_restarts': 3,
}
save(root / 'contract.json', c)
print('Contract digest:', digest(c))
print('Discovered executable paths are required, not inferred by this helper:')
print(shlex.join(['python3', str(Path(__file__).parent / 'candidate.py'), 'create',
                  str(root / 'job'), str(source), str(root / 'contract.json'), digest(c),
                  'ABSOLUTE_BWRAP_PATH', 'ABSOLUTE_CLAUDE_PATH']))
