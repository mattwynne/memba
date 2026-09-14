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
ACCEPTED = "- [x] 001 Accepted foundation."
TODO_TEXT = f"# TODO\n\n{ACCEPTED}\n{TASK}\n"


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
        self.plan.write_text("# Plan\n\n## Implementation Plan\n\n1. Deliver the selected slice.\n")
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

    def baseline_head(self) -> str:
        return json.loads((self.delivery / "planner-guard-baseline.json").read_text())["baseline_head"]

    def write_planner_artifacts(self, *, attempt: str = "implementation", todo_line: str = TASK, source: str | None = None) -> None:
        source = source or self.baseline_head()
        self.delivery.mkdir(parents=True, exist_ok=True)
        state = {
            "schema_version": 1,
            "plan_path": "docs/iterations/009-test/plan.md",
            "todo_path": "docs/iterations/009-test/todo.md",
            "source_baseline": source,
            "accepted_tasks": [ACCEPTED],
            "pending_obligations": [{"task_id": "task-002", "todo_line": todo_line, "origin": "plan", "status": "prepared", "coverage": ["unit"], "replaces": []}],
            "coverage_map": [{"scope": "Deliver slice", "covered_by": ["task-002"]}],
            "planner_note": "Prepared a bounded packet.",
        }
        packet = {
            "schema_version": 1,
            "packet_id": "task-002-abc123-1",
            "task_id": "task-002",
            "todo_line": todo_line,
            "attempt": attempt,
            "plan_path": "docs/iterations/009-test/plan.md",
            "todo_path": "docs/iterations/009-test/todo.md",
            "source_baseline": source,
            "outcome": "Deliver the selected slice",
            "scope": ["Change app.txt"],
            "scope_exclusions": [],
            "references": [{"path": "app.txt", "facts": "Existing accepted code"}],
            "constraints": [],
            "focused_validation": ["python -m pytest"],
            "completion_evidence_required": ["latest-worker-result.json"],
        }
        (self.delivery / "execution-state.json").write_text(json.dumps(state, indent=2) + "\n")
        (self.delivery / "current-worker-packet.json").write_text(json.dumps(packet, indent=2) + "\n")

    def write_worker_result(self, result: str = "ready_for_review", *, packet_id: str = "task-002-abc123-1") -> None:
        data = {
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
        (self.delivery / "latest-worker-result.json").write_text(json.dumps(data, indent=2) + "\n")

    def test_initial_planner_packet_routes_to_worker_and_tolerates_artifact_only_checkpoint(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts()
        self.checkpoint("planner artifacts only")
        result = self.invoke("guard-planner")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": "implement"})

    def test_revision_packet_routes_to_bounded_revision_worker(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts(attempt="revision")
        self.checkpoint("revision packet")
        result = self.invoke("guard-planner")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": "revise"})

    def test_completed_todo_routes_to_final_gate_without_worker_packet(self) -> None:
        self.todo.write_text(TODO_TEXT.replace(TASK, TASK.replace("[ ]", "[x]", 1)))
        self.checkpoint("accepted task")
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.delivery.mkdir(exist_ok=True)
        state = {
            "schema_version": 1,
            "plan_path": "docs/iterations/009-test/plan.md",
            "todo_path": "docs/iterations/009-test/todo.md",
            "source_baseline": self.baseline_head(),
            "accepted_tasks": [ACCEPTED, TASK.replace("[ ]", "[x]", 1)],
            "pending_obligations": [],
            "coverage_map": [],
            "planner_note": "All tasks accepted.",
        }
        (self.delivery / "execution-state.json").write_text(json.dumps(state) + "\n")
        self.checkpoint("completion state")
        result = self.invoke("guard-planner")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": "all_done"})

    def test_guard_fails_closed_when_planner_changes_code_or_plan(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts()
        (self.root / "app.txt").write_text("planner changed code\n")
        self.checkpoint("illegal planner change")
        result = self.invoke("guard-planner")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("may only change", result.stderr)

    def test_guard_fails_closed_when_packet_task_is_stale_or_mismatched(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts(todo_line="- [ ] 999 Wrong task.")
        self.checkpoint("mismatched packet")
        result = self.invoke("guard-planner")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match the first pending", result.stderr)

    def test_route_worker_result_sends_replan_without_review_or_checkoff(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts()
        self.write_worker_result("replan")
        result = self.invoke("route-worker")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": "replan"})
        self.assertIn(TASK, self.todo.read_text())

    def test_route_worker_result_fails_closed_on_mismatched_artifacts(self) -> None:
        self.assertEqual(self.invoke("before-planner").returncode, 0)
        self.write_planner_artifacts()
        self.write_worker_result(packet_id="old-packet")
        result = self.invoke("route-worker")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match current packet", result.stderr)


if __name__ == "__main__":
    unittest.main()
