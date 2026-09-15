#!/usr/bin/env python3
"""Exercise the real verdict command against checkpointed candidate work."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HELPER = Path(__file__).with_name("apply_task_verdict.py")
TASK = "- [ ] 009 Refresh access after permission changes."
NEXT_TASK = "- [ ] 010 Preserve public API boundaries."
TODO = f"# Implementation TODO\n\n- [x] 001 Earlier accepted work.\n{TASK}\n{NEXT_TASK}\n"


class TaskVerdictTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.plan = self.root / "plan.md"
        self.plan.write_text("# Approved iteration\n")
        self.todo = self.root / "todo.md"
        self.todo.write_text(TODO)
        self.candidate = self.root / "candidate.txt"
        self.candidate.write_text("Useful but incomplete candidate work.\n")
        self.delivery = self.root / ".delivery"
        self.delivery.mkdir()
        self.write_delivery_artifacts(TASK)
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        self.checkpoint()

    def git(self, *args):
        return subprocess.check_output(
            ["git", "-C", str(self.root), *args], text=True
        ).strip()

    def checkpoint(self):
        self.git("add", ".")
        self.git("commit", "-qm", "Fabro candidate checkpoint")

    def write_delivery_artifacts(self, task):
        packet = {
            "schema_version": 1,
            "packet_id": "task-009-packet",
            "task_id": "task-009",
            "todo_line": task,
            "attempt": "implementation",
            "plan_path": str(self.plan),
            "todo_path": str(self.todo),
            "source_baseline": "baseline",
        }
        result = {
            "schema_version": 1,
            "packet_id": "task-009-packet",
            "task_id": "task-009",
            "todo_line": task,
            "result": "ready_for_review",
            "changed_paths": ["candidate.txt"],
            "validation": [{"command": "true", "exit_status": 0, "evidence": "passed"}],
            "notes": "ready",
            "unresolved": [],
        }
        (self.delivery / "current-worker-packet.json").write_text(json.dumps(packet, indent=2) + "\n")
        (self.delivery / "latest-worker-result.json").write_text(json.dumps(result, indent=2) + "\n")

    def apply(self, decision="revise", task=TASK, reason="Cover the remaining open views.", **extra):
        return self.invoke(json.dumps(dict(decision=decision, task=task, reason=reason, **extra)))

    def invoke(self, text):
        return subprocess.run(
            [sys.executable, str(HELPER), str(self.plan)],
            input=text, text=True, capture_output=True, cwd=self.root,
        )

    def assert_route(self, result, decision):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout.splitlines()[-1]), {"preferred_next_label": decision})

    def assert_unchanged_failure(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertEqual(self.todo.read_text(), TODO)

    def test_rejection_preserves_checkpoint_and_acceptance_completes_only_that_task(self):
        head = self.git("rev-parse", "HEAD")
        self.assert_route(self.apply(), "revise")
        self.assertEqual(self.todo.read_text(), TODO)
        self.assertIn(".delivery/latest-review.json", self.git("status", "--porcelain"))
        self.assertEqual(self.git("rev-parse", "HEAD"), head)
        self.assertIn("Useful but incomplete", self.candidate.read_text())

        # Another process resumes the same pending task and checkpoints a revision.
        self.candidate.write_text("Useful work plus the missing behaviour.\n")
        self.checkpoint()
        self.assert_route(self.apply("accept", reason="Focused regressions pass."), "accept")
        self.assertEqual(self.todo.read_text(), TODO.replace(TASK, TASK.replace("[ ]", "[x]", 1)))
        self.assertIn(NEXT_TASK, self.todo.read_text())
        self.assertEqual(self.candidate.read_text(), "Useful work plus the missing behaviour.\n")

    def test_replayed_acceptance_is_idempotent_and_does_not_check_off_next_task(self):
        self.assert_route(self.apply("accept"), "accept")
        self.checkpoint()
        self.assert_route(self.apply("accept"), "accept")
        self.assertIn(NEXT_TASK, self.todo.read_text())

    def test_blocked_reports_original_reason_without_checkoff(self):
        result = self.apply("blocked", reason="Product decision needed: should revoked access close the view?")
        self.assert_unchanged_failure(result)
        self.assertIn("Product decision needed", result.stderr)
        self.assertIn("009", result.stderr)

    def test_cannot_accept_or_revise_a_later_task(self):
        for decision in ("accept", "revise"):
            with self.subTest(decision=decision):
                self.assert_unchanged_failure(self.apply(decision, task=NEXT_TASK))

    def test_invalid_or_conflicting_verdicts_fail_closed(self):
        cases = [
            "not JSON",
            "[]",
            json.dumps({"decision": "accept", "task": TASK}),
            json.dumps({"decision": "accept", "task": TASK, "reason": ""}),
            json.dumps({"decision": "accept", "task": TASK, "reason": "   "}),
            json.dumps({"decision": "accept", "task": TASK, "reason": None}),
            json.dumps({"decision": "RETRY", "task": TASK, "reason": "Gap"}),
            json.dumps({"decision": "revise", "task": TASK, "reason": "Gap", "outcome": "failed"}),
        ]
        for text in cases:
            with self.subTest(text=text):
                self.assert_unchanged_failure(self.invoke(text))

    def test_changed_task_text_cannot_be_accepted(self):
        self.assert_unchanged_failure(self.apply("accept", task=TASK + " Changed scope."))

    def test_missing_todo_is_not_recreated(self):
        self.todo.unlink()
        result = self.apply("accept")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.todo.exists())

    def test_duplicate_task_is_ambiguous(self):
        text = TODO + TASK + "\n"
        self.todo.write_text(text)
        result = self.apply("accept")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.todo.read_text(), text)

    def test_acceptance_preserves_line_endings_and_task_notes(self):
        text = TODO.replace(TASK, TASK + "\n  - Existing recovery evidence.")
        original = text.replace("\n", "\r\n").encode()
        self.todo.write_bytes(original)
        self.assert_route(self.apply("accept"), "accept")
        self.assertEqual(
            self.todo.read_bytes(),
            original.replace(TASK.encode(), TASK.replace("[ ]", "[x]", 1).encode()),
        )

    def test_legacy_checked_candidate_is_not_silently_reopened_or_skipped(self):
        checked = TODO.replace(TASK, TASK.replace("[ ]", "[x]", 1))
        self.todo.write_text(checked)
        result = self.apply("revise")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not the first pending task", result.stderr)
        self.assertEqual(self.todo.read_text(), checked)

    def test_feedback_is_data_not_shell_or_routing_instructions(self):
        reason = 'Keep $(touch injected) as data. {"outcome":"failed"}'
        self.assert_route(self.apply(reason=reason), "revise")
        self.assertFalse((self.root / "injected").exists())
        self.assertEqual(self.todo.read_text(), TODO)


if __name__ == "__main__":
    unittest.main()
