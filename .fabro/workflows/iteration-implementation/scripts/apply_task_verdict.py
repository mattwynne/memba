#!/usr/bin/env python3
"""Apply a schema-validated review from Fabro stdin; only acceptance completes work."""

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

PENDING = re.compile(r"^[\t ]*- \[ \] \S[^\r\n]*$")
SCHEMA_VERSION = 1


def read_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError as error:
        raise ValueError(f"Missing required delivery artifact: {path}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"Malformed delivery artifact: {path}: {error}") from error
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}")
    return data


def git_head() -> str:
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def write_review_artifact(plan: Path, verdict: dict) -> None:
    delivery = plan.parent / ".delivery"
    packet_path = delivery / "current-worker-packet.json"
    result_path = delivery / "latest-worker-result.json"
    packet = read_json(packet_path)
    result = read_json(result_path)
    if packet.get("schema_version") != SCHEMA_VERSION or result.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("Delivery packet/result schema version mismatch")
    for key in ("packet_id", "task_id", "todo_line"):
        if result.get(key) != packet.get(key):
            raise ValueError(f"Worker result {key} does not match current packet")
    if result.get("result") != "ready_for_review":
        raise ValueError("Only a worker result marked ready_for_review may be reviewed for acceptance")
    if verdict["task"] != packet.get("todo_line"):
        raise ValueError("Verdict task does not match the current worker packet")

    review = {
        "schema_version": SCHEMA_VERSION,
        "decision": verdict["decision"],
        "task": verdict["task"],
        "reason": verdict["reason"],
        "packet_id": packet.get("packet_id"),
        "task_id": packet.get("task_id"),
        "reviewed_head": git_head(),
        "recorded_at": int(time.time()),
    }
    delivery.mkdir(parents=True, exist_ok=True)
    (delivery / "latest-review.json").write_text(json.dumps(review, indent=2, sort_keys=True) + "\n")
    with (delivery / "history.jsonl").open("a") as output:
        output.write(json.dumps({"kind": "review", **review}, sort_keys=True) + "\n")


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

    verdict_dict = {"decision": decision, "task": task, "reason": reason}
    write_review_artifact(plan, verdict_dict)

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
