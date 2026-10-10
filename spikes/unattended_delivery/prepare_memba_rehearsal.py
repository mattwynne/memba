#!/usr/bin/env python3
"""Approve a read-only current-main runtime rehearsal, NOT product 068 implementation."""
import json
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

from candidate import digest, save

root, runtime = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
root.mkdir()
config = json.loads((runtime / 'runtime.json').read_text())
selectors = [
    {'uri': 'features/list_members.feature', 'name': 'A member sees assigned roles in the member list'},
    {'uri': 'features/list_members.feature', 'name': 'A removed member had a role'},
    {'uri': 'features/journeys/member_onboarding.feature',
     'name': 'Alice joins Kootenay, signs back in, and returns to a private message'}]
examples = json.loads(subprocess.check_output(['node', str(Path(__file__).with_name('select_examples.cjs')),
                      str(runtime / 'source'), json.dumps(selectors)], text=True))
for example in examples:
    if example['kind'] == 'domain':
        example['script'] = 'cd web; ' + shlex.join(['mix', 'test',
            'test/features/domain_cucumber_acceptance_test.exs', '--only', 'scenario_name:' + example['name']])
    else:
        example['script'] = 'cd acceptance-tests; ' + shlex.join(['node_modules/.bin/cucumber-js',
                                                example['uri'] + ':' + str(example['line'])])
unit = 'cd web; mix test test/dependency_contract_test.exs'
c = {'source_sha': config['source_sha'], 'authority': 'non-production-candidate-only',
     'outcome': 'READ-ONLY baseline rehearsal. Observe the three existing selected examples at their real domain/browser boundaries and prove the explicit dependency obligation. Existing green behavior must remain green: do not manufacture red, edit source, implement 068, change contracts, publish or deploy. This is runtime validation, not new product delivery.',
     'examples': examples, 'obligations': [{'id': 'dependency-contract', 'kind': 'domain',
         'proof': 'Existing Memba dependency architecture test at the approved revision', 'script': unit}],
     'editable': [], 'unit_files': [],
     'context_files': sorted({'acceptance-tests/' + e['uri'] for e in examples}),
     'unit_script': unit, 'unit_kind': 'domain', 'runtime_root': str(runtime),
     'runtime_digest': digest(config),
     'model': 'claude-sonnet-4-6', 'claude': str(Path(shutil.which('claude')).resolve()),
     'max_visits': 2, 'max_operations': 30, 'visit_seconds': 600, 'check_seconds': 90,
     'visit_usd': 4, 'deadline_seconds': 1200, 'max_restarts': 2,
     'memory_mb': 4096, 'tasks_max': 512, 'file_size_mb': 128,
     'budget_basis': 'Measured isolated domain command ~15 seconds and actual browser ~23 seconds. 90 seconds per check is ~3x observed browser cold duration; one ten-minute builder visit includes four checks and inspection. One independent read-only review, 20-minute job, no repair/product-edit authority. OTP startup strace proved a 64 MiB JIT memfd: 16 MiB RLIMIT_FSIZE kills even elixir --version. This new job declares a finite 128 MiB per-file cap; old job is not modified.'}
save(root / 'contract.json', c)
print(digest(c))
