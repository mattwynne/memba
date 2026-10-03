#!/usr/bin/env python3
"""Run one approved BDD scenario against a prediction made before execution.

The planner can select a scenario and call its shot, but cannot edit feature files.
This command changes only scenario tags and records the observation. A surprising
failure goes back to the planner; neither a red scenario nor a green one accepts work.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Callable

TAG = re.compile(r"^\s*@[-\w.]+(?:\s+@[-\w.]+)*\s*$")
SCENARIO = re.compile(r"^\s*Scenario:\s*(.*?)\s*$")
Runner = Callable[[list[str]], subprocess.CompletedProcess[str]]


class ScenarioError(ValueError):
    pass


def read_object(path: Path) -> dict:
    try:
        value = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ScenarioError(f"Missing or invalid scenario artifact: {path}: {error}") from error
    if not isinstance(value, dict):
        raise ScenarioError(f"Expected object: {path}")
    return value


def write_object(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def tags(root: Path) -> list[tuple[Path, int]]:
    return [
        (file, index)
        for file in (root / "acceptance-tests/features").rglob("*.feature")
        for index, line in enumerate(file.read_text().splitlines())
        if TAG.fullmatch(line) and "@wip" in line.split()
    ]


def assert_no_wip(root: Path) -> None:
    found = tags(root)
    if found:
        raise ScenarioError("@wip scenario must be green and untagged before the final gate: " +
                            ", ".join(f"{path}:{index + 1}" for path, index in found))


def selection(root: Path, plan: Path, packet: dict) -> tuple[Path, str, str, int]:
    focus = packet.get("scenario_focus")
    if not isinstance(focus, dict):
        raise ScenarioError("scenario_focus must be an object")
    path, name, expected, after = (focus.get(key) for key in ("feature_path", "name", "predicted_failure", "predicted_after"))
    if not all(isinstance(value, str) and value.strip() for value in (path, name, expected, after)):
        raise ScenarioError("scenario_focus needs feature_path, name and two specific predictions")
    if len(expected.strip()) < 12 or (after != "green" and len(after.strip()) < 12):
        raise ScenarioError("Predictions must identify a specific diagnostic or the green outcome")
    if not path.startswith("acceptance-tests/features/") or not path.endswith(".feature"):
        raise ScenarioError("Scenario must be in acceptance-tests/features")
    feature = (root / path).resolve()
    if not feature.is_relative_to((root / "acceptance-tests/features").resolve()) or not feature.is_file():
        raise ScenarioError("Scenario feature path is missing or escapes the feature tree")
    permitted = plan.read_text().split("## Allowed acceptance feature changes", 1)
    if len(permitted) != 2 or f"`{path}`" not in permitted[1].split("\n## ", 1)[0]:
        raise ScenarioError("Approved plan does not permit edits to the selected feature")
    lines = feature.read_text().splitlines(keepends=True)
    matches = [index for index, line in enumerate(lines) if (match := SCENARIO.fullmatch(line.rstrip("\r\n"))) and match.group(1) == name]
    if len(matches) != 1:
        raise ScenarioError("Selected scenario must occur exactly once in the approved feature")
    index = matches[0]
    # Only a scenario's own tag line may be altered. Feature/Rule-wide @todo or
    # @journey tags cannot be silently changed to force this runner to select it.
    tag_index = index - 1 if index and TAG.fullmatch(lines[index - 1].rstrip("\r\n")) else index
    if any("@journey" in line.split() for line in lines[:index] if TAG.fullmatch(line.rstrip("\r\n"))):
        raise ScenarioError("Browser journeys need a separate focused runner; refusing a domain-only run")
    if any("@todo" in line.split() for line in lines[:tag_index] if TAG.fullmatch(line.rstrip("\r\n"))):
        raise ScenarioError("Cannot activate a feature- or rule-level @todo tag")
    return feature, name, expected, tag_index


def update_tag(feature: Path, index: int, *, activate: bool) -> None:
    lines = feature.read_text().splitlines(keepends=True)
    if activate:
        if TAG.fullmatch(lines[index].rstrip("\r\n")):
            tokens = lines[index].split()
            tokens = [tag for tag in tokens if tag != "@todo"]
            if "@wip" not in tokens:
                tokens.append("@wip")
            indent = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
            lines[index] = indent + " ".join(tokens) + "\n"
        else:
            indent = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
            lines.insert(index, indent + "@wip\n")
    else:
        if TAG.fullmatch(lines[index].rstrip("\r\n")):
            tokens = [tag for tag in lines[index].split() if tag != "@wip"]
            indent = lines[index][:len(lines[index]) - len(lines[index].lstrip())]
            if tokens:
                lines[index] = indent + " ".join(tokens) + "\n"
            else:
                lines.pop(index)
    feature.write_text("".join(lines))


def ensure_one_selected(output: str, name: str) -> None:
    summaries = list(re.finditer(r"(\d+) tests?, (\d+) failures?(?:, (\d+) excluded)?", output))
    match = summaries[-1] if summaries else None
    if not match or int(match.group(1)) - int(match.group(3) or 0) != 1:
        raise ScenarioError(f"Expected exactly one selected ExUnit scenario for {name}; check the tag filter and runner output")


def assert_trusted_before(root: Path, path: Path) -> None:
    relative = path.relative_to(root).as_posix()
    try:
        subject = subprocess.check_output(["git", "-C", str(root), "log", "-1", "--format=%s", "--", relative], text=True).strip()
        dirty = subprocess.check_output(["git", "-C", str(root), "status", "--porcelain", "--", relative], text=True).strip()
    except subprocess.CalledProcessError as error:
        raise ScenarioError("Cannot verify the saved call-shot checkpoint") from error
    if "call_shot_and_run_scenario" not in subject or dirty:
        raise ScenarioError("Pre-run prediction was edited outside the trusted call-shot checkpoint")


def run_scenario(root: Path, name: str, runner: Runner | None) -> tuple[list[str], subprocess.CompletedProcess[str]]:
    command = ["dev", "test", "test/features/domain_cucumber_acceptance_test.exs", "--only", f"scenario_name:{name}"]
    if runner is None:
        env = os.environ.copy()
        env["PATH"] = str(root / "bin") + os.pathsep + env.get("PATH", "")
        try:
            result = subprocess.run(command, cwd=root, env=env, text=True, capture_output=True, timeout=540)
        except subprocess.TimeoutExpired as error:
            raise ScenarioError(f"Focused scenario exceeded 540 seconds: {name}") from error
    else:
        result = runner(command)
    return command, result


def observe(root: Path, plan: Path, stage: str, runner: Runner | None = None) -> str:
    delivery = plan.parent / ".delivery"
    packet = read_object(delivery / "current-worker-packet.json")
    if not packet.get("scenario_focus"):
        if tags(root):
            raise ScenarioError("A pending @wip scenario cannot be abandoned for an unscoped worker packet")
        return "review" if stage == "after" else packet.get("attempt", "implementation").replace("implementation", "implement").replace("revision", "revise")
    feature, name, expected, index = selection(root, plan, packet)
    prior = delivery / "wip-before.json"
    if stage == "before":
        if prior.exists() and read_object(prior).get("packet_id") == packet.get("packet_id"):
            raise ScenarioError("This packet's prediction was already tested; refuse to rewrite it")
        active = tags(root)
        if active and (len(active) != 1 or active[0][0] != feature or active[0][1] != index):
            raise ScenarioError("Only one @wip scenario may be active at a time")
        update_tag(feature, index, activate=True)
        if len(tags(root)) != 1:
            raise ScenarioError("Only one @wip scenario may be active at a time")
        record = {"packet_id": packet["packet_id"], "feature_path": packet["scenario_focus"]["feature_path"],
                  "scenario_name": name, "predicted_failure": expected,
                  "predicted_after": packet["scenario_focus"]["predicted_after"], "recorded_at": int(time.time()),
                  "feature_sha256": hashlib.sha256(feature.read_bytes()).hexdigest(), "status": "pending"}
        write_object(prior, record)  # Immutable prediction exists before the test process starts.
    else:
        assert_trusted_before(root, prior)
        record = read_object(prior)
        if record.get("packet_id") != packet.get("packet_id") or record.get("status") != "predicted_red":
            raise ScenarioError("No matching predicted-red scenario baseline for this packet")
        if len(tags(root)) != 1 or tags(root)[0][0] != feature or hashlib.sha256(feature.read_bytes()).hexdigest() != record.get("feature_sha256"):
            raise ScenarioError("Worker changed the active feature or its tag before independent observation")
    command, result = run_scenario(root, name, runner)
    output = (result.stdout or "") + "\n" + (result.stderr or "")
    if runner is None:
        try:
            ensure_one_selected(output, name)
        except ScenarioError:
            if stage == "after":
                raise
            # An undefined/no-test selection is a surprise, not a predicted
            # business failure; persist its diagnostic for the planner.
            result = subprocess.CompletedProcess(command, result.returncode or 1, result.stdout, result.stderr)
            expected = "<no scenario was selected>"
    record.update({"command": command, "exit_status": result.returncode,
                   "output_tail": output[-12000:], "output_sha256": hashlib.sha256(output.encode()).hexdigest(),
                   "predicted_failure_still_present": expected in output,
                   "observed_at": int(time.time())})
    if stage == "before":
        record["status"] = "predicted_red" if result.returncode != 0 and expected in output else "surprise"
        if result.returncode == 0:
            update_tag(feature, index, activate=False)
        write_object(prior, record)
        return ("revise" if packet.get("attempt") == "revision" else "implement") if record["status"] == "predicted_red" else "replan"
    record["status"] = "green" if result.returncode == 0 else "red"
    record["prediction_matched"] = (record["predicted_after"] == "green" and result.returncode == 0) or (
        result.returncode != 0 and record["predicted_after"] != "green" and record["predicted_after"] in output
    )
    if result.returncode == 0:
        update_tag(feature, index, activate=False)
    write_object(delivery / "wip-after.json", record)
    return "review"


def before(root: Path, plan: Path, runner: Runner | None = None) -> str:
    return observe(root, plan, "before", runner)


def after(root: Path, plan: Path, runner: Runner | None = None) -> str:
    return observe(root, plan, "after", runner)


def main(argv: list[str]) -> int:
    if len(argv) != 3 or argv[1] not in ("before", "after", "final"):
        print("Usage: wip_scenario.py before|after|final PLAN_PATH", file=sys.stderr)
        return 2
    try:
        plan = Path(argv[2]).resolve()
        root = Path.cwd().resolve()
        if argv[1] == "final":
            assert_no_wip(root)
        else:
            label = before(root, plan) if argv[1] == "before" else after(root, plan)
            print(json.dumps({"preferred_next_label": label}))
    except (ScenarioError, OSError, KeyError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
