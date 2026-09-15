#!/usr/bin/env python3
"""Regression tests for delivery planner durable artifact contracts."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(__file__).with_name("delivery_planner_state.py")
TASK = "- [ ] 002 Deliver the selected slice."
NEXT_TASK = "- [ ] 003 Deliver the later slice."
ACCEPTED = "- [x] 001 Accepted foundation."
TODO_TEXT = f"# TODO\n\n{ACCEPTED}\n{TASK}\n{NEXT_TASK}\n"
PLAN_PATH = "docs/iterations/009-test/plan.md"
TODO_PATH = "docs/iterations/009-test/todo.md"


class DeliveryPlannerStateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.iteration = self.root / "docs/iterations/009-test"
        self.iteration.mkdir(parents=True)
        self.plan = self.iteration / "plan.md"
        self.todo = self.iteration / "todo.md"
        self.delivery = self.iteration / ".delivery"
        self.plan.write_text("# Plan\n\n## Implementation Plan\n\n1. Deliver the selected slice.\n2. Deliver the later slice.\n")
        self.todo.write_text(TODO_TEXT)
        (self.root / "app.txt").write_text("accepted code\n")
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        self.checkpoint("initial")

    def git(self, *args: str) -> str:
        return subprocess.check_output(["git", "-C", str(self.root), *args], text=True).strip()

    def checkpoint(self, message: str) -> None:
        self.git("add", ".")
        self.git("commit", "-qm", message)

    def invoke(self, command: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(HELPER), command, str(self.plan)],
            cwd=self.root,
            text=True,
            capture_output=True,
        )

    def start_planner(self) -> str:
        result = self.invoke("before-planner")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.checkpoint("fabro(run): before_delivery_planner (succeeded)")
        return self.git("rev-parse", "HEAD")

    def binding_head(self) -> str:
        return self.git("rev-parse", "HEAD")

    def planner_result(self, decision: str = "ready", source: str | None = None, **extra: object) -> dict[str, object]:
        result: dict[str, object] = {
            "schema_version": 1,
            "plan_path": PLAN_PATH,
            "todo_path": TODO_PATH,
            "source_baseline": source or self.binding_head(),
            "decision": decision,
        }
        result.update(extra)
        return result

    def state(self, *, accepted: list[str] | None = None, pending: list[dict[str, object]] | None = None, source: str | None = None, candidate_origins: list[dict[str, object]] | None = None) -> dict[str, object]:
        accepted = [ACCEPTED] if accepted is None else accepted
        pending = [
            {"task_id": "task-002", "todo_line": TASK, "origin": "plan", "status": "prepared", "coverage": ["unit"], "replaces": [], "candidate_origins": []},
            {"task_id": "task-003", "todo_line": NEXT_TASK, "origin": "plan", "status": "pending", "coverage": ["unit"], "replaces": [], "candidate_origins": []},
        ] if pending is None else pending
        coverage = [
            {"scope": "Accepted foundation", "pending_task_ids": [], "accepted_task_lines": accepted},
            {"scope": "Pending implementation", "pending_task_ids": [str(item["task_id"]) for item in pending], "accepted_task_lines": []},
        ]
        return {
            "schema_version": 1,
            "plan_path": PLAN_PATH,
            "todo_path": TODO_PATH,
            "source_baseline": source or self.binding_head(),
            "accepted_tasks": accepted,
            "pending_obligations": pending,
            "candidate_origins": candidate_origins or [],
            "coverage_map": coverage,
            "planner_note": "Prepared a bounded packet.",
        }

    def packet(self, *, attempt: str = "implementation", todo_line: str = TASK, task_id: str = "task-002", source: str | None = None, candidate_origins: list[dict[str, object]] | None = None) -> dict[str, object]:
        return {
            "schema_version": 1,
            "packet_id": f"{task_id}-abc123-1",
            "task_id": task_id,
            "todo_line": todo_line,
            "attempt": attempt,
            "plan_path": PLAN_PATH,
            "todo_path": TODO_PATH,
            "source_baseline": source or self.binding_head(),
            "outcome": "Deliver the selected slice",
            "scope": ["Change app.txt"],
            "scope_exclusions": [],
            "references": [{"path": "app.txt", "facts": "Existing accepted code"}],
            "constraints": [],
            "focused_validation": ["python -m pytest"],
            "completion_evidence_required": ["latest-worker-result.json"],
            "candidate_origins": candidate_origins or [],
        }

    def write_json(self, name: str, data: dict[str, object]) -> None:
        self.delivery.mkdir(parents=True, exist_ok=True)
        (self.delivery / name).write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")

    def write_planner_artifacts(self, *, attempt: str = "implementation", todo_line: str = TASK, task_id: str = "task-002", source: str | None = None, state: dict[str, object] | None = None, planner_result: dict[str, object] | None = None, packet: dict[str, object] | None = None) -> None:
        self.write_json("execution-state.json", state or self.state(source=source))
        self.write_json("planner-result.json", planner_result or self.planner_result(source=source))
        self.write_json("current-worker-packet.json", packet or self.packet(attempt=attempt, todo_line=todo_line, task_id=task_id, source=source))

    def write_worker_result(self, result: str = "ready_for_review", *, packet_id: str = "task-002-abc123-1") -> None:
        data: dict[str, object] = {
            "schema_version": 1,
            "packet_id": packet_id,
            "task_id": "task-002",
            "todo_line": TASK,
            "result": result,
            "changed_paths": ["app.txt"],
            "validation": [{"command": "true", "exit_status": 0, "evidence": "passed"}],
            "notes": "done",
            "unresolved": [],
        }
        if result == "replan":
            data["replan_request"] = {"blocker": "needs prerequisite", "partial_work": ["app.txt"], "completed_checks": ["true"], "remaining_validation": ["pytest"]}
        if result == "human_blocked":
            data["human_blocked_reason"] = "Business decision needed"
        self.write_json("latest-worker-result.json", data)

    def assert_guard_fails(self, expected: str) -> None:
        self.checkpoint("fabro(run): delivery_planner (succeeded)")
        result = self.invoke("guard-planner")
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(expected, result.stderr)

    def assert_guard_route(self, label: str) -> None:
        self.checkpoint("fabro(run): delivery_planner (succeeded)")
        result = self.invoke("guard-planner")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": label})

    def test_initial_planner_packet_routes_to_worker_and_tolerates_artifact_only_checkpoint(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.assert_guard_route("implement")

    def test_completed_todo_routes_to_final_gate_only_when_no_pending_existed_at_planner_entry(self) -> None:
        self.todo.write_text(TODO_TEXT.replace(TASK, TASK.replace("[ ]", "[x]", 1)).replace(NEXT_TASK, NEXT_TASK.replace("[ ]", "[x]", 1)))
        self.checkpoint("accepted all tasks")
        self.start_planner()
        accepted = [ACCEPTED, TASK.replace("[ ]", "[x]", 1), NEXT_TASK.replace("[ ]", "[x]", 1)]
        state = self.state(accepted=accepted, pending=[])
        state["coverage_map"] = [{"scope": "All accepted", "pending_task_ids": [], "accepted_task_lines": accepted}]
        self.write_json("execution-state.json", state)
        self.write_json("planner-result.json", self.planner_result("all_done"))
        self.assert_guard_route("all_done")

    def test_guard_rejects_planner_added_checkoff(self) -> None:
        self.start_planner()
        self.todo.write_text(TODO_TEXT.replace(TASK, TASK.replace("[ ]", "[x]", 1)).replace(NEXT_TASK, NEXT_TASK.replace("[ ]", "[x]", 1)))
        accepted = [ACCEPTED, TASK.replace("[ ]", "[x]", 1), NEXT_TASK.replace("[ ]", "[x]", 1)]
        state = self.state(accepted=accepted, pending=[])
        state["coverage_map"] = [{"scope": "Forged acceptance", "pending_task_ids": [], "accepted_task_lines": accepted}]
        self.write_json("execution-state.json", state)
        self.write_json("planner-result.json", self.planner_result("all_done"))
        self.assert_guard_fails("may not add, remove or change checked")

    def test_guard_rejects_deleted_pending_work_without_lineage(self) -> None:
        self.start_planner()
        self.todo.write_text(f"# TODO\n\n{ACCEPTED}\n")
        state = self.state(pending=[])
        state["coverage_map"] = [{"scope": "Accepted only", "pending_task_ids": [], "accepted_task_lines": [ACCEPTED]}]
        self.write_json("execution-state.json", state)
        self.write_json("planner-result.json", self.planner_result("all_done"))
        self.assert_guard_fails("removed pending obligations")

    def test_guard_allows_split_when_every_original_pending_line_has_lineage(self) -> None:
        self.start_planner()
        split_a = "- [ ] 002a Deliver the selected slice setup."
        split_b = "- [ ] 002b Deliver the selected slice behaviour."
        self.todo.write_text(f"# TODO\n\n{ACCEPTED}\n{split_a}\n{split_b}\n{NEXT_TASK}\n")
        pending = [
            {"task_id": "task-002a", "todo_line": split_a, "origin": "split from task-002", "status": "prepared", "coverage": ["setup"], "replaces": [TASK], "candidate_origins": []},
            {"task_id": "task-002b", "todo_line": split_b, "origin": "split from task-002", "status": "pending", "coverage": ["behaviour"], "replaces": [TASK], "candidate_origins": []},
            {"task_id": "task-003", "todo_line": NEXT_TASK, "origin": "plan", "status": "pending", "coverage": ["unit"], "replaces": [], "candidate_origins": []},
        ]
        self.write_planner_artifacts(state=self.state(pending=pending), packet=self.packet(todo_line=split_a, task_id="task-002a"))
        self.assert_guard_route("implement")

    def test_guard_rejects_missing_packet_handoff_fields(self) -> None:
        self.start_planner()
        packet = self.packet()
        for key in ["packet_id", "outcome", "scope", "scope_exclusions", "references", "constraints", "focused_validation", "completion_evidence_required"]:
            packet.pop(key)
        self.write_planner_artifacts(packet=packet)
        self.assert_guard_fails("requires non-empty string field packet_id")

    def test_guard_rejects_forged_guard_baseline_and_code_change(self) -> None:
        self.start_planner()
        (self.root / "app.txt").write_text("planner changed code\n")
        self.checkpoint("planner code change")
        forged_source = self.git("rev-parse", "HEAD")
        baseline_path = self.delivery / "_guard/planner-guard-baseline.json"
        baseline = json.loads(baseline_path.read_text())
        baseline["pre_planner_head"] = forged_source
        baseline_path.write_text(json.dumps(baseline, indent=2) + "\n")
        self.write_planner_artifacts(source=forged_source)
        self.assert_guard_fails("baseline was modified outside")

    def test_guard_rejects_planner_touching_worker_review_or_history_artifacts(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_json("latest-review.json", {"schema_version": 1, "decision": "accept"})
        self.assert_guard_fails("declared planner artifacts")

    def test_guard_rejects_implementation_attempt_after_unaccepted_revise_verdict(self) -> None:
        self.write_json("latest-review.json", {"schema_version": 1, "decision": "revise", "task": TASK, "reason": "gap", "packet_id": "task-002-abc123-1", "task_id": "task-002"})
        self.checkpoint("review requested revision")
        self.start_planner()
        self.write_planner_artifacts(attempt="implementation")
        self.assert_guard_fails("packet must route to bounded revision")

    def test_guard_rejects_renamed_revision_without_reviewed_task_lineage(self) -> None:
        self.write_json("latest-review.json", {"schema_version": 1, "decision": "revise", "task": TASK, "reason": "gap", "packet_id": "task-002-abc123-1", "task_id": "task-002"})
        self.checkpoint("review requested revision")
        self.start_planner()
        renamed = "- [ ] 002 Renamed repair task."
        self.todo.write_text(f"# TODO\n\n{ACCEPTED}\n{renamed}\n{NEXT_TASK}\n")
        pending = [
            {"task_id": "task-002", "todo_line": renamed, "origin": "renamed", "status": "prepared", "coverage": ["unit"], "replaces": [], "candidate_origins": []},
            {"task_id": "task-003", "todo_line": NEXT_TASK, "origin": "plan", "status": "pending", "coverage": ["unit"], "replaces": [], "candidate_origins": []},
        ]
        self.write_planner_artifacts(attempt="revision", todo_line=renamed, state=self.state(pending=pending), packet=self.packet(attempt="revision", todo_line=renamed))
        self.assert_guard_fails("removed pending obligations")

    def test_guard_routes_explicit_planner_human_block_without_stale_packet(self) -> None:
        self.start_planner()
        self.write_json("execution-state.json", self.state())
        self.write_json("planner-result.json", self.planner_result("human_blocked", actionable_reason="Acceptance contract ambiguous"))
        self.assert_guard_route("human_blocked")

    def test_guard_requires_candidate_provenance_to_survive_replan(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_worker_result("replan")
        self.checkpoint("candidate requested replan")
        second_binding = self.start_planner()
        baseline = json.loads((self.delivery / "_guard/planner-guard-baseline.json").read_text())
        origins = baseline["required_candidate_origins"]
        self.assertTrue(origins)
        # Planner tries to drop the candidate origin.
        self.write_planner_artifacts(source=second_binding)
        self.assert_guard_fails("dropped unaccepted candidate provenance")

    def prepare_replan_candidate(self) -> list[dict[str, object]]:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_worker_result("replan")
        (self.root / "app.txt").write_text("partial candidate\n")
        self.checkpoint("candidate requested replan")
        self.start_planner()
        baseline = json.loads((self.delivery / "_guard/planner-guard-baseline.json").read_text())
        return baseline["required_candidate_origins"]

    def test_global_provenance_must_be_assigned_to_pending_work_and_packet(self) -> None:
        origins = self.prepare_replan_candidate()
        self.write_planner_artifacts(state=self.state(candidate_origins=origins))
        self.assert_guard_fails("candidate provenance must be assigned")

    def test_accepted_candidate_provenance_retires_before_next_task(self) -> None:
        origins = self.prepare_replan_candidate()
        state = self.state(candidate_origins=origins)
        state["pending_obligations"][0]["candidate_origins"] = origins
        packet = self.packet(candidate_origins=origins)
        packet["packet_id"] = "task-002-replanned-2"
        self.write_planner_artifacts(state=state, packet=packet)
        self.assert_guard_route("implement")
        self.write_worker_result(packet_id="task-002-replanned-2")
        self.checkpoint("completed candidate")
        result = subprocess.run(
            [sys.executable, str(HELPER.with_name("apply_task_verdict.py")), str(self.plan)],
            input=json.dumps({"decision": "accept", "task": TASK, "reason": "Candidate verified"}),
            cwd=self.root, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.checkpoint("applied acceptance")
        self.start_planner()
        baseline = json.loads((self.delivery / "_guard/planner-guard-baseline.json").read_text())
        self.assertEqual(baseline["required_candidate_origins"], [])

    def test_shared_candidate_origin_stays_pending_after_one_slice_accepted(self) -> None:
        origins = self.prepare_replan_candidate()
        state = self.state(candidate_origins=origins)
        for obligation in state["pending_obligations"]:
            obligation["candidate_origins"] = origins
            obligation["replaces"] = [TASK]
        packet = self.packet(candidate_origins=origins)
        packet["packet_id"] = "task-002-shared-2"
        self.write_planner_artifacts(state=state, packet=packet)
        self.assert_guard_route("implement")
        self.write_worker_result(packet_id="task-002-shared-2")
        self.checkpoint("completed first slice")
        result = subprocess.run(
            [sys.executable, str(HELPER.with_name("apply_task_verdict.py")), str(self.plan)],
            input=json.dumps({"decision": "accept", "task": TASK, "reason": "First slice verified"}),
            cwd=self.root, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.checkpoint("applied first acceptance")
        self.start_planner()
        baseline = json.loads((self.delivery / "_guard/planner-guard-baseline.json").read_text())
        self.assertEqual(baseline["required_candidate_origins"], origins)

    def test_packet_identity_cannot_reuse_previous_preparation(self) -> None:
        self.start_planner()
        old_packet = self.packet()
        self.write_planner_artifacts(packet=old_packet)
        self.checkpoint("previous preparation")
        self.start_planner()
        packet = self.packet()
        packet["packet_id"] = old_packet["packet_id"]
        self.write_planner_artifacts(packet=packet)
        self.assert_guard_fails("new packet_id")

    def test_route_worker_result_sends_replan_without_review_or_checkoff(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_worker_result("replan")
        result = self.invoke("route-worker")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": "replan"})
        self.assertIn(TASK, self.todo.read_text())

    def test_ready_worker_result_rejects_failed_validation(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_worker_result()
        result_path = self.delivery / "latest-worker-result.json"
        result_data = json.loads(result_path.read_text())
        result_data["validation"][0]["exit_status"] = 1
        result_path.write_text(json.dumps(result_data))
        result = self.invoke("route-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires every validation command to pass", result.stderr)

    def test_route_worker_result_fails_closed_on_mismatched_or_incomplete_artifacts(self) -> None:
        self.start_planner()
        self.write_planner_artifacts()
        self.write_worker_result(packet_id="old-packet")
        result = self.invoke("route-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match current packet", result.stderr)

        self.write_json("latest-worker-result.json", {"schema_version": 1, "packet_id": "task-002-abc123-1", "task_id": "task-002", "todo_line": TASK, "result": "ready_for_review"})
        result = self.invoke("route-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("changed_paths", result.stderr)


if __name__ == "__main__":
    unittest.main()
