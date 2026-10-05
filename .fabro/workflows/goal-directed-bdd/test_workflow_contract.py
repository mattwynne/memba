#!/usr/bin/env python3
"""Small static guard for Fabro's before-visit max_visits behavior."""

from pathlib import Path
import re
import unittest


class WorkflowContractTest(unittest.TestCase):
    def test_prediction_runs_once_before_model_can_implement(self):
        graph = Path(__file__).with_name("workflow.fabro").read_text()
        shot = re.search(r"call_shot\s*\[(.*?)\n    \]", graph, re.S)
        self.assertIsNotNone(shot)
        # Fabro 0.316 stops before reaching max_visits. A value of one
        # prevents the first call; two allows exactly one prediction call.
        self.assertRegex(shot.group(1), r"max_visits=2\b")
        self.assertIn("resume_red -> implement_scenario [condition=\"outcome=succeeded && preferred_label=resume\"]", graph)
        self.assertIn("call_shot -> observe_predicted_red", graph)
        self.assertIn("observe_predicted_red -> implement_scenario [condition=\"outcome=succeeded && preferred_label=implement\"]", graph)
        self.assertIn("observe_predicted_red -> diagnose_surprise [condition=\"outcome=succeeded && preferred_label=repredict\"]", graph)
        self.assertIn("resume_red -> diagnose_surprise [condition=\"outcome=succeeded && preferred_label=repredict\"]", graph)
        self.assertIn("diagnose_surprise -> observe_repredicted_red", graph)
        self.assertIn("observe_repredicted_red -> implement_scenario [condition=\"outcome=succeeded && preferred_label=implement\"]", graph)
        self.assertNotIn("publish_to_main", graph)


if __name__ == "__main__":
    unittest.main()
