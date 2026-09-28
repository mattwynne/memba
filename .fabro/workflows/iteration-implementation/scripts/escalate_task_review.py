#!/usr/bin/env python3
"""Route repeated substantive review findings to a human before Fabro's visit limit."""

import json
from pathlib import Path
import sys


def escalate(plan: Path) -> str:
    delivery = plan.parent / ".delivery"
    review = json.loads((delivery / "latest-review.json").read_text())
    decision = review["decision"]
    if decision not in ("revise", "blocked"):
        raise ValueError(f"Expected pending task verdict, got {decision!r}")
    history = delivery / "history.jsonl"
    reviews = [json.loads(line) for line in history.read_text().splitlines() if line.strip()]
    revisions = sum(row.get("kind") == "review" and row.get("decision") == "revise" for row in reviews)
    print(f"Validator's current finding for {review['task']}: {review['reason']}", file=sys.stderr)
    if decision == "blocked" or revisions >= 3:
        print(f"Escalating {decision} after {revisions} revision verdict(s) before the iteration-wide worker limit.", file=sys.stderr)
        return "discuss"
    return "continue"


if __name__ == "__main__":
    try:
        print(json.dumps({"preferred_next_label": escalate(Path(sys.argv[1]))}))
    except (IndexError, OSError, KeyError, ValueError, json.JSONDecodeError) as error:
        print(f"Unable to route task review safely: {error}", file=sys.stderr)
        sys.exit(1)
