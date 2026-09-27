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
            review = {"kind": "review", "decision": "revise", "task": "- [ ] Task", "reason": "Missing current authority"}
            (delivery / "latest-review.json").write_text(json.dumps(review))
            history = delivery / "history.jsonl"
            for count in (1, 2, 3):
                history.write_text((json.dumps(review) + "\n") * count)
                self.assertEqual(escalate(plan), "discuss" if count == 3 else "continue")
            review["decision"] = "blocked"
            (delivery / "latest-review.json").write_text(json.dumps(review))
            self.assertEqual(escalate(plan), "discuss")
            review["decision"] = "accept"
            (delivery / "latest-review.json").write_text(json.dumps(review))
            with self.assertRaises(ValueError):
                escalate(plan)


if __name__ == "__main__":
    unittest.main()
