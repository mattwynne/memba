#!/usr/bin/env python3
"""Fail-closed tests for a single scenario's call-your-shot delivery loop."""

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

MODULE = Path(__file__).with_name("wip_scenario.py")
spec = importlib.util.spec_from_file_location("wip_scenario", MODULE)
wip = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wip)


class ScenarioLoopTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.plan = self.root / "docs/iterations/067/plan.md"
        self.plan.parent.mkdir(parents=True)
        self.plan.write_text("## Allowed acceptance feature changes\n- `acceptance-tests/features/member.feature`: remove @todo and mark @wip.\n")
        self.feature = self.root / "acceptance-tests/features/member.feature"
        self.feature.parent.mkdir(parents=True)
        self.feature.write_text("Feature: Members\n  @iteration-067 @todo\n  Scenario: Bob sees Alice join\n    Given Bob is viewing his list\n")
        self.delivery = self.plan.parent / ".delivery"
        self.delivery.mkdir()
        self.packet = {"packet_id": "packet-1", "task_id": "task-2", "todo_line": "- [ ] 2 Test",
                       "attempt": "implementation", "scenario_focus": {
                           "feature_path": "acceptance-tests/features/member.feature",
                           "name": "Bob sees Alice join", "predicted_failure": "Undefined step: Bob is viewing his list",
                           "predicted_after": "Expected Alice to appear"}}
        (self.delivery / "current-worker-packet.json").write_text(json.dumps(self.packet))
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.name", "Test"], check=True)
        subprocess.run(["git", "-C", str(self.root), "config", "user.email", "test@example.invalid"], check=True)
        self.checkpoint("initial")

    def checkpoint(self, subject):
        subprocess.run(["git", "-C", str(self.root), "add", "-A"], check=True)
        subprocess.run(["git", "-C", str(self.root), "commit", "-qm", subject], check=True)

    def run_before(self, text="Undefined step: Bob is viewing his list", code=1):
        calls = []
        def runner(command):
            calls.append(command)
            return subprocess.CompletedProcess(command, code, text, "")
        result = wip.before(self.root, self.plan, runner=runner)
        self.checkpoint("fabro(run): call_shot_and_run_scenario (succeeded)")
        return result, calls

    def test_prediction_is_persisted_before_invoking_runner_and_selects_one_scenario(self):
        def runner(command):
            record = json.loads((self.delivery / "wip-before.json").read_text())
            self.assertEqual(record["predicted_failure"], "Undefined step: Bob is viewing his list")
            self.assertEqual(record["predicted_after"], "Expected Alice to appear")
            self.assertIn("@wip", self.feature.read_text())
            self.assertNotIn("@todo", self.feature.read_text())
            self.assertEqual(command[-2:], ["--only", "scenario_name:Bob sees Alice join"])
            return subprocess.CompletedProcess(command, 1, "Undefined step: Bob is viewing his list", "")
        self.assertEqual(wip.before(self.root, self.plan, runner=runner), "implement")
        record = json.loads((self.delivery / "wip-before.json").read_text())
        self.assertEqual(record["status"], "predicted_red")
        self.assertEqual(record["packet_id"], "packet-1")

    def test_untagged_rule_scenario_gets_scenario_level_indentation(self):
        self.feature.write_text("Feature: Members\n  Rule: Open list stays current\n    Scenario: Bob sees Alice join\n      Given Bob is viewing his list\n")
        self.run_before()
        self.assertIn("    @wip\n    Scenario: Bob sees Alice join", self.feature.read_text())

    def test_surprising_failure_does_not_dispatch_worker(self):
        result, _ = self.run_before("No such test selected")
        self.assertEqual(result, "replan")
        self.assertEqual(json.loads((self.delivery / "wip-before.json").read_text())["status"], "surprise")

    def test_unexpected_green_removes_wip_and_replans(self):
        result, _ = self.run_before("1 test, 0 failures", 0)
        self.assertEqual(result, "replan")
        self.assertNotIn("@wip", self.feature.read_text())

    def test_after_worker_red_is_recorded_for_independent_review_not_called_green(self):
        self.run_before()
        result = wip.after(self.root, self.plan, runner=lambda command: subprocess.CompletedProcess(command, 1, "Expected Alice to appear", ""))
        self.assertEqual(result, "review")
        self.assertIn("@wip", self.feature.read_text())
        after = json.loads((self.delivery / "wip-after.json").read_text())
        self.assertEqual(after["status"], "red")
        self.assertTrue(after["prediction_matched"])

    def test_after_worker_surprise_is_recorded_without_claiming_progress(self):
        self.run_before()
        self.assertEqual(wip.after(self.root, self.plan, runner=lambda command: subprocess.CompletedProcess(command, 1, "Unexpected different error", "")), "review")
        self.assertFalse(json.loads((self.delivery / "wip-after.json").read_text())["prediction_matched"])

    def test_after_worker_green_removes_wip(self):
        self.run_before()
        result = wip.after(self.root, self.plan, runner=lambda command: subprocess.CompletedProcess(command, 0, "1 test, 0 failures", ""))
        self.assertEqual(result, "review")
        self.assertNotIn("@wip", self.feature.read_text())
        self.assertEqual(json.loads((self.delivery / "wip-after.json").read_text())["status"], "green")

    def test_worker_cannot_edit_trusted_prediction(self):
        self.run_before()
        path = self.delivery / "wip-before.json"
        record = json.loads(path.read_text())
        record["predicted_failure"] = "A different guess after the run"
        path.write_text(json.dumps(record))
        with self.assertRaisesRegex(wip.ScenarioError, "edited outside"):
            wip.after(self.root, self.plan, runner=lambda command: subprocess.CompletedProcess(command, 1, "new failure", ""))

    def test_worker_cannot_weaken_or_change_active_scenario(self):
        self.run_before()
        self.feature.write_text(self.feature.read_text().replace("Bob is viewing his list", "Bob might be viewing his list"))
        with self.assertRaisesRegex(wip.ScenarioError, "changed the active feature"):
            wip.after(self.root, self.plan, runner=lambda command: subprocess.CompletedProcess(command, 0, "1 test, 0 failures", ""))

    def test_only_one_selected_exunit_test_is_valid_evidence(self):
        wip.ensure_one_selected("179 tests, 1 failure, 178 excluded", "Bob sees Alice join")
        with self.assertRaisesRegex(wip.ScenarioError, "exactly one"):
            wip.ensure_one_selected("179 tests, 0 failures, 179 excluded", "Bob sees Alice join")
        with self.assertRaisesRegex(wip.ScenarioError, "exactly one"):
            wip.ensure_one_selected("179 tests, 2 failures, 177 excluded", "Bob sees Alice join")

    def test_cannot_focus_on_two_scenarios_or_reactivate_future_tag(self):
        other = self.root / "acceptance-tests/features/other.feature"
        other.write_text("Feature: Another\n  @wip\n  Scenario: Another\n    Given nothing\n")
        with self.assertRaisesRegex(wip.ScenarioError, "one @wip"):
            self.run_before()
        self.assertNotIn("@wip", self.feature.read_text())

    def test_refuses_stale_or_unselected_scenario(self):
        self.packet["scenario_focus"]["name"] = "Not found"
        (self.delivery / "current-worker-packet.json").write_text(json.dumps(self.packet))
        with self.assertRaisesRegex(wip.ScenarioError, "exactly once"):
            self.run_before()

    def test_final_gate_rejects_even_green_wip(self):
        self.feature.write_text(self.feature.read_text().replace("@todo", "@wip"))
        with self.assertRaisesRegex(wip.ScenarioError, "@wip"):
            wip.assert_no_wip(self.root)


if __name__ == "__main__":
    unittest.main()
