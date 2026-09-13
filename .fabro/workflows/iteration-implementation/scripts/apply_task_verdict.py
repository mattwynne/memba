#!/usr/bin/env python3
"""Apply a schema-validated review from Fabro stdin; only acceptance completes work."""

import json
import os
from pathlib import Path
import re
import sys
import tempfile

PENDING = re.compile(r"^[\t ]*- \[ \] \S[^\r\n]*$")


def apply_verdict(plan: Path, verdict: object) -> None:
    # Also fail closed when invoked directly, outside Fabro's schema validation.
    if not isinstance(verdict, dict) or set(verdict) != {"decision", "task", "reason"}:
        raise ValueError("Expected only decision, task and reason in the task verdict")
    decision, task, reason = (verdict[key] for key in ("decision", "task", "reason"))
    if decision not in ("accept", "revise", "blocked"):
        raise ValueError("Task decision must be accept, revise or blocked")
    if not isinstance(task, str) or not PENDING.fullmatch(task):
        raise ValueError("Task must be the exact unchecked todo line")
    if not isinstance(reason, str) or not reason.strip():
        raise ValueError("Task verdict requires a non-empty reason")
    if plan.name != "plan.md" or not plan.is_file():
        raise ValueError(f"Expected an existing plan.md: {plan}")

    todo = plan.with_name("todo.md")
    # Keep original line endings and all unrelated task text intact.
    text = todo.read_bytes().decode("utf-8")
    lines = text.splitlines(keepends=True)
    contents = [line.rstrip("\r\n") for line in lines]
    accepted = task.replace("- [ ] ", "- [x] ", 1)
    matches = [index for index, line in enumerate(contents) if line in (task, accepted)]
    if len(matches) != 1:
        raise ValueError(f"Reviewed task is missing or ambiguous in {todo}: {task}")
    index = matches[0]
    first_pending = next((i for i, line in enumerate(contents) if PENDING.fullmatch(line)), None)

    # A resumed command may replay acceptance after the check-off was written.
    # Never complete the next task in its place.
    replay = decision == "accept" and contents[index] == accepted
    if (not replay and index != first_pending) or (replay and first_pending is not None and first_pending < index):
        raise ValueError(f"Reviewed task is not the first pending task in {todo}: {task}")
    if decision == "blocked":
        raise ValueError(f"Task blocked: {task}\n{reason}")
    if decision == "accept" and not replay:
        lines[index] = lines[index].replace("- [ ] ", "- [x] ", 1)
        # Atomic replacement plus replay safety covers interruption at check-off.
        with tempfile.NamedTemporaryFile(dir=todo.parent, delete=False) as output:
            temporary = Path(output.name)
            try:
                output.write("".join(lines).encode("utf-8"))
                output.flush()
                os.chmod(temporary, todo.stat().st_mode)
                temporary.replace(todo)
            finally:
                temporary.unlink(missing_ok=True)

    print(f"Task {decision}: {task}\n{reason}", file=sys.stderr)
    # Fabro validates this deterministic routing object, not the model's prose.
    print(json.dumps({"preferred_next_label": decision}))


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: apply_task_verdict.py PLAN_PATH < verdict.json", file=sys.stderr)
        return 2
    try:
        apply_verdict(Path(sys.argv[1]), json.load(sys.stdin))
    except (ValueError, OSError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
