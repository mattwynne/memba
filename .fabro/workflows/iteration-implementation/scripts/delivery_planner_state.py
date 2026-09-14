#!/usr/bin/env python3
"""Durable artifact and routing helpers for the iteration delivery planner loop."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

PENDING = re.compile(r"^[\t ]*- \[ \] \S[^\r\n]*$")
CHECKED = re.compile(r"^[\t ]*- \[x\] \S[^\r\n]*$")
SCHEMA_VERSION = 1


class ContractError(RuntimeError):
    pass


def run_git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def plan_parts(plan: Path) -> tuple[Path, Path, Path]:
    if plan.name != "plan.md" or not plan.is_file():
        raise ContractError(f"Expected an existing plan.md: {plan}")
    iteration_dir = plan.parent
    todo = iteration_dir / "todo.md"
    delivery = iteration_dir / ".delivery"
    return iteration_dir, todo, delivery


def rel(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_todo_lines(todo: Path) -> list[str]:
    if not todo.is_file():
        raise ContractError(f"Todo file missing: {todo}")
    return [line.rstrip("\r\n") for line in todo.read_text().splitlines()]


def checked_lines(todo: Path) -> list[str]:
    return [line for line in read_todo_lines(todo) if CHECKED.fullmatch(line)]


def pending_lines(todo: Path) -> list[str]:
    return [line for line in read_todo_lines(todo) if PENDING.fullmatch(line)]


def first_pending(todo: Path) -> str | None:
    return next((line for line in read_todo_lines(todo) if PENDING.fullmatch(line)), None)


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text())
    except FileNotFoundError as error:
        raise ContractError(f"Missing required delivery artifact: {path}") from error
    except json.JSONDecodeError as error:
        raise ContractError(f"Malformed JSON in {path}: {error}") from error
    if not isinstance(data, dict):
        raise ContractError(f"Expected JSON object in {path}")
    return data


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def append_history(delivery: Path, kind: str, data: dict[str, Any]) -> None:
    delivery.mkdir(parents=True, exist_ok=True)
    record = {"kind": kind, "recorded_at": int(time.time()), **data}
    with (delivery / "history.jsonl").open("a") as output:
        output.write(json.dumps(record, sort_keys=True) + "\n")


def route(label: str) -> None:
    print(json.dumps({"preferred_next_label": label}))


def delivery_paths(plan: Path) -> dict[str, Path]:
    _, todo, delivery = plan_parts(plan)
    return {
        "todo": todo,
        "delivery": delivery,
        "baseline": delivery / "planner-guard-baseline.json",
        "state": delivery / "execution-state.json",
        "packet": delivery / "current-worker-packet.json",
        "worker_result": delivery / "latest-worker-result.json",
        "review": delivery / "latest-review.json",
    }


def allowed_planner_path(path: str, todo: Path, delivery: Path) -> bool:
    todo_rel = rel(todo)
    delivery_rel = rel(delivery)
    return path == todo_rel or path.startswith(delivery_rel + "/")


def changed_since(base: str) -> list[str]:
    if not base:
        raise ContractError("Missing baseline commit")
    try:
        run_git("cat-file", "-e", f"{base}^{{commit}}")
    except subprocess.CalledProcessError as error:
        raise ContractError(f"Baseline commit does not exist: {base}") from error
    names: set[str] = set()
    for args in (("diff", "--name-only", f"{base}..HEAD"), ("diff", "--name-only"), ("diff", "--cached", "--name-only")):
        out = run_git(*args)
        names.update(line for line in out.splitlines() if line)
    return sorted(names)


def assert_no_nonartifact_change_since(base: str, todo: Path, delivery: Path) -> None:
    disallowed = [path for path in changed_since(base) if not allowed_planner_path(path, todo, delivery)]
    if disallowed:
        raise ContractError(
            "Planner packet is stale or planner changed non-planning files since "
            f"{base}: {', '.join(disallowed)}"
        )


def before_planner(plan: Path) -> None:
    paths = delivery_paths(plan)
    todo = paths["todo"]
    delivery = paths["delivery"]
    if not todo.is_file():
        raise ContractError(f"Todo file missing before planner: {todo}")
    baseline = {
        "schema_version": SCHEMA_VERSION,
        "plan_path": rel(plan),
        "todo_path": rel(todo),
        "baseline_head": run_git("rev-parse", "HEAD"),
        "plan_sha256": file_sha(plan),
        "accepted_tasks": checked_lines(todo),
        "pending_before": pending_lines(todo),
        "created_at": int(time.time()),
    }
    write_json(paths["baseline"], baseline)
    print(f"Delivery planner baseline captured at {baseline['baseline_head']} in {paths['baseline']}")


def require_string(data: dict[str, Any], key: str, path: Path) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ContractError(f"{path} requires non-empty string field {key}")
    return value


def guard_planner(plan: Path) -> None:
    paths = delivery_paths(plan)
    todo = paths["todo"]
    delivery = paths["delivery"]
    baseline = read_json(paths["baseline"])
    if baseline.get("schema_version") != SCHEMA_VERSION:
        raise ContractError("Planner baseline schema version mismatch")
    if baseline.get("plan_path") != rel(plan) or baseline.get("todo_path") != rel(todo):
        raise ContractError("Planner baseline does not match this plan/todo path")
    if baseline.get("plan_sha256") != file_sha(plan):
        raise ContractError("Planner changed the approved plan.md; stopping")
    base = require_string(baseline, "baseline_head", paths["baseline"])
    disallowed = [path for path in changed_since(base) if not allowed_planner_path(path, todo, delivery)]
    if disallowed:
        raise ContractError("Delivery planner may only change todo.md and .delivery artifacts; changed: " + ", ".join(disallowed))

    current_checked = set(checked_lines(todo))
    lost = [line for line in baseline.get("accepted_tasks", []) if line not in current_checked]
    if lost:
        raise ContractError("Delivery planner removed or changed accepted task records: " + "; ".join(lost))

    state = read_json(paths["state"])
    if state.get("schema_version") != SCHEMA_VERSION:
        raise ContractError("execution-state.json schema version mismatch")
    if state.get("plan_path") != rel(plan) or state.get("todo_path") != rel(todo):
        raise ContractError("execution-state.json does not match this plan/todo path")
    for line in current_checked:
        if line not in state.get("accepted_tasks", []):
            raise ContractError(f"execution-state.json omits accepted task: {line}")

    selected = first_pending(todo)
    if selected is None:
        # No worker packet is needed when the planner proves all tasks are complete.
        route("all_done")
        return

    packet = read_json(paths["packet"])
    if packet.get("schema_version") != SCHEMA_VERSION:
        raise ContractError("current-worker-packet.json schema version mismatch")
    if packet.get("plan_path") != rel(plan) or packet.get("todo_path") != rel(todo):
        raise ContractError("current-worker-packet.json does not match this plan/todo path")
    if packet.get("todo_line") != selected:
        raise ContractError(
            "Worker packet task does not match the first pending todo line: "
            f"packet={packet.get('todo_line')!r}, first_pending={selected!r}"
        )
    if packet.get("source_baseline") != base:
        raise ContractError("Worker packet source_baseline must equal the guarded planner baseline")
    assert_no_nonartifact_change_since(require_string(packet, "source_baseline", paths["packet"]), todo, delivery)
    task_id = require_string(packet, "task_id", paths["packet"])
    pending_obligations = state.get("pending_obligations")
    if not isinstance(pending_obligations, list) or not any(
        isinstance(item, dict) and item.get("task_id") == task_id and item.get("todo_line") == selected
        for item in pending_obligations
    ):
        raise ContractError("execution-state.json does not map the selected packet to a pending obligation")
    attempt = packet.get("attempt")
    if attempt not in ("implementation", "revision"):
        raise ContractError("current-worker-packet.json attempt must be implementation or revision")
    append_history(delivery, "planner_guard", {"task_id": task_id, "todo_line": selected, "attempt": attempt, "baseline_head": base})
    route("revise" if attempt == "revision" else "implement")


def route_worker(plan: Path) -> None:
    paths = delivery_paths(plan)
    packet = read_json(paths["packet"])
    result = read_json(paths["worker_result"])
    todo = paths["todo"]
    delivery = paths["delivery"]
    if result.get("schema_version") != SCHEMA_VERSION:
        raise ContractError("latest-worker-result.json schema version mismatch")
    for key in ("packet_id", "task_id", "todo_line"):
        if result.get(key) != packet.get(key):
            raise ContractError(f"Worker result {key} does not match current packet")
    if first_pending(todo) != packet.get("todo_line"):
        raise ContractError("Current todo first pending task no longer matches the worker packet")
    status = result.get("result")
    if status not in ("ready_for_review", "replan", "human_blocked"):
        raise ContractError("Worker result must be ready_for_review, replan or human_blocked")
    append_history(delivery, "worker_result", {"task_id": result["task_id"], "todo_line": result["todo_line"], "result": status})
    route({"ready_for_review": "review", "replan": "replan", "human_blocked": "human_blocked"}[status])


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] not in {"before-planner", "guard-planner", "route-worker"}:
        print("Usage: delivery_planner_state.py before-planner|guard-planner|route-worker PLAN_PATH", file=sys.stderr)
        return 2
    try:
        command = argv[1]
        plan = Path(argv[2])
        if command == "before-planner":
            before_planner(plan)
        elif command == "guard-planner":
            guard_planner(plan)
        else:
            route_worker(plan)
    except (ContractError, OSError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
