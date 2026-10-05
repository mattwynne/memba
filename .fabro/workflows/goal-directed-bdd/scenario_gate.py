#!/usr/bin/env python3
"""Non-publishing, single-scenario BDD pilot gate. Never accepts model claims as test results."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

TAG = re.compile(r"^\s*@[-\w.]+(?:\s+@[-\w.]+)*\s*$")
SCENARIO = re.compile(r"^\s*Scenario:\s*(.*?)\s*$")
TESTS = re.compile(r"(\d+) tests?, (\d+) failures?(?:, (\d+) excluded)?")
FEATURE = "acceptance-tests/features/custom_group_access_requests.feature"
NAME = "Eve asks to join Board"


class GateError(ValueError):
    pass


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def artifact(plan: Path, name: str) -> Path:
    return plan.parent / ".delivery" / "goal-directed-bdd" / name


def load(path: Path) -> dict:
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        raise GateError(f"Expected an object: {path}")
    return value


def save(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def selected_feature(root: Path, plan: Path) -> tuple[Path, int]:
    if not plan.is_file():
        raise GateError("Approved plan is missing")
    permitted = plan.read_text().split("## Allowed acceptance feature changes", 1)
    if len(permitted) != 2 or f"`{FEATURE}`" not in permitted[1].split("\n## ", 1)[0]:
        raise GateError("Approved plan does not permit this feature")
    feature = (root / FEATURE).resolve()
    if not feature.is_relative_to((root / "acceptance-tests/features").resolve()) or not feature.is_file():
        raise GateError("Feature missing or outside acceptance tree")
    lines = feature.read_text().splitlines(keepends=True)
    matching = [i for i, line in enumerate(lines) if (match := SCENARIO.fullmatch(line.rstrip("\r\n"))) and match.group(1) == NAME]
    if len(matching) != 1:
        raise GateError("Expected exactly one approved scenario")
    index = matching[0]
    tag_index = index - 1 if index and TAG.fullmatch(lines[index - 1].rstrip("\r\n")) else index
    for line in lines[:tag_index]:
        if TAG.fullmatch(line.rstrip("\r\n")) and ("@todo" in line.split() or "@journey" in line.split()):
            raise GateError("Feature/rule @todo or browser journey cannot be selected by this domain runner")
    return feature, tag_index


def active_wip(root: Path) -> list[tuple[Path, int]]:
    return [(path, i) for path in (root / "acceptance-tests/features").rglob("*.feature")
            for i, line in enumerate(path.read_text().splitlines())
            if TAG.fullmatch(line) and "@wip" in line.split()]


def tag(feature: Path, index: int, *, activate: bool) -> None:
    lines = feature.read_text().splitlines(keepends=True)
    line = lines[index]
    if TAG.fullmatch(line.rstrip("\r\n")):
        tokens = [token for token in line.split() if token not in (("@todo", "@wip") if activate else ("@wip",))]
        if activate:
            tokens.append("@wip")
        indent = line[: len(line) - len(line.lstrip())]
        if tokens:
            lines[index] = indent + " ".join(tokens) + "\n"
        else:
            lines.pop(index)
    elif activate:
        indent = line[: len(line) - len(line.lstrip())]
        lines.insert(index, indent + "@wip\n")
    else:
        raise GateError("Missing @wip tag")
    feature.write_text("".join(lines))


def run(root: Path) -> tuple[int, str]:
    command = ["dev", "test", "test/features/domain_cucumber_acceptance_test.exs", "--only", f"scenario_name:{NAME}"]
    env = os.environ.copy()
    env["PATH"] = str(root / "bin") + os.pathsep + env.get("PATH", "")
    try:
        result = subprocess.run(command, cwd=root, env=env, text=True, capture_output=True, timeout=540)
    except subprocess.TimeoutExpired as error:
        raise GateError("Focused scenario timed out; not an intended red") from error
    output = (result.stdout or "") + "\n" + (result.stderr or "")
    return result.returncode, output


def ensure_one(output: str) -> None:
    summaries = list(TESTS.finditer(output))
    if not summaries or int(summaries[-1].group(1)) - int(summaries[-1].group(3) or 0) != 1:
        raise GateError("Expected exactly one selected scenario; zero/ambiguous tests cannot pass the gate")


def before(root: Path, plan: Path, shot: dict) -> None:
    feature, index = selected_feature(root, plan)
    expected = shot.get("predicted_failure")
    if not isinstance(expected, str) or len(expected.strip()) < 16:
        raise GateError("A specific predicted failure must be recorded before the first run")
    if active_wip(root) or artifact(plan, "before.json").exists():
        raise GateError("Pilot must start with no active or previously tested @wip scenario")
    tag(feature, index, activate=True)
    record = {"scenario": NAME, "feature": FEATURE, "predicted_failure": expected,
              "feature_sha256": sha(feature.read_bytes()), "status": "pending"}
    save(artifact(plan, "before.json"), record)  # Written before executing the scenario.
    code, output = run(root)
    ensure_one(output)
    record.update(exit_status=code, output_sha256=sha(output.encode()), output_tail=output[-12000:])
    if "No matching step definition" in output or "No scenarios" in output:
        record["status"] = "harness_failure"
    elif code != 0 and expected in output:
        record["status"] = "predicted_red"
    else:
        record["status"] = "surprise"
    save(artifact(plan, "before.json"), record)
    if record["status"] != "predicted_red":
        raise GateError(f"Scenario did not fail for the predicted behaviour: {record['status']}; {output[-1200:]}")
    print(json.dumps({"preferred_next_label": "implement"}))


def trusted_before(root: Path, plan: Path) -> None:
    path = artifact(plan, "before.json").relative_to(root).as_posix()
    subject = subprocess.check_output(["git", "log", "-1", "--format=%s", "--", path], cwd=root, text=True).strip()
    dirty = subprocess.check_output(["git", "status", "--porcelain", "--", path], cwd=root, text=True).strip()
    if "observe_predicted_red" not in subject or dirty:
        raise GateError("Predicted-red evidence was not preserved by the trusted gate checkpoint")


def resume(root: Path, plan: Path) -> None:
    prior = artifact(plan, "before.json")
    if not prior.exists():
        if active_wip(root):
            raise GateError("Active @wip has no trusted predicted-red checkpoint")
        print(json.dumps({"preferred_next_label": "new"}))
        return
    trusted_before(root, plan)
    record = load(prior)
    feature, index = selected_feature(root, plan)
    if (record.get("status") != "predicted_red" or record.get("scenario") != NAME
            or active_wip(root) != [(feature, index)]
            or sha(feature.read_bytes()) != record.get("feature_sha256")):
        raise GateError("Cannot resume missing/stale @wip red evidence")
    print(json.dumps({"preferred_next_label": "resume"}))


def after(root: Path, plan: Path) -> None:
    trusted_before(root, plan)
    record = load(artifact(plan, "before.json"))
    if record.get("status") != "predicted_red" or record.get("scenario") != NAME:
        raise GateError("No recorded intended red; cannot review or implement")
    feature, index = selected_feature(root, plan)
    if active_wip(root) != [(feature, index)] or sha(feature.read_bytes()) != record["feature_sha256"]:
        raise GateError("Worker changed or removed the active scenario before its observed green")
    code, output = run(root)
    ensure_one(output)
    save(artifact(plan, "after.json"), {"scenario": NAME, "feature_sha256": record["feature_sha256"],
         "status": "green" if code == 0 else "red", "exit_status": code,
         "output_sha256": sha(output.encode()), "output_tail": output[-12000:]})
    print(json.dumps({"preferred_next_label": "review" if code == 0 else "rework"}))


def verdict(root: Path, plan: Path, review: dict) -> None:
    trusted_before(root, plan)
    before_record = load(artifact(plan, "before.json"))
    after_record = load(artifact(plan, "after.json"))
    feature, index = selected_feature(root, plan)
    if (before_record.get("status") != "predicted_red" or after_record.get("status") != "green"
            or before_record["feature_sha256"] != after_record["feature_sha256"]
            or sha(feature.read_bytes()) != before_record["feature_sha256"]
            or active_wip(root) != [(feature, index)]):
        raise GateError("Review cannot accept missing/stale red, green or @wip evidence")
    decision = review.get("decision")
    if decision not in ("accept", "revise", "blocked") or not isinstance(review.get("reason"), str) or not review["reason"].strip():
        raise GateError("Review needs a structured decision and reason")
    save(artifact(plan, "review.json"), review)
    if decision == "accept":
        tag(feature, index, activate=False)
        save(artifact(plan, "accepted.json"), {"scenario": NAME, "before_sha256": before_record["output_sha256"],
             "after_sha256": after_record["output_sha256"], "decision": decision})
    print(json.dumps({"preferred_next_label": decision}))


def final(root: Path, plan: Path) -> None:
    if active_wip(root):
        raise GateError("@wip remains; no final gate or publication")
    accepted = load(artifact(plan, "accepted.json"))
    if accepted.get("decision") != "accept" or accepted.get("scenario") != NAME:
        raise GateError("The focused scenario was not independently accepted")
    # This pilot covers one bounded scenario, not the entire old iteration.
    print("Non-publishing historical scenario pilot complete; whole-iteration plan conformance not claimed.")


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] not in ("resume", "before", "after", "verdict", "final"):
        print("Usage: scenario_gate.py resume|before|after|verdict|final PLAN_PATH", file=sys.stderr)
        return 2
    try:
        root = Path.cwd().resolve()
        plan = (root / argv[2]).resolve()
        if not plan.is_relative_to(root / "docs/iterations"):
            raise GateError("Plan must be in docs/iterations")
        if argv[1] == "resume":
            resume(root, plan)
        elif argv[1] == "before":
            before(root, plan, json.load(sys.stdin))
        elif argv[1] == "after":
            after(root, plan)
        elif argv[1] == "verdict":
            verdict(root, plan, json.load(sys.stdin))
        else:
            final(root, plan)
    except (GateError, OSError, KeyError, json.JSONDecodeError, subprocess.CalledProcessError) as error:
        print(f"BDD pilot stopped: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
