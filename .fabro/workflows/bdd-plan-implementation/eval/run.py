#!/usr/bin/env python3
"""Run a fixed batch of independent plan-navigator trials with the native child double."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'bdd-scenario-implementation/eval'))
from navigator import wilson


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checkout', type=Path, required=True, help='Clean historical fixture checkout')
    parser.add_argument('--out', type=Path, required=True, help='New results directory inside that checkout')
    parser.add_argument('--runs', type=int, required=True)
    parser.add_argument('--server', default='https://fabro.home.wynne.family')
    args = parser.parse_args()
    if args.runs < 1:
        parser.error('--runs must be positive')
    root, out = args.checkout.resolve(), args.out.resolve()
    out.relative_to(root)
    source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=root):
        raise RuntimeError('The fixture checkout must be clean')
    out.mkdir(parents=True)  # Never reuse a batch or overwrite an uncertain launch.
    workflow = root / '.fabro/workflows/bdd-plan-implementation'
    graph = (workflow / 'workflow.fabro').read_text()
    graph = graph.replace('@prompts/navigator.md', '@' + os.path.relpath(workflow / 'prompts/navigator.md', out))
    graph = graph.replace('../bdd-scenario-implementation/workflow.fabro', os.path.relpath(workflow / 'eval/double.fabro', out))
    # Observe after the real parent's done decision; this command cannot guide it.
    observe = ('mkdir -p .fabro/tmp/bdd-plan/eval; '
               'cp acceptance-tests/features/member_profile.feature .fabro/tmp/bdd-plan/eval/final.feature; '
               'git diff "$(cat .fabro/tmp/bdd-plan/base)" -- web/lib > .fabro/tmp/bdd-plan/eval/code.patch; '
               'git diff --name-only "$(cat .fabro/tmp/bdd-plan/base)" > .fabro/tmp/bdd-plan/eval/changed-paths')
    graph = graph.replace('navigator -> done [', 'navigator -> observe [')
    graph = graph.rsplit('}', 1)[0] + (
        f'    observe [shape=parallelogram, script={json.dumps("set -eu; " + observe)}]\n'
        '    observe -> done [condition="outcome=succeeded"]\n    observe -> stop\n}\n')
    (out / 'parent.fabro').write_text(graph)
    config = (workflow / 'workflow.toml').read_text().replace('graph = "workflow.fabro"', 'graph = "parent.fabro"')
    config = config.replace('plan = ""', 'plan = "docs/iterations/068-member-name-editing/plan.md"')
    (out / 'workflow.toml').write_text(config)
    manifest = {'requested': args.runs, 'source': source, 'case': '068-three-domain-scenarios', 'trials': []}

    def save():
        trials = manifest['trials']
        passed = sum(t.get('passed', False) for t in trials)
        summary = {**manifest, 'finished': len(trials), 'passed': passed,
                   'not_run': args.runs - len(trials), 'wilson_95': wilson(passed, len(trials))}
        (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')

    save()
    with (out / 'validation.log').open('w') as log:
        subprocess.run(['fabro', '--no-upgrade-check', 'validate', str(out / 'workflow.toml')], cwd=root,
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    for i in range(1, args.runs + 1):
        trial = out / f'trial-{i:02}'
        trial.mkdir()

        def cli(name, *command, check=True):
            with (trial / f'{name}.json').open('w') as stdout, (trial / f'{name}.stderr').open('w') as stderr:
                result = subprocess.run(['fabro', '--no-upgrade-check', *command, '--server', args.server],
                                        cwd=root, stdout=stdout, stderr=stderr)
            (trial / f'{name}.exit').write_text(str(result.returncode) + '\n')
            if check:
                result.check_returncode()
            return (trial / f'{name}.json').read_text()

        # One launch per requested trial. An unknown acknowledgement stops the batch.
        launch = json.loads(cli('launch', 'run', str(out / 'workflow.toml'), '--detach', '--json',
                                '--label', f'plan-eval={out.name}', '--label', f'trial={i}'))
        run_id = launch['run_id']
        print(f'{i}/{args.runs}: {run_id}', flush=True)
        terminal = json.loads(cli('wait', 'wait', run_id, '--json', '--interval', '5000', check=False))
        if terminal.get('status') not in ('succeeded', 'failed', 'cancelled', 'canceled', 'interrupted'):
            raise RuntimeError(f'{run_id} is not terminal; inspect it, do not relaunch')
        cli('dump', 'dump', run_id, '--output', str(trial / 'dump'))
        final = list((trial / 'dump').glob('artifacts/*-observe@1/**/final.feature'))
        result = {'passed': False, 'error': 'No unique final observation'}
        if len(final) == 1:
            graded = subprocess.run(['node', str(HERE / 'grade.cjs'), str(final[0].parent)], capture_output=True, text=True)
            (trial / 'grade.stdout').write_text(graded.stdout)
            (trial / 'grade.stderr').write_text(graded.stderr)
            result = json.loads(graded.stdout)
        result.update(trial=i, run_id=run_id, status=terminal['status'])
        result['passed'] = result['passed'] and terminal['status'] == 'succeeded'
        manifest['trials'].append(result)
        save()
        print(json.dumps(result), flush=True)
    return 0 if all(t['passed'] for t in manifest['trials']) else 1


if __name__ == '__main__':
    raise SystemExit(main())
