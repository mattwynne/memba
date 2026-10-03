import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from escalate_task_review import escalate


class EscalationTest(unittest.TestCase):
    def test_blocked_and_third_revision_discuss_before_worker_visit_limit(self):
        with tempfile.TemporaryDirectory() as root:
            plan = Path(root) / "plan.md"
            plan.write_text("# Example\n")
            delivery = plan.parent / ".delivery"
            delivery.mkdir()
            review = {
                "kind": "review",
                "decision": "revise",
                "task": "- [ ] Task",
                "task_id": "task-008a",
                "reason": "Missing current authority",
            }
            (delivery / "latest-review.json").write_text(json.dumps(review))
            history = delivery / "history.jsonl"
            other_task = {**review, "task_id": "task-005"}
            earlier_tasks = [
                {**review, "task_id": task_id}
                for task_id in ("task-001", "task-003", "task-005")
            ]
            for count in (1, 2, 3):
                rows = earlier_tasks + [review] * count
                history.write_text("".join(json.dumps(row) + "\n" for row in rows))
                self.assertEqual(escalate(plan), "discuss" if count == 3 else "continue")

            # Three earlier revision verdicts on other tasks cannot escalate
            # this task's first finding, even when a prior task has two.
            history.write_text("".join(json.dumps(row) + "\n" for row in [other_task] * 3 + [review]))
            self.assertEqual(escalate(plan), "continue")

            review["decision"] = "blocked"
            (delivery / "latest-review.json").write_text(json.dumps(review))
            self.assertEqual(escalate(plan), "discuss")
            review["decision"] = "accept"
            (delivery / "latest-review.json").write_text(json.dumps(review))
            with self.assertRaises(ValueError):
                escalate(plan)

            review.pop("task_id")
            review["decision"] = "revise"
            (delivery / "latest-review.json").write_text(json.dumps(review))
            with self.assertRaises(KeyError):
                escalate(plan)


if __name__ == "__main__":
    unittest.main()
