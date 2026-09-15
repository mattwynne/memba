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
PLANNER_OUTPUTS = {"execution-state.json", "current-worker-packet.json", "planner-result.json"}


class ContractError(RuntimeError):
    pass


def run_git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()


def plan_parts(plan: Path) -> tuple[Path, Path, Path]:
    if plan.name != "plan.md" or not plan.is_file():
        raise ContractError(f"Expected an existing plan.md: {plan}")
    iteration_dir = plan.parent
    return iteration_dir, iteration_dir / "todo.md", iteration_dir / ".delivery"


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


def read_json_if_present(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    return read_json(path)


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
    guard = delivery / "_guard"
    return {
        "todo": todo,
        "delivery": delivery,
        "guard_dir": guard,
        "baseline": guard / "planner-guard-baseline.json",
        "state": delivery / "execution-state.json",
        "packet": delivery / "current-worker-packet.json",
        "planner_result": delivery / "planner-result.json",
        "worker_result": delivery / "latest-worker-result.json",
        "review": delivery / "latest-review.json",
        "history": delivery / "history.jsonl",
    }


def planner_writable_path(path: str, todo: Path, delivery: Path) -> bool:
    if path == rel(todo):
        return True
    delivery_rel = rel(delivery)
    prefix = delivery_rel + "/"
    if not path.startswith(prefix):
        return False
    rest = path[len(prefix):]
    return "/" not in rest and rest in PLANNER_OUTPUTS


def changed_since(base: str) -> list[str]:
    if not base:
        raise ContractError("Missing baseline commit")
    try:
        run_git("cat-file", "-e", f"{base}^{{commit}}")
    except subprocess.CalledProcessError as error:
        raise ContractError(f"Baseline commit does not exist: {base}") from error
    names: set[str] = set()
    for args in (
        ("diff", "--name-only", f"{base}..HEAD"),
        ("diff", "--name-only"),
        ("diff", "--cached", "--name-only"),
        ("ls-files", "--others", "--exclude-standard"),
    ):
        out = run_git(*args)
        names.update(line for line in out.splitlines() if line)
    return sorted(
        name for name in names
        if "__pycache__/" not in name and not name.endswith((".pyc", ".pyo"))
    )


def require_string(data: dict[str, Any], key: str, path: Path) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ContractError(f"{path} requires non-empty string field {key}")
    return value


def require_list(data: dict[str, Any], key: str, path: Path) -> list[Any]:
    value = data.get(key)
    if not isinstance(value, list):
        raise ContractError(f"{path} requires list field {key}")
    return value


def require_string_list(data: dict[str, Any], key: str, path: Path, *, nonempty: bool = False) -> list[str]:
    value = require_list(data, key, path)
    if nonempty and not value:
        raise ContractError(f"{path} requires non-empty list field {key}")
    if not all(isinstance(item, str) and item.strip() for item in value):
        raise ContractError(f"{path} field {key} must contain non-empty strings")
    return value


def require_dict_list(data: dict[str, Any], key: str, path: Path, *, nonempty: bool = False) -> list[dict[str, Any]]:
    value = require_list(data, key, path)
    if nonempty and not value:
        raise ContractError(f"{path} requires non-empty list field {key}")
    if not all(isinstance(item, dict) for item in value):
        raise ContractError(f"{path} field {key} must contain objects")
    return value


def ensure_schema_version(data: dict[str, Any], path: Path) -> None:
    if data.get("schema_version") != SCHEMA_VERSION:
        raise ContractError(f"{path} schema version mismatch")


def validate_paths(data: dict[str, Any], path: Path, plan: Path, todo: Path) -> None:
    if data.get("plan_path") != rel(plan) or data.get("todo_path") != rel(todo):
        raise ContractError(f"{path} does not match this plan/todo path")


def valid_origin(origin: Any) -> bool:
    return isinstance(origin, dict) and all(
        isinstance(origin.get(key), str) and origin.get(key).strip()
        for key in ("packet_id", "task_id", "todo_line", "base_sha", "head_sha", "reason")
    )


def origin_key(origin: dict[str, Any]) -> tuple[str, str, str, str, str, str]:
    return tuple(origin[key] for key in ("packet_id", "task_id", "todo_line", "base_sha", "head_sha", "reason"))  # type: ignore[return-value]


def collect_required_candidate_origins(paths: dict[str, Path]) -> list[dict[str, Any]]:
    origins: list[dict[str, Any]] = []
    state = read_json_if_present(paths["state"])
    if state:
        for origin in state.get("candidate_origins", []):
            if isinstance(origin, dict):
                origins.append(origin)

    packet = read_json_if_present(paths["packet"])
    worker = read_json_if_present(paths["worker_result"])
    review = read_json_if_present(paths["review"])
    head = run_git("rev-parse", "HEAD")

    worker_matches = bool(packet and worker and all(
        worker.get(key) == packet.get(key) for key in ("packet_id", "task_id", "todo_line")
    ))
    review_matches = bool(packet and review and
        review.get("packet_id") == packet.get("packet_id") and
        review.get("task_id") == packet.get("task_id") and
        review.get("task") == packet.get("todo_line"))
    if review_matches and review.get("decision") == "accept" and (
        review["task"].replace("- [ ] ", "- [x] ", 1) in checked_lines(paths["todo"])
    ):
        # Acceptance retires only the reviewed provenance, and never a range
        # still assigned to another pending slice of the same candidate.
        pending = set(pending_lines(paths["todo"]))
        still_owned = {
            origin_key(origin)
            for obligation in (state or {}).get("pending_obligations", [])
            if obligation.get("todo_line") in pending
            for origin in obligation.get("candidate_origins", [])
            if valid_origin(origin)
        }
        accepted_origins = {
            origin_key(origin) for origin in review.get("candidate_origins", [])
            if valid_origin(origin)
        }
        origins = [origin for origin in origins
                   if origin_key(origin) not in accepted_origins or origin_key(origin) in still_owned]

    if packet and isinstance(packet.get("source_baseline"), str):
        if worker_matches and worker.get("result") == "replan":
            origins.append({
                "packet_id": str(packet.get("packet_id", "")),
                "task_id": str(packet.get("task_id", "")),
                "todo_line": str(packet.get("todo_line", "")),
                "base_sha": packet["source_baseline"],
                "head_sha": head,
                "reason": "worker_replan",
            })
        if review_matches and review.get("decision") == "revise":
            origins.append({
                "packet_id": str(packet.get("packet_id", "")),
                "task_id": str(packet.get("task_id", "")),
                "todo_line": str(packet.get("todo_line", "")),
                "base_sha": packet["source_baseline"],
                "head_sha": head,
                "reason": "review_revise",
            })

    deduped: dict[tuple[str, str, str, str, str, str], dict[str, Any]] = {}
    for origin in origins:
        if valid_origin(origin):
            deduped[origin_key(origin)] = origin
    return list(deduped.values())


def before_planner(plan: Path) -> None:
    paths = delivery_paths(plan)
    todo = paths["todo"]
    if not todo.is_file():
        raise ContractError(f"Todo file missing before planner: {todo}")
    baseline = {
        "schema_version": SCHEMA_VERSION,
        "plan_path": rel(plan),
        "todo_path": rel(todo),
        "pre_planner_head": run_git("rev-parse", "HEAD"),
        "plan_sha256": file_sha(plan),
        "accepted_tasks": checked_lines(todo),
        "pending_before": pending_lines(todo),
        "previous_packet_id": (read_json_if_present(paths["packet"]) or {}).get("packet_id"),
        "required_candidate_origins": collect_required_candidate_origins(paths),
        "created_by": "before_delivery_planner",
        "created_at": int(time.time()),
    }
    write_json(paths["baseline"], baseline)
    print(f"Delivery planner baseline captured from {baseline['pre_planner_head']} in {paths['baseline']}")


def baseline_binding_head(path: Path) -> str:
    rel_path = rel(path)
    try:
        commit = run_git("log", "-1", "--format=%H", "--", rel_path)
        subject = run_git("log", "-1", "--format=%s", "--", rel_path)
    except subprocess.CalledProcessError as error:
        raise ContractError(f"Planner guard baseline is not committed: {path}") from error
    if not commit:
        raise ContractError(f"Planner guard baseline is not committed: {path}")
    if "before_delivery_planner" not in subject and "Snapshot Before Delivery Planner" not in subject:
        raise ContractError("Planner guard baseline was modified outside the trusted before-planner checkpoint")
    return commit


def validate_baseline(paths: dict[str, Path], plan: Path, todo: Path) -> dict[str, Any]:
    baseline = read_json(paths["baseline"])
    ensure_schema_version(baseline, paths["baseline"])
    validate_paths(baseline, paths["baseline"], plan, todo)
    if baseline.get("plan_sha256") != file_sha(plan):
        raise ContractError("Planner changed the approved plan.md; stopping")
    require_string(baseline, "pre_planner_head", paths["baseline"])
    if baseline.get("created_by") != "before_delivery_planner":
        raise ContractError("Planner baseline was not created by before_delivery_planner")
    baseline["binding_head"] = baseline_binding_head(paths["baseline"])
    accepted = require_string_list(baseline, "accepted_tasks", paths["baseline"])
    pending = require_string_list(baseline, "pending_before", paths["baseline"])
    if not all(CHECKED.fullmatch(line) for line in accepted):
        raise ContractError("Planner baseline accepted_tasks must contain checked todo lines")
    if not all(PENDING.fullmatch(line) for line in pending):
        raise ContractError("Planner baseline pending_before must contain unchecked todo lines")
    origins = require_list(baseline, "required_candidate_origins", paths["baseline"])
    if not all(valid_origin(origin) for origin in origins):
        raise ContractError("Planner baseline required_candidate_origins are malformed")
    return baseline


def assert_planner_file_boundary(base: str, todo: Path, delivery: Path) -> None:
    disallowed = [path for path in changed_since(base) if not planner_writable_path(path, todo, delivery)]
    if disallowed:
        raise ContractError("Delivery planner may only change todo.md and declared planner artifacts; changed: " + ", ".join(disallowed))


def validate_planner_result(paths: dict[str, Path], plan: Path, todo: Path, base: str) -> dict[str, Any]:
    result = read_json(paths["planner_result"])
    ensure_schema_version(result, paths["planner_result"])
    validate_paths(result, paths["planner_result"], plan, todo)
    if result.get("source_baseline") != base:
        raise ContractError("planner-result source_baseline must equal the guarded planner baseline")
    decision = result.get("decision")
    if decision not in ("ready", "all_done", "human_blocked"):
        raise ContractError("planner-result decision must be ready, all_done or human_blocked")
    if decision == "human_blocked":
        require_string(result, "actionable_reason", paths["planner_result"])
    else:
        if "actionable_reason" in result and not isinstance(result["actionable_reason"], str):
            raise ContractError("planner-result actionable_reason must be a string when present")
    return result


def validate_state(paths: dict[str, Path], plan: Path, todo: Path, baseline: dict[str, Any]) -> dict[str, Any]:
    state = read_json(paths["state"])
    ensure_schema_version(state, paths["state"])
    validate_paths(state, paths["state"], plan, todo)
    base = require_string(baseline, "binding_head", paths["baseline"])
    if state.get("source_baseline") != base:
        raise ContractError("execution-state source_baseline must equal the guarded planner baseline")

    current_checked = checked_lines(todo)
    if current_checked != baseline["accepted_tasks"]:
        raise ContractError("Delivery planner may not add, remove or change checked accepted todo lines")
    accepted_tasks = require_string_list(state, "accepted_tasks", paths["state"])
    if accepted_tasks != current_checked:
        raise ContractError("execution-state accepted_tasks must exactly match current checked todo lines")

    pending_obligations = require_dict_list(state, "pending_obligations", paths["state"])
    task_ids: set[str] = set()
    obligation_by_line: dict[str, dict[str, Any]] = {}
    replaced_lines: set[str] = set()
    for index, obligation in enumerate(pending_obligations):
        task_id = require_string(obligation, "task_id", paths["state"])
        if task_id in task_ids:
            raise ContractError(f"Duplicate pending obligation task_id: {task_id}")
        task_ids.add(task_id)
        todo_line = require_string(obligation, "todo_line", paths["state"])
        if not PENDING.fullmatch(todo_line):
            raise ContractError(f"Pending obligation {task_id} todo_line must be an unchecked todo line")
        if todo_line in obligation_by_line:
            raise ContractError(f"Duplicate pending obligation for todo line: {todo_line}")
        obligation_by_line[todo_line] = obligation
        require_string(obligation, "origin", paths["state"])
        status = obligation.get("status")
        if status not in ("pending", "prepared", "blocked"):
            raise ContractError(f"Pending obligation {task_id} has invalid status")
        require_string_list(obligation, "coverage", paths["state"], nonempty=True)
        for replaced in require_string_list(obligation, "replaces", paths["state"]):
            if not PENDING.fullmatch(replaced):
                raise ContractError(f"Pending obligation {task_id} replaces must contain unchecked todo lines")
            replaced_lines.add(replaced)
        origins = obligation.get("candidate_origins", [])
        if not isinstance(origins, list) or not all(valid_origin(origin) for origin in origins):
            raise ContractError(f"Pending obligation {task_id} candidate_origins are malformed")

    current_pending = pending_lines(todo)
    if set(obligation_by_line) != set(current_pending):
        raise ContractError("execution-state pending_obligations must cover every current unchecked todo line exactly")

    missing_lineage = [line for line in baseline["pending_before"] if line not in current_pending and line not in replaced_lines]
    if missing_lineage:
        raise ContractError("Planner removed pending obligations without explicit lineage: " + "; ".join(missing_lineage))

    candidate_origins = state.get("candidate_origins", [])
    if not isinstance(candidate_origins, list) or not all(valid_origin(origin) for origin in candidate_origins):
        raise ContractError("execution-state candidate_origins are malformed")
    required_origin_keys = {origin_key(origin) for origin in baseline["required_candidate_origins"]}
    state_origin_keys = {origin_key(origin) for origin in candidate_origins}
    if not required_origin_keys.issubset(state_origin_keys):
        raise ContractError("execution-state dropped unaccepted candidate provenance")
    assigned_origins = {
        origin_key(origin)
        for obligation in pending_obligations
        for origin in obligation.get("candidate_origins", [])
    }
    if state_origin_keys != assigned_origins:
        raise ContractError("Unaccepted candidate provenance must be assigned to pending obligations exactly")
    for obligation in pending_obligations:
        for origin in obligation.get("candidate_origins", []):
            if (origin["task_id"] != obligation["task_id"] and
                origin["todo_line"] != obligation["todo_line"] and
                origin["todo_line"] not in obligation["replaces"]):
                raise ContractError("Candidate provenance assignment requires explicit task lineage")

    coverage = require_dict_list(state, "coverage_map", paths["state"])
    covered_task_ids: set[str] = set()
    covered_accepted: set[str] = set()
    for item in coverage:
        require_string(item, "scope", paths["state"])
        for task_id in require_string_list(item, "pending_task_ids", paths["state"]):
            if task_id not in task_ids:
                raise ContractError(f"coverage_map references unknown pending task_id: {task_id}")
            covered_task_ids.add(task_id)
        for line in require_string_list(item, "accepted_task_lines", paths["state"]):
            if line not in current_checked:
                raise ContractError(f"coverage_map references unknown accepted task line: {line}")
            covered_accepted.add(line)
    if task_ids and not task_ids.issubset(covered_task_ids):
        raise ContractError("coverage_map must reference every pending task_id")
    if current_checked and not set(current_checked).issubset(covered_accepted):
        raise ContractError("coverage_map must reference every accepted task line")
    require_string(state, "planner_note", paths["state"])
    return state


def validate_packet(paths: dict[str, Path], plan: Path, todo: Path, base: str, state: dict[str, Any], selected: str) -> dict[str, Any]:
    packet = read_json(paths["packet"])
    ensure_schema_version(packet, paths["packet"])
    validate_paths(packet, paths["packet"], plan, todo)
    if packet.get("todo_line") != selected:
        raise ContractError(
            "Worker packet task does not match the first pending todo line: "
            f"packet={packet.get('todo_line')!r}, first_pending={selected!r}"
        )
    if packet.get("source_baseline") != base:
        raise ContractError("Worker packet source_baseline must equal the guarded planner baseline")
    for key in ("packet_id", "task_id", "outcome"):
        require_string(packet, key, paths["packet"])
    attempt = packet.get("attempt")
    if attempt not in ("implementation", "revision"):
        raise ContractError("current-worker-packet.json attempt must be implementation or revision")
    for key in ("scope", "focused_validation", "completion_evidence_required"):
        require_string_list(packet, key, paths["packet"], nonempty=True)
    for key in ("scope_exclusions", "constraints"):
        require_string_list(packet, key, paths["packet"])
    refs = require_dict_list(packet, "references", paths["packet"], nonempty=True)
    for ref in refs:
        require_string(ref, "path", paths["packet"])
        require_string(ref, "facts", paths["packet"])
    origins = packet.get("candidate_origins", [])
    if not isinstance(origins, list) or not all(valid_origin(origin) for origin in origins):
        raise ContractError("current-worker-packet candidate_origins are malformed")

    task_id = packet["task_id"]
    pending_obligations = state["pending_obligations"]
    matches = [item for item in pending_obligations if item.get("task_id") == task_id and item.get("todo_line") == selected]
    if len(matches) != 1:
        raise ContractError("execution-state does not map the selected packet to exactly one pending obligation")
    obligation_origins = {origin_key(origin) for origin in matches[0].get("candidate_origins", [])}
    packet_origins = {origin_key(origin) for origin in origins}
    if obligation_origins != packet_origins:
        raise ContractError("current-worker-packet must match selected obligation candidate provenance exactly")
    return packet


def latest_unaccepted_revision(paths: dict[str, Path], accepted_tasks: list[str]) -> dict[str, Any] | None:
    review = read_json_if_present(paths["review"])
    if not review or review.get("decision") != "revise":
        return None
    if review.get("task", "").replace("- [ ] ", "- [x] ", 1) in accepted_tasks:
        return None
    for key in ("packet_id", "task_id", "task", "reason"):
        require_string(review, key, paths["review"])
    return review


def guard_planner(plan: Path) -> None:
    paths = delivery_paths(plan)
    todo = paths["todo"]
    delivery = paths["delivery"]
    baseline = validate_baseline(paths, plan, todo)
    base = baseline["binding_head"]
    assert_planner_file_boundary(base, todo, delivery)
    result = validate_planner_result(paths, plan, todo, base)
    state = validate_state(paths, plan, todo, baseline)

    selected = first_pending(todo)
    if result["decision"] == "human_blocked":
        append_history(delivery, "planner_human_blocked", {"reason": result["actionable_reason"], "baseline_head": base})
        route("human_blocked")
        return
    if result["decision"] == "all_done":
        if selected is not None or baseline["pending_before"] or state["pending_obligations"]:
            raise ContractError("Planner may report all_done only when no pending obligations existed or remain")
        route("all_done")
        return
    if result["decision"] != "ready":
        raise ContractError("Planner result decision does not match a routable state")
    if selected is None:
        raise ContractError("Planner reported ready but no pending todo line remains")

    packet = validate_packet(paths, plan, todo, base, state, selected)
    if packet["packet_id"] == baseline.get("previous_packet_id"):
        raise ContractError("Each preparation requires a new packet_id; previous worker evidence cannot be reused")
    review = latest_unaccepted_revision(paths, baseline["accepted_tasks"])
    if review:
        if packet["attempt"] != "revision":
            raise ContractError("Latest unaccepted review requested revision; packet must route to bounded revision")
        if packet["task_id"] != review["task_id"]:
            raise ContractError("Revision packet task_id must match the latest unaccepted review")
        if packet["todo_line"] != review["task"]:
            replaces = []
            for obligation in state["pending_obligations"]:
                if obligation.get("task_id") == packet["task_id"]:
                    replaces = obligation.get("replaces", [])
                    break
            if review["task"] not in replaces:
                raise ContractError("Revision packet must retain lineage to the reviewed todo line")

    append_history(delivery, "planner_guard", {"task_id": packet["task_id"], "todo_line": selected, "attempt": packet["attempt"], "baseline_head": base})
    route("revise" if packet["attempt"] == "revision" else "implement")


def validate_worker_result(
    paths: dict[str, Path], todo: Path, *, allow_accepted_packet: bool = False
) -> tuple[dict[str, Any], dict[str, Any]]:
    packet = read_json(paths["packet"])
    ensure_schema_version(packet, paths["packet"])
    result = read_json(paths["worker_result"])
    ensure_schema_version(result, paths["worker_result"])
    for key in ("packet_id", "task_id", "todo_line"):
        if not isinstance(packet.get(key), str) or not packet.get(key).strip():
            raise ContractError(f"Current packet missing required {key}")
        if result.get(key) != packet.get(key):
            raise ContractError(f"Worker result {key} does not match current packet")
    if first_pending(todo) != packet.get("todo_line"):
        accepted_line = str(packet.get("todo_line", "")).replace("- [ ] ", "- [x] ", 1)
        if not allow_accepted_packet or accepted_line not in checked_lines(todo):
            raise ContractError("Reviewed task is not the first pending task in the current todo")
    status = result.get("result")
    if status not in ("ready_for_review", "replan", "human_blocked"):
        raise ContractError("Worker result must be ready_for_review, replan or human_blocked")
    require_string_list(result, "changed_paths", paths["worker_result"])
    require_string(result, "notes", paths["worker_result"])
    unresolved = result.get("unresolved")
    if not isinstance(unresolved, list):
        raise ContractError("Worker result unresolved must be a list")
    validation = require_dict_list(result, "validation", paths["worker_result"])
    if status == "ready_for_review" and not validation:
        raise ContractError("ready_for_review worker result requires validation evidence")
    for item in validation:
        require_string(item, "command", paths["worker_result"])
        if not isinstance(item.get("exit_status"), int):
            raise ContractError("Worker validation entries require integer exit_status")
        require_string(item, "evidence", paths["worker_result"])
    if status == "ready_for_review" and any(item["exit_status"] != 0 for item in validation):
        raise ContractError("ready_for_review requires every validation command to pass")
    if status == "replan":
        request = result.get("replan_request")
        if not isinstance(request, dict):
            raise ContractError("replan worker result requires replan_request")
        require_string(request, "blocker", paths["worker_result"])
        for key in ("partial_work", "completed_checks", "remaining_validation"):
            require_string_list(request, key, paths["worker_result"])
    if status == "human_blocked":
        require_string(result, "human_blocked_reason", paths["worker_result"])
    return packet, result


def route_worker(plan: Path) -> None:
    paths = delivery_paths(plan)
    packet, result = validate_worker_result(paths, paths["todo"])
    delivery = paths["delivery"]
    status = result["result"]
    append_history(delivery, "worker_result", {"packet_id": packet["packet_id"], "task_id": result["task_id"], "todo_line": result["todo_line"], "result": status})
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
