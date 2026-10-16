"""Retained 25 isolated guard cases; run with python3 -B .../runner/test_guard.py.

No app/test process, model, network, container or Fabro run is executed. The three
frozen stdout fixtures are unchanged historical logs from fabro-implementation/
3b445881827e48b8bc7d75efee7e3d0c/job/evidence/{0061,0048,0094}-example.stdout.
They test parsing, NOT present-day product results. The named green trace and
preflight outputs below are explicitly synthetic, as in the original inline run.
Only Python's standard library is used; all guard subprocess paths are mocked.
"""
import ast
import contextlib
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import shlex
import sys
import tomllib
from unittest.mock import patch

WORKFLOW = Path(__file__).resolve().parents[1]
os.chdir(WORKFLOW.parents[2])
ast.parse((WORKFLOW / "runner/guard.py").read_text())
config = tomllib.loads((WORKFLOW / "workflow.toml").read_text())
assert len(list((WORKFLOW / "prompts").glob("*.md"))) == 5
assert len(config["run"]["hooks"]) == 5
assert config["run"]["model"]["fallbacks"] == {"gpt-5.6-sol": []}
spec = importlib.util.spec_from_file_location("guard", WORKFLOW / "runner/guard.py")
g = importlib.util.module_from_spec(spec)
spec.loader.exec_module(g)
fixtures = WORKFLOW / "runner/tests/fixtures"
missing = (fixtures / "domain-missing-step.stdout").read_text()
failed = (fixtures / "domain-failed-step.stdout").read_text()
old_green = (fixtures / "domain-untraced-green.stdout").read_text()
feature = "acceptance-tests/features/member_profile.feature"
name = "Alice's older edit requires confirmation of the newer name"
other = "Alice's corrected name appears across clubs and on earlier contributions"
count = 0


def block(fn):
    try:
        fn()
    except (ValueError, KeyError):
        return
    raise AssertionError("Expected deterministic block")


def check(label, fn):
    global count
    with contextlib.redirect_stdout(io.StringIO()):
        fn()
    count += 1
    print("PASS", label)


def parse_undefined():
    e = g.domain_result(missing, 2, feature, name)
    assert e["status"] == "undefined"
    assert e["step"] == 'Alice began changing their name when it was "Alice Smith"'
    assert e["counts"][0]["excluded"] == 130


check("genuine historical missing step is legitimate domain undefined", parse_undefined)


def parse_failed():
    e = g.domain_result(failed, 2, feature, other)
    assert e["status"] == "failed" and ":invalid_person_id" in e["error"]
    assert e["step"] == "Alice is a member of Rockies Cycling Co-op"


check("genuine historical failed step retains causal assertion values", parse_failed)
check("intentional --only exclusions leave exactly one actual test",
      lambda: g.exunit_counts("131 tests, 0 failures, 130 excluded\n"))
check("zero selected cannot pass",
      lambda: block(lambda: g.exunit_counts("131 tests, 0 failures, 131 excluded\n")))
check("skipped execution cannot pass",
      lambda: block(lambda: g.exunit_counts("131 tests, 0 failures, 130 excluded, 1 skipped\n")))
check("wrong selected scenario rejected",
      lambda: block(lambda: g.domain_result(missing, 2, feature, "wrong example")))
check("wrong selected feature rejected",
      lambda: block(lambda: g.domain_result(missing, 2, "acceptance-tests/features/wrong.feature", name)))
check("non-test command exit rejected",
      lambda: block(lambda: g.domain_result(missing, 1, feature, name)))
check("setup failure cannot count as expected product red",
      lambda: block(lambda: g.domain_result(missing + "\n__ex_unit_setup_0/1\n", 2, feature, name)))
check("old untraced green is insufficient for new trace protocol",
      lambda: block(lambda: g.domain_result(old_green, 0, feature, name)))
trace_green = old_green + "\n  * test member_profile.feature: " + name + " [L29] (3.0ms)\n"
check("synthetic traced-green fixture passes exact identity/count checks",
      lambda: g.domain_result(trace_green, 0, feature, name))
check("ambiguous/pending shape never invented as success",
      lambda: block(lambda: g.domain_result(missing.replace("Cucumber.StepError", "Cucumber.PendingStepError"), 2, feature, name)))

# Synthetic observations exercise role decisions, never product tests.
facts = {
    "acceptance_kind": "domain", "feature": feature, "scenario": name,
    "spec": "docs/iterations/068-member-name-editing/plan.md", "setup_id": "FIXTURE",
    "deadline_utc": "2099-01-01T00:00:00Z", "aggregate_operations": 1000,
    "operations_spent_before_run": 17, "allowed_paths": ["web/lib/memba", "web/test"],
}
p0 = {"status": "undefined", "step": 'Alice began changing their name when it was "Alice Smith"', "reason": "missing step"}
p1 = {"status": "undefined", "step": "next step", "reason": "next missing step"}
pg = {"status": "passed", "reason": "green"}


def state(role="bdd_driver"):
    return {
        "facts": copy.deepcopy(facts), "node": role, "operations": 17, "serial": 0,
        "tests": {}, "phase": "scenario", "role_source": "A", "role_head": "HEAD",
        "assignment": {
            "goal": "one change", "paths": ["web/lib/memba", "web/test"],
            "units": [], "earlier": [], "edit_allowed": False, "halt": False,
            "initial_prediction": copy.deepcopy(p0), "next_prediction": copy.deepcopy(p1),
        },
    }


def command(*args):
    return shlex.join(["python3", "-B", g.HERE, *args])


def ctx(s, tool, data):
    return {"node_id": s["node"], "tool_name": tool, "tool_input": data}


text, code, calls = missing, 2, []


def run(s, argv, label):
    calls.append(argv)
    return {"source": "A", "source_after": "A", "exit": code, "log": "FIXTURE-NOT-A-RUN"}, text


with patch.object(g, "source", return_value="A"), patch.object(g, "write"), \
        patch.object(g, "git", return_value=b""), patch.object(g, "run", side_effect=run):
    def actual_argv():
        s = state()
        g.observe(s, "acceptance", json.dumps(p0))
        assert calls[-1] == ["bin/dev", "test", "test/features/domain_cucumber_acceptance_test.exs",
                             "--only", "scenario_name:" + name, "--trace"]
        assert s["assignment"]["edit_allowed"]

    check("domain argv is exact and apostrophe remains one safe argument", actual_argv)

    def mismatch():
        s = state()
        s["assignment"]["initial_prediction"]["step"] = "wrong step"
        g.observe(s, "acceptance", json.dumps(s["assignment"]["initial_prediction"]))
        assert s["assignment"]["result"] == "baseline_mismatch_untouched"
        assert not s["assignment"]["edit_allowed"]

    check("first mismatch cannot edit", mismatch)

    def later():
        s = state("bdd_navigator")
        s["tests"]["acceptance"] = dict(source="A", status="undefined", step=p0["step"])
        a = copy.deepcopy(s["assignment"])
        a.pop("initial_prediction")
        g.accept(s, "bdd_navigator", dict(decision="change", source="A", reason="fixture", change=a))
        assert s["assignment"]["edit_allowed"]

    check("later driver reuses matching actual without baseline test", later)

    def handback():
        s = state()
        g.observe(s, "acceptance", json.dumps(p0))
        s["assignment"]["next_prediction"] = p0
        g.observe(s, "acceptance", json.dumps(p0))
        assert s["assignment"]["halt"] and s["assignment"]["result"] == "reached_prediction"
        block(lambda: g.observe(s, "acceptance", json.dumps(p0)))

    check("predicted next red hands back immediately", handback)

    def unexpected():
        s = state()
        s["assignment"].update(edit_allowed=True, known={"status": "undefined", "step": "other", "error": "other"})
        g.observe(s, "acceptance", json.dumps(p1))
        assert s["assignment"]["result"] == "unexpected_result"

    check("unexpected domain result hands back, no next obstacle", unexpected)

    def ref_red():
        s = state("refactoring_driver")
        g.observe(s, "baseline", json.dumps(pg))
        assert s["assignment"]["result"] == "baseline_red_untouched"
        assert not s["assignment"]["edit_allowed"]

    check("fresh refactoring baseline red stays untouched", ref_red)

    def serial():
        s = state()
        s["assignment"]["edit_allowed"] = True
        g.hook_tool(s, ctx(s, "shell_command", {"command": command("observe", "acceptance", json.dumps(p0))}))
        block(lambda: g.hook_tool(s, ctx(s, "apply_patch", "*** Begin Patch\n*** Update File: web/lib/memba/a.ex\n*** End Patch")))

    check("parallel native test/write crossing blocked", serial)

    def ro():
        s = state("review")
        g.hook_tool(s, ctx(s, "shell_command", {"command": command("inspect", "diff")}))
        block(lambda: g.hook_tool(s, ctx(s, "apply_patch", "*** Begin Patch\n*** Update File: web/lib/memba/a.ex\n*** End Patch")))
        block(lambda: g.hook_tool(s, ctx(s, "spawn_agent", {})))

    check("fresh review read-only, no subagents", ro)

    # Preflight main is isolated: the subprocess boundary remains mocked.
    s = state()
    preflight = "responsive check: forced by --force.\nresponsive check: passed 10 viewport/page checks\n"

    def pf_run(s, argv, label):
        return {"source": "A", "source_after": "A", "exit": 0, "log": "FIXTURE"}, preflight if "--force" in argv else "toolchain fixture"

    with patch.object(g, "load", return_value=s), patch.object(g, "run", side_effect=pf_run), \
            patch.object(sys, "argv", ["guard", "preflight"]):
        def pf_ok():
            g.main()
            assert s["preflight"]["viewport_checks"] == 10 and s["preflight"]["forced"]

        check("forced preflight requires genuine-command/count protocol (fixture)", pf_ok)
        preflight = "responsive check: skipped;\nresponsive check: passed 10 viewport/page checks\n"
        check("skipped/unforced preflight cannot admit implementation", lambda: block(g.main))
        preflight = "responsive check: forced by --force.\nresponsive check: passed 0 viewport/page checks\n"
        check("zero viewport preflight cannot admit implementation", lambda: block(g.main))

    def blocked_result():
        s = state()
        s["assignment"].update(halt=True, result="blocked")
        block(lambda: g.accept(s, "bdd_driver", dict(decision="handback", source="A", reason="prose cannot accept")))

    check("missing/invalid result cannot become agent-prose completion", blocked_result)

    def limits():
        s = state()
        s["operations"] = 1000
        block(lambda: g.limits(s, True))
        s = state()
        s["facts"]["deadline_utc"] = "2000-01-01T00:00:00Z"
        block(lambda: g.limits(s))

    check("original aggregate/deadline exhausted across visits", limits)

assert count == 25
print(f"{count} current domain/preflight/protocol fixture checks PASS; AST/TOML/five-role structure PASS. No app tests, model, container, workflow run, commit or push.")
