#!/usr/bin/env python3
"""Fresh native trials; receipts are the record, and reporting never launches anything."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'bdd-scenario-implementation/eval'))
from navigator import wilson

TERMINAL = {'succeeded', 'failed', 'cancelled', 'canceled', 'interrupted'}


def read_json(file):
    try:
        return json.loads(file.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def report(out):
    manifest = read_json(out / 'manifest.json')
    trials = []
    for trial in sorted(out.glob('trial-*')):
        launch, wait, grade = [read_json(trial / name) for name in ('launch.json', 'wait.json', 'grade.json')]
        trials.append({'trial': trial.name, 'run_id': launch.get('run_id'), 'status': wait.get('status', 'unknown'),
                       'passed': wait.get('status') == 'succeeded' and grade.get('passed', False),
                       'grade': grade or {'error': 'Not graded; inspect saved receipts'}})
    finished = sum(t['status'] in TERMINAL for t in trials)
    passed = sum(t['passed'] for t in trials)
    summary = {**manifest, 'attempted': len(trials), 'finished': finished, 'passed': passed,
               'not_run': manifest['requested'] - len(trials), 'wilson_95': wilson(passed, finished), 'trials': trials}
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(f"{passed}/{finished} finished trials passed; {summary['not_run']} not run; evidence: {out}", flush=True)
    return summary


def prepare(root, out, runs):
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=root):
        raise ValueError('The historical checkout must be clean')
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', 'HEAD',
                                      '.fabro/workflows/bdd-plan-implementation/eval'], cwd=root, text=True).splitlines()
    if set(tracked) - {'.fabro/workflows/bdd-plan-implementation/eval/.gitignore'}:
        raise ValueError('Use a fresh historical checkout without eval code or prepared results')
    out.relative_to(root)
    out.mkdir(parents=True)  # No overwrites, uncertain relaunches or replacement trials.
    (out / 'manifest.json').write_text(json.dumps({'requested': runs, 'source': subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()}, indent=2) + '\n')
    # These ignored host files are bundled by Fabro, not copied into the managed clone.
    script = "set -eu\nif [ ! -d acceptance-tests/node_modules/@cucumber/gherkin ]; then npm ci --prefix acceptance-tests --ignore-scripts --no-audit --no-fund; fi\nnode <<'DOUBLE'\n"
    script += (HERE / 'double.cjs').read_text() + '\ncomplete(' + json.dumps((HERE / 'cases/core.patch').read_text()) + ');\nDOUBLE\n'
    (out / 'double.sh').write_text(script)
    (out / 'double.fabro').write_text((HERE / 'double.fabro').read_text())
    (out / 'navigator.md').write_text((HERE.parent / 'prompts/navigator.md').read_text())
    graph = (HERE.parent / 'workflow.fabro').read_text().replace('@prompts/navigator.md', '@navigator.md')
    graph = graph.replace('../bdd-scenario-implementation/workflow.fabro', 'double.fabro')
    observe = ('set -eu; mkdir -p .fabro/tmp/bdd-plan/eval; '
               'cp acceptance-tests/features/member_profile.feature .fabro/tmp/bdd-plan/eval/final.feature; '
               'git diff "$(cat .fabro/tmp/bdd-plan/base)" > .fabro/tmp/bdd-plan/eval/final.patch')
    graph = graph.replace('navigator -> done [', 'navigator -> observe [')
    graph = graph.rsplit('}', 1)[0] + f'    observe [shape=parallelogram, script={json.dumps(observe)}]\n    observe -> done [condition="outcome=succeeded"]\n    observe -> stop\n}}\n'
    (out / 'parent.fabro').write_text(graph)
    config = (HERE.parent / 'workflow.toml').read_text().replace('graph = "workflow.fabro"', 'graph = "parent.fabro"')
    (out / 'workflow.toml').write_text(config.replace('plan = ""', 'plan = "docs/iterations/068-member-name-editing/plan.md"'))


def run(args):
    root, out = args.checkout.resolve(), args.out.resolve()
    prepare(root, out, args.runs)

    def cli(folder, name, *command, check=False):
        with (folder / name).open('w') as stdout, (folder / (name + '.stderr')).open('w') as stderr:
            result = subprocess.run(['fabro', '--no-upgrade-check', *command, *([] if command[0] == 'validate' else ['--server', args.server])],
                                    cwd=root, stdout=stdout, stderr=stderr)
        (folder / (name + '.exit')).write_text(str(result.returncode) + '\n')
        if check:
            result.check_returncode()
        return result.returncode

    try:
        cli(out, 'validation.log', 'validate', str(out / 'workflow.toml'), check=True)
        for i in range(1, args.runs + 1):
            trial = out / f'trial-{i:02}'
            trial.mkdir()
            cli(trial, 'launch.json', 'run', str(out / 'workflow.toml'), '--detach', '--json',
                '--label', f'plan-eval={out.name}', '--label', f'trial={i}', check=True)
            run_id = read_json(trial / 'launch.json')['run_id']  # Unknown acknowledgement stops, never retries.
            print(f'{i}/{args.runs}: {run_id}', flush=True)
            cli(trial, 'wait.json', 'wait', run_id, '--json', '--interval', '5000')
            if read_json(trial / 'wait.json').get('status') not in TERMINAL:
                raise RuntimeError(f'{run_id} is not terminal; inspect it, do not relaunch')
            events = cli(trial, 'events.jsonl', 'events', run_id, '--json')
            artifacts = cli(trial, 'artifacts.log', 'artifact', 'cp', run_id, str(trial / 'artifacts'), '--tree')
            final = list((trial / 'artifacts/observe').rglob('final.feature'))
            if len(final) == 1 and not events and not artifacts:
                with (trial / 'grade.json').open('w') as stdout, (trial / 'grade.stderr').open('w') as stderr:
                    subprocess.run(['node', str(HERE / 'grade.cjs'), str(final[0].parent), str(trial / 'events.jsonl')],
                                   cwd=HERE.parents[3], stdout=stdout, stderr=stderr)
            if events or artifacts or len(final) != 1 or read_json(trial / 'wait.json')['status'] != 'succeeded':
                break  # Infrastructure failures need inspection, not nineteen more identical failures.
    finally:
        summary = report(out)
    return 0 if summary['passed'] == args.runs else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checkout', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--runs', type=int)
    parser.add_argument('--report', action='store_true', help='Recompute from receipts; no launches')
    parser.add_argument('--server', default='https://fabro.home.wynne.family')
    args = parser.parse_args()
    if args.report:
        report(args.out.resolve())
    else:
        if args.checkout is None or args.runs is None or args.runs < 1:
            parser.error('--checkout and a positive --runs are required')
        raise SystemExit(run(args))
