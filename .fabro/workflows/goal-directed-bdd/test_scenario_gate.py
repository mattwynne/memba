#!/usr/bin/env python3
"""Isolated, no-database contract tests for the non-publishing BDD pilot gate."""

import importlib.util
import io
import json
import subprocess
from contextlib import redirect_stdout
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

    def test_new_rehearsal_or_saved_red_checkpoint_routes_without_retesting_red(self):
        with patch.object(gate, "trusted_before"):
            gate.resume(self.root, self.plan)
            self.predicted_red()
            gate.resume(self.root, self.plan)
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "predicted_red")

    def test_resume_refuses_stale_red(self):
        self.predicted_red()
        self.feature.write_text(self.feature.read_text().replace("@wip", "@todo"))
        with patch.object(gate, "trusted_before"):
            with self.assertRaisesRegex(gate.GateError, "stale"):
                gate.resume(self.root, self.plan)

    def test_intended_red_then_green_and_review_accept(self):
        self.predicted_red()
        with patch.object(gate, "trusted_before"):
            with patch.object(gate, "run", return_value=(0, "1 test, 0 failures")):
                gate.after(self.root, self.plan)
            gate.verdict(self.root, self.plan, {"decision": "accept", "reason": "Observed and reviewed"})
        self.assertNotIn("@wip", self.feature.read_text())
        gate.final(self.root, self.plan)

    def test_wrong_product_red_is_preserved_and_repredicted_before_worker(self):
        output = "function Memba.Messaging.send_group_access_request/2 is undefined\n1 test, 1 failure"
        with patch.object(gate, "run", return_value=(2, output)):
            routing = io.StringIO()
            with redirect_stdout(routing):
                gate.before(self.root, self.plan, self.shot)
            self.assertEqual(json.loads(routing.getvalue()), {"preferred_next_label": "repredict"})
            first = gate.load(gate.artifact(self.plan, "before.json"))
            self.assertEqual(first["status"], "surprise")
            with patch.object(gate, "trusted_before"), patch.object(gate, "trusted_unchanged_candidate"):
                routing = io.StringIO()
                with redirect_stdout(routing):
                    gate.resume(self.root, self.plan)
                self.assertEqual(json.loads(routing.getvalue()), {"preferred_next_label": "repredict"})
                revised = {"decision": "repredict", "reason": "The missing API has a different name",
                           "predicted_failure": "function Memba.Messaging.send_group_access_request/2 is undefined"}
                routing = io.StringIO()
                with redirect_stdout(routing):
                    gate.before(self.root, self.plan, revised)
            self.assertEqual(json.loads(routing.getvalue()), {"preferred_next_label": "implement"})
        self.assertEqual(gate.load(gate.artifact(self.plan, "shot-01.json")), first)
        second = gate.load(gate.artifact(self.plan, "before.json"))
        self.assertEqual(second["status"], "predicted_red")
        self.assertEqual(second["attempt"], 2)
        self.assertEqual(second["feature_sha256"], first["feature_sha256"])
        self.assertNotEqual(second["predicted_failure"], first["predicted_failure"])

    def test_second_wrong_prediction_stops_without_third_attempt(self):
        output = "another missing behaviour at the product boundary\n1 test, 1 failure"
        with patch.object(gate, "run", return_value=(2, output)):
            gate.before(self.root, self.plan, self.shot)
            with patch.object(gate, "trusted_before"), patch.object(gate, "trusted_unchanged_candidate"):
                routing = io.StringIO()
                with redirect_stdout(routing):
                    gate.before(self.root, self.plan, {"decision": "repredict", "reason": "Different missing API",
                                                     "predicted_failure": "another missing behaviour that does not match"})
                self.assertEqual(json.loads(routing.getvalue()), {"preferred_next_label": "stop"})
                with self.assertRaisesRegex(gate.GateError, "Only one unchanged surprising red"):
                    gate.before(self.root, self.plan, self.shot)
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "surprise")
        self.assertEqual(gate.load(gate.artifact(self.plan, "shot-01.json"))["attempt"], 1)

    def test_diagnosis_may_block_without_rerunning(self):
        with patch.object(gate, "run", return_value=(2, "unrelated error\n1 test, 1 failure")):
            gate.before(self.root, self.plan, self.shot)
        with patch.object(gate, "trusted_before"), patch.object(gate, "trusted_unchanged_candidate"), patch.object(gate, "run") as runner:
            routing = io.StringIO()
            with redirect_stdout(routing):
                gate.before(self.root, self.plan, {"decision": "blocked", "reason": "Not a product failure"})
            runner.assert_not_called()
            self.assertEqual(json.loads(routing.getvalue()), {"preferred_next_label": "stop"})
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "surprise")
        with patch.object(gate, "trusted_before"):
            with self.assertRaisesRegex(gate.GateError, "blocked diagnosis"):
                gate.resume(self.root, self.plan)

    def test_tampered_first_observation_cannot_be_accepted(self):
        output = "function Memba.Messaging.send_group_access_request/2 is undefined\n1 test, 1 failure"
        with patch.object(gate, "run", return_value=(2, output)):
            gate.before(self.root, self.plan, self.shot)
            with patch.object(gate, "trusted_before"), patch.object(gate, "trusted_unchanged_candidate"):
                gate.before(self.root, self.plan, {"decision": "repredict", "reason": "Corrected missing API",
                                                  "predicted_failure": "function Memba.Messaging.send_group_access_request/2 is undefined"})
        prior = gate.artifact(self.plan, "shot-01.json")
        prior.write_text(prior.read_text().replace("surprise", "predicted_red"))
        with patch.object(gate, "trusted_before"), patch.object(gate, "run") as runner:
            with self.assertRaisesRegex(gate.GateError, "Original surprise was modified"):
                gate.after(self.root, self.plan)
            runner.assert_not_called()

    def test_already_green_does_not_turn_into_reprediction(self):
        with patch.object(gate, "run", return_value=(0, "1 test, 0 failures")):
            with self.assertRaisesRegex(gate.GateError, "already_green"):
                gate.before(self.root, self.plan, self.shot)
        self.assertEqual(gate.load(gate.artifact(self.plan, "before.json"))["status"], "already_green")

    def test_cannot_repredict_after_feature_changes(self):
        with patch.object(gate, "run", return_value=(2, "unexpected red\n1 test, 1 failure")):
            gate.before(self.root, self.plan, self.shot)
        self.feature.write_text(self.feature.read_text().replace("Eve requests access", "Eve directly joins"))
        with patch.object(gate, "trusted_before"), patch.object(gate, "trusted_unchanged_candidate"):
            with self.assertRaisesRegex(gate.GateError, "unchanged surprising red"):
                gate.before(self.root, self.plan, {"decision": "repredict", "reason": "Mismatch",
                                                    "predicted_failure": "unexpected red but more specific"})

    def test_diagnostic_model_may_not_commit_candidate_edits(self):
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        before = gate.artifact(self.plan, "before.json")
        gate.save(before, {"status": "surprise"})
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(["git", "-c", "user.name=Test", "-c", "user.email=test@example.com",
                        "commit", "-qm", "fabro: observe_predicted_red (succeeded)"], cwd=self.root, check=True)
        gate.trusted_unchanged_candidate(self.root, self.plan)
        (self.root / "product_code.ex").write_text("bad change\n")
        subprocess.run(["git", "add", "."], cwd=self.root, check=True)
        subprocess.run(["git", "-c", "user.name=Test", "-c", "user.email=test@example.com",
                        "commit", "-qm", "diagnose_surprise changed product code"], cwd=self.root, check=True)
        with self.assertRaisesRegex(gate.GateError, "Diagnosis edited"):
            gate.trusted_unchanged_candidate(self.root, self.plan)

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
