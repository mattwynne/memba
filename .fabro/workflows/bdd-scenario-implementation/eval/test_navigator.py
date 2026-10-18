import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest

import navigator


class NavigatorEvalTest(unittest.TestCase):
    def test_workflow_finishes_after_checks_without_refactoring_or_review(self):
        graph = (navigator.WORKFLOW / "workflow.fabro").read_text()
        self.assertIn('digraph BddScenarioImplementation', graph)
        self.assertIn('navigator -> check [condition="outcome=succeeded && preferred_label=check"]', graph)
        self.assertIn('check -> done [condition="outcome=succeeded"]', graph)
        self.assertIn('check -> navigator [condition="outcome=failed"]', graph)
        self.assertNotIn('refactor', graph)
        self.assertNotIn('review', graph)
        self.assertEqual({p.name for p in (navigator.WORKFLOW / 'prompts').glob('*.md')},
                         {'bdd-navigator.md', 'bdd-driver.md'})

    def test_wilson_interval(self):
        self.assertIsNone(navigator.wilson(0, 0))
        self.assertAlmostEqual(navigator.wilson(0, 20)[1], 0.161125158, places=8)
        self.assertAlmostEqual(navigator.wilson(20, 20)[0], 0.838874842, places=8)
        self.assertAlmostEqual(navigator.wilson(5, 10)[0], 0.236593091, places=8)
        self.assertAlmostEqual(navigator.wilson(5, 10)[1], 0.763406909, places=8)

    def test_preparation_snapshots_prompt_and_separates_calls(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "batch"
            prompt = navigator.WORKFLOW / "prompts/bdd-navigator.md"
            navigator.prepare(out, 3, prompt)
            self.assertEqual((out / "navigator-prompt.md").read_text(), prompt.read_text())
            graph = (out / "navigator.fabro").read_text()
            self.assertIn('shape=tab', graph)
            self.assertIn('fidelity="full"', graph)
            self.assertIn('default_max_retries=0', graph)
            self.assertIn('trial_1 -> trial_2', graph)
            self.assertIn('trial_3 -> done', graph)
            for i in range(1, 4):
                self.assertIn(f'  trial_{i} [label="Navigator"]', graph)
            self.assertNotIn('shape=box', graph)
            with self.assertRaises(FileExistsError):
                navigator.prepare(out, 3, prompt)
            with self.assertRaises(ValueError):
                navigator.prepare(Path(directory) / "invalid", 0, prompt)

    def test_grading_counts_wrong_missing_and_failed_responses(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / "manifest.json").write_text(json.dumps({"runs": 6, "expected_label": "check"}))
            stages = out / "dump/stages"
            stages.mkdir(parents=True)
            events = []
            for i, label, status in [(1, "check", "succeeded"), (2, "stop", "succeeded"),
                                     (3, "refactor", "succeeded"), (4, None, "succeeded"),
                                     (5, "check", "failed")]:
                events.append({"event": "stage.completed", "node_id": f"trial_{i}",
                               "properties": {"preferred_label": label, "status": status}})
                stage = stages / f"00{i}-trial_{i}@1"
                stage.mkdir()
                (stage / "response.md").write_text("Ready for checks! (Prose is not the grade.)")
            (out / "dump/events.jsonl").write_text("\n".join(json.dumps(e) for e in events))
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(navigator.report(out), 1)
            report = json.loads((out / "summary.json").read_text())
            self.assertEqual(report["successes"], 1)
            self.assertEqual(report["observed"], 5)
            self.assertEqual(report["no_response"], 1)
            self.assertEqual(report["trials"][-1]["result"], "no_response")
            # The same evidence with a one-trial declaration is a complete pass.
            (out / "manifest.json").write_text('{"runs": 1, "expected_label": "check"}')
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(navigator.report(out), 0)

    def test_all_missing_has_no_success_estimate(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / "manifest.json").write_text('{"runs": 2, "expected_label": "check"}')
            (out / "dump").mkdir()
            (out / "dump/events.jsonl").write_text("")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(navigator.report(out), 1)
            self.assertIsNone(json.loads((out / "summary.json").read_text())["wilson_95"])


if __name__ == "__main__":
    unittest.main()
