#!/usr/bin/env python3
"""Apply a schema-validated review from Fabro stdin; only acceptance completes work."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import sys
import tempfile
import time
from typing import Any

from delivery_planner_state import ContractError, delivery_paths, read_json, require_string, run_git

PENDING = re.compile(r"^[\t ]*- \[ \] \S[^\r\n]*$")
SCHEMA_VERSION = 1


def git_head() -> str:
    try:
        return run_git("rev-parse", "HEAD")
    except Exception:
        return "unknown"


def write_review_artifact(plan: Path, verdict: dict[str, str], packet: dict[str, Any], result: dict[str, Any]) -> None:
    delivery = plan.parent / ".delivery"
    review = {
        "schema_version": SCHEMA_VERSION,
        "decision": verdict["decision"],
        "task": verdict["task"],
        "reason": verdict["reason"],
        "packet_id": packet["packet_id"],
        "task_id": packet["task_id"],
        "worker_result": result["result"],
        "candidate_origins": packet.get("candidate_origins", []),
        "reviewed_head": git_head(),
        "recorded_at": int(time.time()),
    }
    delivery.mkdir(parents=True, exist_ok=True)
    (delivery / "latest-review.json").write_text(json.dumps(review, indent=2, sort_keys=True) + "\n")
    with (delivery / "history.jsonl").open("a") as output:
        output.write(json.dumps({"kind": "review", **review}, sort_keys=True) + "\n")


def validate_verdict_shape(verdict: object) -> tuple[str, str, str]:
    if not isinstance(verdict, dict) or set(verdict) != {"decision", "task", "reason"}:
        raise ValueError("Expected only decision, task and reason in the task verdict")
    decision, task, reason = (verdict[key] for key in ("decision", "task", "reason"))
    if decision not in ("accept", "revise", "blocked"):
        raise ValueError("Task decision must be accept, revise or blocked")
    if not isinstance(task, str) or not PENDING.fullmatch(task):
        raise ValueError("Task must be the exact unchecked todo line")
    if not isinstance(reason, str) or not reason.strip():
        raise ValueError("Task verdict requires a non-empty reason")
    return decision, task, reason


def validate_todo_application(todo: Path, decision: str, task: str) -> tuple[list[str], int, bool]:
    text = todo.read_bytes().decode("utf-8")
    lines = text.splitlines(keepends=True)
    contents = [line.rstrip("\r\n") for line in lines]
    accepted = task.replace("- [ ] ", "- [x] ", 1)
    matches = [index for index, line in enumerate(contents) if line in (task, accepted)]
    if len(matches) != 1:
        raise ValueError(f"Reviewed task is missing or ambiguous in {todo}: {task}")
    index = matches[0]
    first_pending = next((i for i, line in enumerate(contents) if PENDING.fullmatch(line)), None)
    replay = decision == "accept" and contents[index] == accepted
    if (not replay and index != first_pending) or (replay and first_pending is not None and first_pending < index):
        raise ValueError(f"Reviewed task is not the first pending task in {todo}: {task}")
    return lines, index, replay


def check_off(todo: Path, lines: list[str], index: int) -> None:
    lines[index] = lines[index].replace("- [ ] ", "- [x] ", 1)
    with tempfile.NamedTemporaryFile(dir=todo.parent, delete=False) as output:
        temporary = Path(output.name)
        try:
            output.write("".join(lines).encode("utf-8"))
            output.flush()
            os.chmod(temporary, todo.stat().st_mode)
            temporary.replace(todo)
        finally:
            temporary.unlink(missing_ok=True)


def validate_review_artifacts(paths: dict[str, Path], task: str) -> tuple[dict[str, Any], dict[str, Any]]:
    packet = read_json(paths["packet"])
    result = read_json(paths["worker_result"])
    if packet.get("schema_version") != SCHEMA_VERSION or result.get("schema_version") != SCHEMA_VERSION:
        raise ValueError("Delivery packet/result schema version mismatch")
    for key in ("packet_id", "task_id", "todo_line"):
        require_string(packet, key, paths["packet"])
        if result.get(key) != packet.get(key):
            raise ValueError(f"Worker result {key} does not match current packet")
    if packet["todo_line"] != task:
        raise ValueError("Verdict task does not match the current worker packet")
    if result.get("result") != "ready_for_review":
        raise ValueError("Only a worker result marked ready_for_review may be reviewed for acceptance")
    validation = result.get("validation")
    if not isinstance(validation, list) or not validation:
        raise ValueError("ready_for_review worker result requires validation evidence")
    for item in validation:
        if not isinstance(item, dict) or not isinstance(item.get("command"), str) or not isinstance(item.get("exit_status"), int) or not isinstance(item.get("evidence"), str):
            raise ValueError("Worker validation entries require command, integer exit_status and evidence")
    if not isinstance(result.get("changed_paths"), list) or not isinstance(result.get("unresolved"), list) or not isinstance(result.get("notes"), str):
        raise ValueError("Worker result requires changed_paths, notes and unresolved fields")
    return packet, result


def apply_verdict(plan: Path, verdict: object) -> None:
    decision, task, reason = validate_verdict_shape(verdict)
    if plan.name != "plan.md" or not plan.is_file():
        raise ValueError(f"Expected an existing plan.md: {plan}")

    paths = delivery_paths(plan)
    todo = paths["todo"]
    try:
        packet, result = validate_review_artifacts(paths, task)
    except ContractError as error:
        raise ValueError(str(error)) from error

    lines, index, replay = validate_todo_application(todo, decision, task)
    verdict_dict = {"decision": decision, "task": task, "reason": reason}

    if decision == "accept" and not replay:
        check_off(todo, lines, index)
        write_review_artifact(plan, verdict_dict, packet, result)
    elif decision == "accept" and replay:
        write_review_artifact(plan, verdict_dict, packet, result)
    elif decision == "revise":
        write_review_artifact(plan, verdict_dict, packet, result)
    else:
        write_review_artifact(plan, verdict_dict, packet, result)
        raise ValueError(f"Task blocked: {task}\n{reason}")

    print(f"Task {decision}: {task}\n{reason}", file=sys.stderr)
    print(json.dumps({"preferred_next_label": decision}))


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: apply_task_verdict.py PLAN_PATH < verdict.json", file=sys.stderr)
        return 2
    try:
        apply_verdict(Path(sys.argv[1]), json.load(sys.stdin))
    except (ValueError, OSError, json.JSONDecodeError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
