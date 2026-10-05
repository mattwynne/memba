#!/usr/bin/env python3
"""Isolated, no-database contract tests for the non-publishing BDD pilot gate."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("scenario_gate", Path(__file__).with_name("scenario_gate.py"))
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class ScenarioGateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.plan = self.root / "docs/iterations/066-request-group-access/plan.md"
        self.plan.parent.mkdir(parents=True)
        self.plan.write_text("## Allowed acceptance feature changes\n\n- `" + gate.FEATURE + "`: approved.\n")
        self.feature = self.root / gate.FEATURE
        self.feature.parent.mkdir(parents=True)
        self.feature.write_text("@iteration-066\nFeature: Ask\n\n  Rule: Request\n    @todo\n    Scenario: Eve asks to join Board\n      When Eve requests access to Board\n")
        self.shot = {"predicted_failure": "function Memba.Messaging.request_group_access/2 is undefined or private"}

    def predicted_red(self):
        with patch.object(gate, "run", return_value=(2, "function Memba.Messaging.request_group_access/2 is undefined or private\n1 test, 1 failure")):
            gate.before(self.root, self.plan, self.shot)
        self.assertIn("@wip", self.feature.read_text())
        self.assertNotIn("@todo", self.feature.read_text())
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "predicted_red")

    def test_intended_red_then_green_and_review_accept(self):
        self.predicted_red()
        with patch.object(gate, "trusted_before"):
            with patch.object(gate, "run", return_value=(0, "1 test, 0 failures")):
                gate.after(self.root, self.plan)
            gate.verdict(self.root, self.plan, {"decision": "accept", "reason": "Observed and reviewed"})
        self.assertNotIn("@wip", self.feature.read_text())
        gate.final(self.root, self.plan)

    def test_wrong_red_does_not_start_worker(self):
        with patch.object(gate, "run", return_value=(2, "unexpected database error\n1 test, 1 failure")):
            with self.assertRaisesRegex(gate.GateError, "did not fail for the predicted behaviour"):
                gate.before(self.root, self.plan, self.shot)
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "surprise")

    def test_undefined_step_is_not_product_red(self):
        with patch.object(gate, "run", return_value=(2, "No matching step definition\n1 test, 1 failure")):
            with self.assertRaisesRegex(gate.GateError, "harness_failure"):
                gate.before(self.root, self.plan, {"predicted_failure": "No matching step definition: Eve requests access to Board"})

    def test_zero_selected_is_not_product_red(self):
        with patch.object(gate, "run", return_value=(0, "0 tests, 0 failures")):
            with self.assertRaisesRegex(gate.GateError, "exactly one"):
                gate.before(self.root, self.plan, self.shot)

    def test_feature_level_todo_is_not_silently_activated(self):
        self.feature.write_text(self.feature.read_text().replace("@iteration-066", "@iteration-066 @todo"))
        with self.assertRaisesRegex(gate.GateError, "Feature/rule @todo"):
            gate.before(self.root, self.plan, self.shot)

    def test_worker_may_not_change_scenario_before_review(self):
        self.predicted_red()
        self.feature.write_text(self.feature.read_text().replace("Eve asks to join Board", "Eve asks to join Everyone"))
        with patch.object(gate, "trusted_before"):
            with self.assertRaises(gate.GateError):
                gate.after(self.root, self.plan)

    def test_review_cannot_accept_red_or_forget_to_remove_wip(self):
        self.predicted_red()
        with patch.object(gate, "trusted_before"):
            with patch.object(gate, "run", return_value=(2, "Still red\n1 test, 1 failure")):
                gate.after(self.root, self.plan)
            with self.assertRaisesRegex(gate.GateError, "missing/stale"):
                gate.verdict(self.root, self.plan, {"decision": "accept", "reason": "No"})
        with self.assertRaisesRegex(gate.GateError, "@wip remains"):
            gate.final(self.root, self.plan)

    def test_unsafe_uncheckpointed_red_is_rejected(self):
        self.predicted_red()
        with self.assertRaises(Exception):
            gate.after(self.root, self.plan)


if __name__ == "__main__":
    unittest.main()
