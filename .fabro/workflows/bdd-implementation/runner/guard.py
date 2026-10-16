"""Runtime-unvalidated draft: sandbox guards/source-bound observations, NOT an agent adapter.

Fabro owns inference, sessions, command logs, artifacts, checkpoints and Docker.
Only latest handoff facts live here; there is no recovery/session/receipt service.
"""
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import sys

ROOT = Path.cwd().resolve()
HERE = ".fabro/workflows/bdd-implementation/runner/guard.py"
TMP = ROOT / ".fabro/tmp/bdd-implementation"
STATE = TMP / "state.json"
ROLES = {"bdd_navigator", "bdd_driver", "refactoring_navigator", "refactoring_driver", "review"}
DRIVERS = {"bdd_driver", "refactoring_driver"}
READ_TOOLS = {"read_file", "read_many_files", "grep", "glob", "list_dir", "update_plan"}


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def read(path):
    return json.loads(Path(path).read_text())


def write(path, value):
    temporary = Path(str(path) + "." + str(os.getpid()) + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT)


def path_in_repo(value):
    path = (ROOT / value).resolve()
    require(path.is_relative_to(ROOT) and path != ROOT, "Path must be inside source checkout")
    require(".git" not in path.relative_to(ROOT).parts, "No Git internals")
    return path


def source():
    # Checkpoint SHA alone would stale unchanged test evidence after every node.
    # Hash actual tracked + nonignored new source bytes and executable/symlink modes.
    names = git("ls-files", "-z", "--cached", "--others", "--exclude-standard").split(b"\0")
    digest = hashlib.sha256()
    for raw in sorted(set(names) - {b""}):
        name = os.fsdecode(raw)
        if name.startswith((".fabro/tmp/", ".fabro/blobs/")):
            continue
        p = ROOT / name
        digest.update(raw + b"\0")
        if not p.exists() and not p.is_symlink():
            digest.update(b"deleted\0")
            continue
        mode = p.lstat().st_mode
        require(stat.S_ISREG(mode) or stat.S_ISLNK(mode), "Unsupported source file kind")
        digest.update(str(stat.S_IMODE(mode)).encode() + b"\0")
        digest.update(os.fsencode(os.readlink(p)) if p.is_symlink() else p.read_bytes())
    return digest.hexdigest()


def image_metadata():
    return {key: os.environ.get("MEMBA_FABRO_IMAGE_" + key) for key in ("VERSION", "SOURCE", "BUILD")}


def load():
    s = read(STATE)
    require(read(TMP / "boot.json")["run_id"] == s["run_id"], "Run ownership mismatch")
    require(s["image_metadata"] == image_metadata(), "Runtime image metadata changed; old test results cannot be reused")
    return s


def limits(s, spend=False):
    require(dt.datetime.now(dt.timezone.utc) < dt.datetime.fromisoformat(s["facts"]["deadline_utc"].replace("Z", "+00:00")), "Original deadline exhausted; preserve work")
    if spend:
        s["operations"] += 1
    require(s["operations"] <= s["facts"]["aggregate_operations"], "Original aggregate allowance exhausted")
    write(STATE, s)


def route(label):
    print(json.dumps({"preferred_next_label": label}))


def current_green(s):
    e = s.get("tests", {}).get("acceptance", {})
    return e.get("source") == source() and e.get("status") == "passed"


def selected(s):
    a = s.get("assignment", {})
    return ["acceptance", *a.get("units", []), *a.get("earlier", [])]


def checks_green(s):
    now = source()
    return all(s.get("tests", {}).get(k, {}).get("source") == now and s["tests"][k]["status"] == "passed" for k in selected(s))


def matches(actual, prediction):
    if prediction.get("status") == "passed":
        return actual["status"] == "passed"
    return (actual["status"] == prediction.get("status") and actual.get("step") == prediction.get("step")
            and (actual["status"] == "undefined" or bool(prediction.get("error_contains"))
                 and prediction["error_contains"] in actual.get("error", "")))


def prediction(p):
    require(isinstance(p, dict) and p.get("reason") and p.get("status") in {"passed", "failed", "undefined"}, "Predict status and causal reason before testing")
    if p["status"] != "passed":
        require(p.get("step") and (p["status"] == "undefined" or p.get("error_contains")), "Predict the exact failing step and stable assertion/error, not an incidental phrase")


def run(s, argv, label):
    limits(s, spend=True)
    before = source()
    s["serial"] += 1
    stem = TMP / str(s["serial"])
    print(json.dumps({"command": argv, "source": before, "head": git("rev-parse", "HEAD").decode().strip(), "setup": s["facts"]["setup_id"], "log": str(stem) + ".log"}), flush=True)
    remaining = (dt.datetime.fromisoformat(s["facts"]["deadline_utc"].replace("Z", "+00:00")) - dt.datetime.now(dt.timezone.utc)).total_seconds()
    with open(str(stem) + ".log", "w") as log:
        try:
            result = subprocess.run(argv, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=max(1, min(2200, remaining)))
            code = result.returncode
        except subprocess.TimeoutExpired:
            raise ValueError("Command timed out; preserve work/log, do not infer a test result")
    text = Path(str(stem) + ".log").read_text(errors="replace")
    print(text, flush=True)
    e = {"command": argv, "source": before, "source_after": source(), "exit": code, "log": str(stem) + ".log", "label": label, "setup": s["facts"]["setup_id"], "image_metadata": s.get("image_metadata")}
    return e, text


def exunit_counts(text):
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    matches = re.findall(r"^(?:\d+ (?:doctests?|properties), )*(\d+) tests?, (\d+) failures?(?:, (\d+) excluded)?(?:, (\d+) skipped)?\s*$", text, re.M)
    require(matches, "No actual ExUnit summary")
    counts = [{"total": int(n), "failures": int(f), "excluded": int(x or 0), "skipped": int(k or 0)} for n, f, x, k in matches]
    require(all(c["total"] - c["excluded"] > 0 and c["skipped"] == 0 for c in counts), "Zero selected or skipped ExUnit tests")
    return counts


def domain_result(text, code, feature, name):
    # Same real ExUnit selection/count boundary as the private prototype, not
    # Cucumber-JS and not a fabricated JSON report. --trace identifies the test.
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    counts = exunit_counts(text)
    require(len(counts) == 1 and counts[0]["total"] - counts[0]["excluded"] == 1, "Exactly one selected domain example must execute")
    require(f'scenario_name: {json.dumps(name, ensure_ascii=False)}' in text and f'test {Path(feature).name}: {name}' in text, "Wrong/missing actual domain scenario trace/tag")
    require(not re.search(r"__ex_unit_setup|setup_all callback|Compilation error|DBConnection\.(?:Connection|Ownership)Error|ExUnit.TimeoutError|Before (?:step )?hook.*failed", text), "Infrastructure/setup failure is not product red")
    result = {"counts": counts, "feature": feature, "scenario": name}
    if code == 0:
        require(counts[0]["failures"] == 0, "Contradictory domain green")
        return dict(result, status="passed")
    require(code == 2 and counts[0]["failures"] == 1, "Non-test exit is not an acceptance result")
    missing = "No matching step definition found for step:"
    failure = re.search(r"\*\* \(Cucumber.StepError\) (No matching step definition found for step:|Step failed:)", text)
    require(failure, "Unsupported domain failure shape; inspect raw output, never improvise a result")
    marker = failure[1]
    step = re.search(re.escape(marker) + r"\s*\n\s*\n\s*(?:Given|When|Then|And|But|\*)\s+([^\n]+)", text[failure.start():])
    require(step, "No actual failing domain step in error output")
    require(f'in scenario "{name}"' in text and feature.removeprefix("acceptance-tests/") in text, "Failure belongs to another example")
    # Keep causal assertion details, not source line numbers or prior step history.
    body = text[failure.end():]
    body = re.split(r"\n\s*(?:Step execution history:|code: DomainCucumberRunner|stacktrace:)", body)[0]
    error = missing if marker == missing else re.split(r'matching pattern: "[^\n]*"\s*\n', body, maxsplit=1)[-1].strip()
    return dict(result, status="undefined" if marker == missing else "failed", step=step[1].strip(), error=error)


def observe_one(s, key, p):
    unit = key.startswith("web/test/")
    if unit:
        require(p.get("status") in {"passed", "failed"} and p.get("reason"), "Predict unit result and reason before testing")
        require(re.fullmatch(r"web/test/[A-Za-z0-9_/-]+_test\.exs(?::[1-9][0-9]*)?", key) and key.split(":")[0] != "web/test/features/domain_cucumber_acceptance_test.exs", "Use focused web units; the domain suite requires exact named-example selection")
        argv = ["bin/dev", "test", key.removeprefix("web/")]
    else:
        prediction(p)
        if key == "acceptance":
            feature, name = s["facts"]["feature"], s["facts"]["scenario"]
        else:
            require(re.fullmatch(r"domain:acceptance-tests/features/[A-Za-z0-9_/-]+\.feature::[^\r\n]+", key), "Earlier domain example needs exact feature and name")
            feature, name = key.removeprefix("domain:").split("::", 1)
        argv = ["bin/dev", "test", "test/features/domain_cucumber_acceptance_test.exs", "--only", "scenario_name:" + name, "--trace"]
    print(json.dumps({"prediction_before_execution": p, "selection": key}), flush=True)
    e, text = run(s, argv, key)
    require(e["source"] == e["source_after"], "Test changed source; result cannot be reused")
    if unit:
        counts = exunit_counts(text)
        e.update(counts=counts, status="passed" if e["exit"] == 0 and all(c["failures"] == 0 for c in counts) else "failed")
    else:
        e.update(domain_result(text, e["exit"], feature, name))
    s.setdefault("tests", {})[key] = e
    print(json.dumps(e), flush=True)
    write(STATE, s)
    return e


def observe(s, mode, raw, unit=None):
    a = s["assignment"]
    require(not a.get("halt"), "Assignment handed back: no more tests or edits")
    p = json.loads(raw)
    if mode in {"baseline", "checks"}:
        require(s["node"] == "refactoring_driver", "Green-first selection belongs to refactoring driver")
        require(p.get("status") == "passed", "Refactoring predicts all selected tests green")
        if mode == "baseline":
            require(not a.get("edit_allowed"), "Do not repeat a valid green baseline")
        else:
            require(a.get("edit_allowed"), "Run green baseline before editing")
        for key in selected(s):
            observe_one(s, key, p)
        green = checks_green(s)
        if mode == "baseline" and green:
            a["edit_allowed"] = True
        elif mode == "baseline":
            a.update(halt=True, result="baseline_red_untouched")
        elif green:
            a.update(halt=True, result="green")
    elif mode == "unit":
        require(unit in a.get("units", []) + a.get("earlier", []) and a.get("edit_allowed"), "Supporting selector must be assigned, after baseline")
        observe_one(s, unit, p)
    else:
        require(mode == "acceptance" and s["node"] == "bdd_driver", "Unexpected observation command")
        prediction(p)
        initial = not a.get("edit_allowed")
        expected = a.get("initial_prediction") if initial else a["next_prediction"]
        require(p == expected or not initial, "Initial observation must use navigator's prior prediction")
        e = observe_one(s, "acceptance", p)
        if initial:
            if matches(e, expected) and e["status"] != "passed":
                a.update(edit_allowed=True, known=e)
            else:
                a.update(halt=True, result="initial_green_untouched" if e["status"] == "passed" else "baseline_mismatch_untouched")
        elif matches(e, a["next_prediction"]):
            a.update(halt=True, result="reached_prediction")
        else:
            def failure_identity(observation):
                # Ignore stack locations, not assertion values or the failing step.
                error = re.split(r"\n\s+at ", observation.get("error", ""))[0].strip()
                return observation.get("status"), observation.get("step"), error
            if failure_identity(e) != failure_identity(a["known"]):
                a.update(halt=True, result="unexpected_result")
    write(STATE, s)
    print(json.dumps({"assignment_state": a}), flush=True)


def inspect(s, mode, *args):
    if mode == "diff":
        print(git("diff", s["base"], "--", ".", ":(exclude).fabro/tmp", ":(exclude).fabro/blobs").decode())
    elif mode == "status":
        print(git("status", "--short").decode())
    elif mode == "read":
        require(len(args) == 1, "One path per read")
        print(path_in_repo(args[0]).read_text())
    elif mode == "list":
        require(len(args) == 1, "One directory per list")
        print("\n".join(str(p.relative_to(ROOT)) for p in sorted(path_in_repo(args[0]).iterdir())))
    elif mode == "search":
        require(len(args) == 2, "Search takes literal text and directory")
        result = subprocess.run(["rg", "-n", "-F", "--", args[0], str(path_in_repo(args[1]))], capture_output=True, text=True)
        require(result.returncode in {0, 1}, "Search failed")
        print(result.stdout)
    else:
        raise ValueError("Unknown inspect operation")


def reserve_tool(s, name):
    require(not s.get("active_tool"), "Serial change protocol: wait for the preceding shell/write tool to finish")
    s["active_tool"] = name
    write(STATE, s)


def hook_tool(s, context):
    require(context.get("node_id") == s["node"] and s["node"] in ROLES, "Tool call outside active role")
    limits(s, spend=True)
    name, data = context["tool_name"], context.get("tool_input", {})
    if name in READ_TOOLS:
        return
    if name in {"shell", "shell_command"}:
        command = data.get("command", "")
        args = shlex.split(command)
        require(command == shlex.join(args), "Use canonical shlex command spelling; no shell expressions")
        require(args[:3] == ["python3", "-B", HERE] and len(args) >= 5, "Shell is limited to this guard's inspect/observe commands")
        require(Path(data.get("workdir") or ROOT).resolve() == ROOT, "Keep shell in checkout root (managed symlink is fine)")
        require(args[3] == "inspect" or args[3] == "observe" and s["node"] in DRIVERS, "Read-only role: inspection only")
        require(args[3] != "observe" or not s["assignment"].get("halt"), "Driver has handed back")
        reserve_tool(s, name)
        return
    require(s["node"] in DRIVERS and s["assignment"].get("edit_allowed") and not s["assignment"].get("halt"), "Read-only or pre-baseline/handed-back driver: no edits")
    if name == "apply_patch":
        require(isinstance(data, str), "Unknown patch input shape; inspect native tools before extending")
        paths = re.findall(r"^\*\*\* (?:Add File|Update File|Delete File|Move to): (.+)$", data, re.M)
        require(paths, "No patch paths")
    else:
        require(name in {"write_file", "edit_file"}, "No subagents, web/MCP, run-management or unknown tools")
        paths = [data.get("file_path") or data.get("path") or ""]
    for value in paths:
        p = str(path_in_repo(value).relative_to(ROOT))
        require(not p.startswith((".fabro/", ".pi/", ".github/")) and not p.endswith(".feature"), "Workflow, examples and settings are protected")
        require(any(p == q or p.startswith(q.rstrip("/") + "/") for q in s["assignment"]["paths"]), "Edit outside assigned change")
    reserve_tool(s, name)


def dispositions(s, result, done=False):
    ids = {f["id"] for f in s.get("review", {}).get("findings", [])}
    if not s.get("full", {}).get("green"):
        ids.add("full_check")
    values = result.get("dispositions", {})
    require(set(values) == ids and ids, "Account for every combined finding/full_check; do not drop or invent IDs")
    for item in values.values():
        require(item.get("status") in ({"fixed", "rejected"} if done else {"pending", "assigned", "fixed", "rejected"}) and item.get("reason"), "Each disposition needs status and evidence/reason")
    s["dispositions"] = values


def accept(s, role, result):
    require(result["source"] == s["role_source"], "Role response bound to wrong source")
    decision = result["decision"]
    if role not in DRIVERS:
        require(source() == s["role_source"], "Read-only role changed source")
    if decision == "blocked":
        print(json.dumps(result), file=sys.stderr)
        raise ValueError("Agent reported an actionable blocker")
    if role in {"bdd_navigator", "refactoring_navigator"}:
        if decision in {"change", "repair_bdd", "repair_refactor", "refactor"}:
            a = result["change"]
            require(a.get("goal") and a.get("paths"), "Assign one bounded goal and paths")
            for p in a["paths"]:
                path_in_repo(p)
                require(any(p == q or p.startswith(q.rstrip("/") + "/") for q in s["facts"]["allowed_paths"]), "Assignment outside approved scope")
            for unit in a.get("units", []):
                require(re.fullmatch(r"web/test/[A-Za-z0-9_/-]+_test\.exs(?::[1-9][0-9]*)?", unit), "Unsupported unit selection")
            for earlier in a.get("earlier", []):
                require(re.fullmatch(r"domain:acceptance-tests/features/[A-Za-z0-9_/-]+\.feature::[^\r\n]+", earlier), "Select earlier domain examples by exact feature and scenario name")
            a.update(edit_allowed=False, halt=False)
            if decision in {"change", "repair_bdd"}:
                prediction(a["next_prediction"])
                previous = s.get("tests", {}).get("acceptance", {})
                if previous.get("source") == source():
                    a.update(edit_allowed=True, known=previous)
                else:
                    prediction(a["initial_prediction"])
            if s["phase"] == "repair":
                dispositions(s, result)
                require(result.get("finding_ids") and set(result["finding_ids"]).issubset(s["dispositions"]), "Bind one repair to actual finding IDs")
                a["finding_ids"] = result["finding_ids"]
                a["findings"] = [f for f in s.get("review", {}).get("findings", []) if f["id"] in a["finding_ids"]]
                if "full_check" in a["finding_ids"]:
                    a["full_check"] = s.get("full")
            s["assignment"] = a
            label = "repair_refactor" if decision == "repair_refactor" else "refactor" if decision == "refactor" else "change"
        elif decision == "scenario_green":
            require(current_green(s) and s["phase"] != "repair", "Need actual current green; repair list is not complete")
            label = decision
        elif decision == "repairs_done":
            require(s["phase"] == "repair" and current_green(s), "Repairs require current actual scenario green")
            dispositions(s, result, done=True)
            label = decision
        else:
            require(role == "refactoring_navigator" and decision in {"done", "needs_bdd"}, "Invalid navigator decision")
            label = decision
    elif role in DRIVERS:
        a = s["assignment"]
        permitted = {"green", "baseline_red_untouched"} if role == "refactoring_driver" else {"reached_prediction", "unexpected_result", "baseline_mismatch_untouched", "initial_green_untouched"}
        require(decision == "handback" and a.get("halt") and a.get("result") in permitted, "Driver must reach a real observation/handback, not prose or an invalid/blocked test result")
        changed = git("diff", "--name-only", s["role_head"]).decode().splitlines()
        changed += git("ls-files", "--others", "--exclude-standard").decode().splitlines()
        changed = [p for p in changed if not p.startswith((".fabro/tmp/", ".fabro/blobs/"))]
        require(all(any(p == q or p.startswith(q.rstrip("/") + "/") for q in a["paths"]) for p in changed), "Driver changed unassigned source")
        if "untouched" in a["result"]:
            require(source() == s["role_source"], "Baseline mismatch/red must return without source edits")
        if a["result"] in {"green", "reached_prediction"}:
            require(all(s.get("tests", {}).get(k, {}).get("source") == source() and s["tests"][k]["status"] == "passed" for k in a.get("units", []) + a.get("earlier", [])), "Supporting selection missing/stale/not green")
        s["handback"] = {**result, "actual": a["result"]}
        label = "green" if role == "refactoring_driver" and a["result"] == "green" and s["phase"] != "repair" else "handback"
    else:
        require(role == "review" and s.get("full", {}).get("source") == source() and s["full"].get("green"), "Review needs actual current full check")
        require(decision in {"clean", "findings"} and set(result.get("lenses", {})) == {"architecture", "quality", "spec", "ux", "copy"}, "Complete all applicable lenses in one review")
        require(all(v.get("evidence") and v.get("status") in {"covered", "not_applicable"} for v in result["lenses"].values()) and all(result["lenses"][k]["status"] == "covered" for k in ("architecture", "quality", "spec")), "Missing applicable review evidence")
        require(decision != "clean" or not result.get("findings"), "Clean review cannot retain findings")
        require(decision != "findings" or result.get("findings"), "Findings list missing")
        ids = [f["id"] for f in result.get("findings", [])]
        require(all(isinstance(i, str) and i and i != "full_check" for i in ids) and len(ids) == len(set(ids)), "Finding IDs must be unique; full_check is reserved")
        s["review"] = result
        if decision == "findings":
            s["phase"] = "repair"
        label = decision
    write(STATE, s)
    route(label)


def main():
    action, *args = sys.argv[1:]
    if action == "begin":
        require(not TMP.exists(), "No automatic restart/resume: preserve previous work and native logs; navigator sessions are memory-only")
        TMP.mkdir(parents=True)
        context = read(os.environ["FABRO_HOOK_CONTEXT"])
        write(TMP / "boot.json", {"run_id": context["run_id"]})
        return
    if action == "admit":
        f = read(path_in_repo(args[0]))
        require(len(args) == 2 and re.fullmatch(r"[0-9a-f]{40}", args[1]), "Pass the exact prepared commit SHA separately (no self-referential committed SHA)")
        require(not f.get("expected_source_head") or f["expected_source_head"] == args[1], "Conflicting source admission")
        f["expected_source_head"] = args[1]
        require(git("rev-parse", "HEAD").decode().strip() == f["expected_source_head"], "Wrong prepared source HEAD")
        dirty = [line for line in git("status", "--porcelain").decode().splitlines() if not line[3:].startswith((".fabro/tmp/", ".fabro/blobs/"))]
        require(not dirty, "Prepared source must be clean; use normal committed managed clone")
        require(source() and f["scenario"] and f["setup_id"] and f["allowed_paths"], "Missing agreed facts")
        require(f["acceptance_kind"] == "domain", "This reviewed draft targets the existing domain ExUnit runner, not browser/JS acceptance")
        require(type(f["aggregate_operations"]) is int and f["aggregate_operations"] > 0, "Agree a finite original allowance")
        require(type(f["operations_spent_before_run"]) is int and 0 <= f["operations_spent_before_run"] < f["aggregate_operations"], "Parent must carry original operations already spent across any approved new attempt")
        require(dt.datetime.fromisoformat(f["deadline_utc"].replace("Z", "+00:00")).tzinfo is not None, "Deadline must include timezone")
        for p in [f["feature"], f["spec"]]:
            require(path_in_repo(p).is_file(), "Missing agreed feature/spec")
        for p in f["allowed_paths"]:
            path_in_repo(p)
            require(any(p == q or p.startswith(q + "/") for q in ("web/lib", "web/test", "web/assets")), "Scope must be explicit application/domain-test paths; no JS harness/dependency/config/workflow changes")
        s = {"facts": f, "run_id": read(TMP / "boot.json")["run_id"], "base": f["expected_source_head"], "operations": f["operations_spent_before_run"], "serial": 0, "phase": "scenario", "tests": {}}
        s["image_metadata"] = image_metadata()  # Available baked metadata, NOT a verified digest.
        write(STATE, s)
        limits(s)
        print(json.dumps(s))
        return
    if action == "stage" and not STATE.exists():
        context = read(os.environ["FABRO_HOOK_CONTEXT"])
        require(context["node_id"] in {"start", "admit", "stop"}, "No job state; no checkpoint resume without navigator sessions")
        return
    s = load()
    limits(s)
    if action == "stage":
        context = read(os.environ["FABRO_HOOK_CONTEXT"])
        require(context["run_id"] == s["run_id"], "Wrong run")
        require(not s.get("active_tool"), "Previous tool completion is uncertain; preserve work and stop")
        limits(s, spend=True)
        s["node"] = context["node_id"]
        if s["node"] in ROLES:
            s["role_source"], s["role_head"] = source(), git("rev-parse", "HEAD").decode().strip()
            keys = ("facts", "base", "phase", "operations", "tests", "preflight")
            if s["node"] not in DRIVERS:
                keys += ("full", "review", "dispositions")
            if s["node"] in {"bdd_navigator", "refactoring_navigator"}:
                keys += ("handback",)
            packet = {k: s.get(k) for k in keys}
            packet.update(role=s["node"], source=s["role_source"], head=s["role_head"])
            if s["node"] in DRIVERS:
                packet["change"] = s["assignment"]
            write(TMP / "task.json", packet)
        write(STATE, s)
    elif action == "tool":
        hook_tool(s, read(os.environ["FABRO_HOOK_CONTEXT"]))
    elif action == "tool_done":
        context = read(os.environ["FABRO_HOOK_CONTEXT"])
        require(context.get("node_id") == s["node"], "Tool completion from wrong role")
        if context["tool_name"] == s.get("active_tool"):
            s.pop("active_tool")
            write(STATE, s)
    elif action == "inspect":
        inspect(s, *args)
    elif action == "observe":
        observe(s, *args)
    elif action == "accept":
        accept(s, args[0], json.load(sys.stdin))
    elif action == "preflight":
        e, _ = run(s, ["bin/dev", "sandbox-check"], "normal-toolchain-preflight")
        require(e["exit"] == 0 and e["source"] == e["source_after"], "Normal sandbox preflight failed or changed source")
        e, text = run(s, ["bin/dev", "responsive-check", "--force"], "forced-browser-network-preflight")
        count = re.search(r"^responsive check: passed ([1-9][0-9]*) viewport/page checks$", text, re.M)
        require(e["exit"] == 0 and e["source"] == e["source_after"] and count and "responsive check: forced by --force." in text and "responsive check: skipped;" not in text, "Forced genuine browser/network preflight needs actual positive viewport count, unchanged source and exit zero")
        s["preflight"] = dict(e, forced=True, viewport_checks=int(count[1]))
        write(STATE, s)
    elif action == "full":
        require(current_green(s), "Selected example must actually be green before full check")
        e, text = run(s, ["bin/dev", "check"], "ordinary-full-dev-check")
        scenarios = re.findall(r"(\d+) scenarios? \(([^)]+)\)", text)
        units = exunit_counts(text) if e["exit"] == 0 else []
        e["green"] = bool(e["source"] == e["source_after"] and e["exit"] == 0 and units and scenarios and all(c["failures"] == 0 for c in units) and all(int(n) > 0 and detail == n + " passed" for n, detail in scenarios))
        require(e["exit"] != 0 or units and scenarios, "Full check exited zero without recognised real test summaries; inspect runner/output, do not invent acceptance")
        s["full"] = e
        if not e["green"]:
            s["phase"] = "repair"
        write(STATE, s)
        route("green" if e["green"] else "repair")
    elif action == "finish":
        require(current_green(s) and s.get("full", {}).get("source") == source() and s["full"].get("green") and s.get("review", {}).get("source") == source() and s["review"]["decision"] == "clean", "Missing/stale scenario, full gate or complete clean review")
        print("Selected example, full dev check and single review agree on source " + source())
    else:
        raise ValueError("Unknown guard action")


if __name__ == "__main__":
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "begin":
            main()
        else:
            # Native API tools may run in parallel. Serialize state changes AND
            # command observations; pre/post reservations cover native edits too.
            require(TMP.is_dir(), "No live job directory; preserve work, no automatic recovery")
            with (TMP / "guard.lock").open("a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                main()
    except (ValueError, KeyError, OSError, subprocess.SubprocessError, TypeError) as error:
        # A missing/invalid observation is not permission for further driver edits.
        if len(sys.argv) > 1 and sys.argv[1] == "observe" and STATE.exists():
            with (TMP / "guard.lock").open("a") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                s = read(STATE)
                s["assignment"].update(halt=True, result="blocked", error=str(error))
                write(STATE, s)
        print("BLOCKED: " + str(error), file=sys.stderr)
        sys.exit(2)
