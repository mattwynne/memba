#!/usr/bin/env python3
"""Twenty fresh read-only decisions from one commit; no implementation workflow."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tomllib

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'scenario/eval'))
from navigator import wilson


def assess(reply, case):
    try:
        answer = json.loads(reply)
    except json.JSONDecodeError:
        return {'passed': False, 'error': 'Invalid JSON response'}
    passed = (isinstance(answer, dict) and answer.get('plan') == case['plan']
              and answer.get('feature') == case['feature']
              and answer.get('scenario') in case['acceptable_first']
              and isinstance(answer.get('reason'), str) and bool(answer['reason'].strip()))
    return {'passed': passed, 'answer': answer}


def report(out):
    manifest = json.loads((out / 'manifest.json').read_text())
    events = [json.loads(line) for line in (out / 'events.jsonl').read_text().splitlines()]
    completed = {e.get('node_id'): e['properties'].get('status') for e in events if e['event'] == 'stage.completed'}
    trials = []
    for i in range(1, manifest['requested'] + 1):
        replies = list((out / 'dump/stages').glob(f'*-trial_{i}@1/response.md'))
        result = assess(replies[0].read_text(), manifest['case']) if len(replies) == 1 else {
            'passed': False, 'error': 'No unique saved response'}
        result['passed'] = result['passed'] and completed.get(f'trial_{i}') == 'succeeded'
        trials.append({'trial': i, 'observed': len(replies) == 1, **result})
    observed = sum(t['observed'] for t in trials)
    passed = sum(t['passed'] for t in trials)
    summary = {**manifest, 'observed': observed, 'passed': passed,
               'no_response': manifest['requested'] - observed,
               'wilson_95': wilson(passed, observed), 'trials': trials}
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(f'{passed}/{observed} observed decisions passed; {summary["no_response"]} missing. {out}', flush=True)
    return summary


def prepare(out, runs):
    if runs < 1:
        raise ValueError('Choose a positive trial count before launch')
    out.mkdir(parents=True)  # Never overwrite results or replace an uncertain launch.
    case = json.loads((HERE / 'case.json').read_text())
    prompt = (HERE / 'prompt.md').read_text()
    (out / 'prompt.md').write_text(prompt)
    nodes = [f'trial_{i}' for i in range(1, runs + 1)]
    graph = 'digraph CommitSelection {\n graph [default_max_retries=0]\n start [shape=Mdiamond]\n done [shape=Msquare]\n'
    graph += '\n'.join(f' {node} [shape=box, backend="api", fidelity="full", thread_id="{node}", prompt="@prompt.md"]' for node in nodes)
    graph += '\n' + '\n'.join(f' {a} -> {b}' for a, b in zip(['start'] + nodes, nodes + ['done'])) + '\n}\n'
    (out / 'workflow.fabro').write_text(graph)
    source_config = (HERE.parents[1] / 'workflow.toml').read_text()
    source_graph = tomllib.loads(source_config)['workflow']['graph']
    config = source_config.replace(f'graph = "{source_graph}"', 'graph = "workflow.fabro"', 1).replace(
        'commit = "HEAD"', f'commit = "{case["commit"]}"')
    (out / 'workflow.toml').write_text(config)
    manifest = {'requested': runs, 'case': case,
                'prompt_sha256': hashlib.sha256(prompt.encode()).hexdigest(),
                'source': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=HERE, text=True).strip()}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return case


def run(args):
    root, out = args.checkout.resolve(), args.out.resolve()
    if subprocess.check_output(['git', 'status', '--porcelain'], cwd=root):
        raise ValueError('Fixture checkout must be clean')
    case = json.loads((HERE / 'case.json').read_text())
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
    if head != case['commit']:
        raise ValueError('Use the frozen case commit')
    out.relative_to(root)
    prepare(out, args.runs)

    def cli(name, *command, check=True):
        with (out / name).open('w') as stdout, (out / (name + '.stderr')).open('w') as stderr:
            result = subprocess.run(['fabro', '--no-upgrade-check', *command,
                                     *([] if command[0] == 'validate' else ['--server', args.server])],
                                    cwd=root, stdout=stdout, stderr=stderr)
        (out / (name + '.exit')).write_text(str(result.returncode) + '\n')
        if check:
            result.check_returncode()
        return (out / name).read_text()

    cli('validation.log', 'validate', str(out / 'workflow.toml'))
    launch = json.loads(cli('launch.json', 'run', str(out / 'workflow.toml'), "--environment", "memba-dev", '--detach', '--json',
                            '--label', f'commit-selection={out.name}'))
    run_id = launch['run_id']  # Unknown acknowledgement stops; never launch again.
    print(f'{run_id}: {args.runs} fresh decisions; only task input is commit {head}', flush=True)
    terminal = json.loads(cli('wait.json', 'wait', run_id, '--json', '--interval', '5000', check=False))
    if terminal.get('status') not in {'succeeded', 'failed', 'cancelled', 'canceled', 'interrupted'}:
        raise RuntimeError('Run not terminal; inspect it, do not relaunch')
    cli('events.jsonl', 'events', run_id, '--json')
    cli('dump.log', 'dump', run_id, '--output', str(out / 'dump'))
    summary = report(out)
    return 0 if summary['passed'] == args.runs else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--checkout', type=Path)
    parser.add_argument('--runs', type=int)
    parser.add_argument('--report', action='store_true')
    parser.add_argument('--server', default='https://fabro.home.wynne.family')
    args = parser.parse_args()
    if args.report:
        report(args.out.resolve())
    else:
        if args.checkout is None or args.runs is None:
            parser.error('--checkout and --runs are required')
        raise SystemExit(run(args))
