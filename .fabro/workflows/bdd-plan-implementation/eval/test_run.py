import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import run as runner


class EvalInfrastructureTest(unittest.TestCase):
    def test_stock_workflow_reuse_and_shell_edits(self):
        graph = (runner.HERE.parent / 'workflow.fabro').read_text()
        self.assertIn('scenario [import="../bdd-scenario-implementation/workflow.fabro"]', graph)
        self.assertNotIn('stack.child_workflow', graph)
        prompts = [runner.HERE.parent / 'prompts/navigator.md',
                   runner.HERE.parents[1] / 'bdd-scenario-implementation/prompts/bdd-navigator.md',
                   runner.HERE.parents[1] / 'bdd-scenario-implementation/prompts/bdd-driver.md']
        for prompt in prompts:
            text = prompt.read_text()
            self.assertIn('shell commands', text)
            self.assertIn('apply_patch', text)
        scenario = (runner.HERE.parents[1] / 'bdd-scenario-implementation/workflow.fabro').read_text()
        self.assertIn('checked -> done\n', scenario)  # Native import boundary has no condition.

    def test_failed_export_does_not_erase_terminal_receipt(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            (out / 'manifest.json').write_text('{"requested": 20}')
            trial = out / 'trial-01'
            trial.mkdir()
            (trial / 'launch.json').write_text('{"run_id": "first"}')
            (trial / 'wait.json').write_text('{"status": "failed"}')
            (trial / 'artifacts.log.stderr').write_text('Export unavailable')
            summary = runner.report(out)
            self.assertEqual((summary['attempted'], summary['acknowledged'], summary['finished'], summary['not_run']), (1, 1, 1, 19))
            self.assertEqual(summary['trials'][0]['status'], 'failed')
            (trial / 'wait.json').write_text('interrupted output')
            self.assertEqual(runner.report(out)['finished'], 0)
            self.assertEqual(runner.report(out)['not_run'], 19)

    def test_grader_errors_stop_but_objective_failures_continue(self):
        self.assertTrue(runner.valid_grade(0, {'passed': True}))
        self.assertTrue(runner.valid_grade(1, {'passed': False, 'error': 'wrong first choice'}))
        for code, verdict in [(2, {}), (1, {}), (0, {}), (1, {'passed': True}), (0, {'passed': False})]:
            self.assertFalse(runner.valid_grade(code, verdict))

    def test_unknown_launch_acknowledgement_is_attempted_but_not_launched(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            (out / 'manifest.json').write_text('{"requested": 20}')
            trial = out / 'trial-01'
            trial.mkdir()
            (trial / 'launch.json').write_text('incomplete acknowledgement')
            (trial / 'wait.json').write_text('{"status":"succeeded"}')
            summary = runner.report(out)
            self.assertEqual((summary['attempted'], summary['acknowledged'], summary['finished'], summary['not_run']),
                             (1, 0, 0, 19))
            self.assertFalse(summary['trials'][0]['passed'])

    def test_prepared_result_is_bundled_but_absent_from_the_clone(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'source'
            root.mkdir()
            def git(*args):
                return subprocess.check_output(['git', *args], cwd=root, stderr=subprocess.DEVNULL)
            git('init', '-q')
            (root / '.gitignore').write_text('/results/\n')
            git('add', '.gitignore')
            git('-c', 'user.name=Eval', '-c', 'user.email=eval@example.invalid',
                '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Fixture')
            out = root / 'results/batch'
            runner.prepare(root, out, 20)
            self.assertIn('PersonRenamed', (out / 'double.sh').read_text())
            self.assertIn('script="@double.sh"', (out / 'double.fabro').read_text())
            self.assertIn('scenario [import="double.fabro"]', (out / 'parent.fabro').read_text())
            clone = Path(tmp) / 'clone'
            git('clone', '-q', str(root), str(clone))
            self.assertFalse((clone / 'results').exists())
            self.assertFalse((clone / '.fabro/workflows/bdd-plan-implementation/eval').exists())
            with self.assertRaises(FileExistsError):
                runner.prepare(root, out, 20)
            leaked = root / '.fabro/workflows/bdd-plan-implementation/eval/core.patch'
            leaked.parent.mkdir(parents=True)
            leaked.write_text('prepared result')
            git('add', str(leaked))
            git('-c', 'user.name=Eval', '-c', 'user.email=eval@example.invalid',
                '-c', 'commit.gpgsign=false', 'commit', '-qm', 'Leaky fixture')
            with self.assertRaisesRegex(ValueError, 'without eval code'):
                runner.prepare(root, root / 'results/another', 20)


if __name__ == '__main__':
    unittest.main()
