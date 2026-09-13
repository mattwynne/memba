#!/usr/bin/env python3
"""Native Fabro regression harness for the iteration task review loop.

This intentionally runs Fabro (not a graph simulator) against a small fixture graph
that keeps the real task-loop schema/stdin/routing edges and replaces agents and
unrelated delivery work with local scripts.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import textwrap
import time
import unittest

ROOT = Path(__file__).resolve().parents[4]
WORKFLOW_DIR = ROOT / ".fabro/workflows/iteration-implementation"
FABRO = Path(os.environ.get("FABRO_BIN") or shutil.which("fabro") or "fabro").resolve()
BASE_PATH = f"{FABRO.parent}:{Path(sys.executable).parent}:/usr/bin:/bin:/usr/sbin:/sbin"
TOKEN = "fabro_dev_" + ("a" * 64)
SESSION_SECRET = "0123456789abcdef0123456789abcdef"
TASK_CURRENT = "- [ ] current009 implement the current task"
TASK_LATER = "- [ ] later010 implement the later task"
TASK_ACCEPTED = "- [x] task001 already accepted"

TASK_NODES = {
    "sync_task_list", "todo_readable", "all_tasks_done", "implement_next_task",
    "validate_task", "apply_task_verdict", "task_stopped", "revise_task",
    "dev_check", "publish_to_main",
}


class FabroTaskRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not FABRO.is_file():
            raise RuntimeError("Install Fabro or set FABRO_BIN to run the native regression")
        cls.failed = True
        cls.tmp = Path(tempfile.mkdtemp(prefix="fabro-task-runtime-"))
        cls.addClassCleanup(cls.stop_server)
        cls.server_log = cls.tmp / "server.log"
        (cls.tmp / "home").mkdir()
        (cls.tmp / "settings.toml").write_text(
            textwrap.dedent(
                """
                _version=1
                [server.auth]
                methods=['dev-token']
                [server.slatedb]
                provider='local'
                [server.artifacts]
                provider='local'
                """
            ).strip()
            + "\n"
        )
        cls.env = {
            "HOME": str(cls.tmp / "home"),
            "PATH": BASE_PATH,
            "SESSION_SECRET": SESSION_SECRET,
            "FABRO_DEV_TOKEN": TOKEN,
            # No prompt nodes should execute; this only lets Fabro create command-only runs.
            "OPENAI_API_KEY": "sk-test-not-used-by-command-fixture",
        }
        cls.server_log_handle = cls.server_log.open("w")
        cls.server = subprocess.Popen(
            [
                str(FABRO),
                "--no-upgrade-check",
                "server",
                "start",
                "--foreground",
                "--no-web",
                "--config",
                str(cls.tmp / "settings.toml"),
                "--storage-dir",
                str(cls.tmp / "storage"),
                "--bind",
                str(cls.tmp / "fabro.sock"),
            ],
            env=cls.env,
            cwd=cls.tmp,
            stdout=cls.server_log_handle,
            stderr=subprocess.STDOUT,
            start_new_session=True,
            text=True,
        )
        cls._wait_for_server()
        subprocess.run(
            [
                str(FABRO),
                "auth",
                "login",
                "--server",
                str(cls.tmp / "fabro.sock"),
                "--dev-token",
                TOKEN,
                "--no-upgrade-check",
            ],
            env=cls.env,
            check=True,
            text=True,
            capture_output=True,
        )
        cls.failed = False

    @classmethod
    def stop_server(cls) -> None:
        if hasattr(cls, "server") and cls.server.poll() is None:
            os.killpg(cls.server.pid, signal.SIGTERM)
            try:
                cls.server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(cls.server.pid, signal.SIGKILL)
                cls.server.wait(timeout=10)
        if hasattr(cls, "server_log_handle"):
            cls.server_log_handle.close()
        if getattr(cls, "failed", True):
            print(f"\nPreserved Fabro runtime harness temp dir: {cls.tmp}", file=sys.stderr)
        else:
            shutil.rmtree(cls.tmp, ignore_errors=True)

    @classmethod
    def _wait_for_server(cls) -> None:
        sock = cls.tmp / "fabro.sock"
        deadline = time.time() + 20
        while time.time() < deadline:
            if cls.server.poll() is not None:
                raise RuntimeError(f"Fabro server exited early; see {cls.server_log}")
            if sock.exists():
                return
            time.sleep(0.2)
        raise RuntimeError(f"Fabro server socket did not appear; see {cls.server_log}")

    def run(self, result=None):  # type: ignore[override]
        outcome = super().run(result)
        if outcome.failures or outcome.errors:
            type(self).failed = True
        return outcome

    def make_fixture(self, name: str, scenario: dict[str, object]) -> Path:
        fixture = self.tmp / name
        fixture.mkdir()
        for child in ["schemas", "scripts", "docs/iterations/009-runtime"]:
            (fixture / child).mkdir(parents=True, exist_ok=True)

        shutil.copy2(WORKFLOW_DIR / "schemas/task-verdict.json", fixture / "schemas/task-verdict.json")
        helpers = fixture / ".fabro/workflows/iteration-implementation/scripts"
        helpers.mkdir(parents=True)
        for name in ("apply_task_verdict.py", "sync_task_list.py"):
            shutil.copy2(WORKFLOW_DIR / "scripts" / name, helpers / name)

        (fixture / "scenario.json").write_text(json.dumps(scenario, indent=2) + "\n")
        plan = fixture / "docs/iterations/009-runtime/plan.md"
        plan.write_text("# Runtime harness plan\n")
        (fixture / "docs/iterations/009-runtime/todo.md").write_text(
            "\n".join([TASK_ACCEPTED, TASK_CURRENT, TASK_LATER]) + "\n"
        )
        (fixture / "workflow.toml").write_text(
            textwrap.dedent(
                f"""
                _version=1
                [workflow]
                graph='fixture.fabro'
                [run.environment]
                id='fixture'
                [environments.fixture]
                provider='local'
                [run.clone]
                enabled=false
                [run.run_branch]
                enabled=false
                push=false
                [run.meta_branch]
                enabled=false
                push=false
                [run.pull_request]
                enabled=false
                [run]
                working_dir='{fixture}'
                [run.inputs]
                plan_path='docs/iterations/009-runtime/plan.md'
                """
            ).strip()
            + "\n"
        )
        (fixture / "fixture.fabro").write_text(self.fixture_graph())
        (fixture / "scripts/step.py").write_text(STEP_SCRIPT)
        (fixture / "scripts/validate.py").write_text(VALIDATE_SCRIPT)
        self.git(fixture, "init", "-q")
        self.git(fixture, "config", "user.email", "runtime@example.invalid")
        self.git(fixture, "config", "user.name", "Runtime Harness")
        self.git(fixture, "add", ".")
        self.git(fixture, "commit", "-q", "-m", "fixture")
        return fixture

    def fixture_graph(self) -> str:
        parent = (WORKFLOW_DIR / "workflow.fabro").read_text()
        nodes = dict(re.findall(r"^    (\w+) (\[\n.*?^    \])", parent, re.M | re.S))
        self.assertTrue(TASK_NODES <= nodes.keys())
        blocks = []
        for name in sorted(TASK_NODES):
            block = nodes[name]
            # Keep production schema, stdin_source, limits and command bodies.
            # Replace only LLM work and delivery side effects with inert fixtures.
            if name in ("implement_next_task", "validate_task", "revise_task"):
                command = "python3 scripts/validate.py" if name == "validate_task" else f"python3 scripts/step.py {name}"
                block = re.sub(r'prompt="[^"]*"', f'shape=parallelogram, script="{command}"', block)
            elif name in ("dev_check", "publish_to_main"):
                block = re.sub(r'script="(?:\\.|[^"\\])*"', f'script="python3 scripts/step.py {name}"', block)
            self.assertIn("shape=parallelogram", block)
            self.assertNotIn("prompt=", block)
            blocks.append(f"    {name} {block}")
        edges = [
            line for line in parent.splitlines()
            if (match := re.match(r"\s*(\w+) -> (\w+)", line))
            and match[1] in TASK_NODES and match[2] in TASK_NODES
        ]
        return '\n'.join([
            'digraph TaskRuntime {',
            '    graph [goal="test task verdicts", max_node_visits=80]',
            '    start [shape=Mdiamond]', '    exit [shape=Msquare]',
            *blocks,
            '    start -> sync_task_list', *edges,
            '    dev_check -> publish_to_main [condition="outcome=succeeded"]',
            '    dev_check -> task_stopped',
            '    publish_to_main -> exit [condition="outcome=succeeded"]',
            '    publish_to_main -> task_stopped',
            '}',
        ]) + '\n'

    def git(self, cwd: Path, *args: str) -> None:
        subprocess.run(["git", *args], cwd=cwd, check=True, text=True, capture_output=True)

    def run_fixture(self, fixture: Path) -> dict[str, object]:
        completed = subprocess.run(
            [
                str(FABRO),
                "--no-upgrade-check",
                "run",
                "--server",
                str(self.tmp / "fabro.sock"),
                str(fixture / "workflow.toml"),
                "--auto-approve",
                "--provider",
                "openai",
                "--model",
                "gpt-5",
            ],
            env=self.env,
            cwd=fixture,
            text=True,
            capture_output=True,
            timeout=90,
        )
        run_id_match = re.search(r"Run:\s+([0-9A-Z]+)", completed.stdout + completed.stderr)
        events = logs = ""
        if run_id_match:
            run_id = run_id_match.group(1)
            events = self.fabro_text("events", run_id)
            logs = self.fabro_text("logs", run_id)
        else:
            run_id = ""
        (fixture / "run.stdout").write_text(completed.stdout)
        (fixture / "run.stderr").write_text(completed.stderr)
        (fixture / "run.events").write_text(events)
        (fixture / "run.logs").write_text(logs)
        self.assertTrue(run_id, completed.stdout + completed.stderr)
        records = [json.loads(line) for line in events.splitlines() if line.strip()]
        self.assertFalse(any(event["event"].startswith("agent.llm") for event in records))
        return {
            "stages": [event.get("node_id") for event in records if event["event"] == "stage.started"],
            "status": completed.returncode,
            "stdout": completed.stdout,
            "stderr": completed.stderr,
            "run_id": run_id,
            "events": events,
            "logs": logs,
            "combined": "\n".join([completed.stdout, completed.stderr, events, logs]),
        }

    def fabro_text(self, command: str, run_id: str) -> str:
        completed = subprocess.run(
            [str(FABRO), "--no-upgrade-check", command, "--server", str(self.tmp / "fabro.sock"), run_id, *(["--json"] if command == "events" else [])],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=30,
        )
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)
        return completed.stdout if command == "events" else completed.stdout + completed.stderr

    def todo(self, fixture: Path) -> str:
        return (fixture / "docs/iterations/009-runtime/todo.md").read_text()

    def test_revise_then_accept_checks_off_same_first_pending_task_only(self) -> None:
        fixture = self.make_fixture(
            "revise-accept",
            {"verdicts": [{"decision": "revise"}, {"decision": "accept"}, {"decision": "accept"}]},
        )
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 0, result["combined"])
        reviews = [json.loads(line) for line in (fixture / "reviews.jsonl").read_text().splitlines()]
        self.assertIn(TASK_CURRENT, reviews[0])
        self.assertIn(TASK_CURRENT, reviews[1])
        self.assertIn(TASK_CURRENT.replace("[ ]", "[x]"), reviews[2])
        self.assertIn(TASK_LATER, reviews[2])
        self.assertEqual((fixture / "work.log").read_text().splitlines(), [
            f"implement_next_task:{TASK_CURRENT}", f"revise_task:{TASK_CURRENT}",
            f"implement_next_task:{TASK_LATER}",
        ])
        self.assertNotIn("- [ ]", self.todo(fixture))
        self.assertIn(TASK_ACCEPTED, self.todo(fixture))
        self.assertEqual(result["stages"].count("apply_task_verdict"), 3)
        self.assertTrue((fixture / "published.txt").exists())

    def test_failed_review_cannot_reuse_prior_acceptance(self) -> None:
        fixture = self.make_fixture(
            "stale-output",
            {"verdicts": [{"decision": "accept"}, {"exit_code": 23}]},
        )
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 1, result["combined"])
        todo = self.todo(fixture)
        self.assertIn(TASK_CURRENT.replace("- [ ]", "- [x]"), todo)
        self.assertIn(TASK_LATER, todo)
        self.assertIn("fixture reviewer execution failure", result["combined"])
        self.assertEqual(result["stages"].count("apply_task_verdict"), 1)
        self.assertEqual(result["stages"][-1], "task_stopped")
        self.assertNotIn("publish_to_main", result["stages"])

    def test_malformed_schema_with_failed_outcome_fails_closed(self) -> None:
        fixture = self.make_fixture(
            "malformed-schema",
            {"verdicts": [{"decision": "revise", "extra": {"outcome": "failed"}}]},
        )
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 1, result["combined"])
        self.assertIn(TASK_CURRENT, self.todo(fixture))
        self.assertNotIn("revise_task", result["stages"])
        self.assertNotIn("apply_task_verdict", result["stages"])
        self.assertIn("output_schema validation", result["combined"])

    def test_blocked_verdict_preserves_reason_in_events(self) -> None:
        reason = "Blocked because dependency XYZ is missing"
        fixture = self.make_fixture("blocked", {"verdicts": [{"decision": "blocked", "reason": reason}]})
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 1, result["combined"])
        self.assertIn(reason, result["events"])
        self.assertIn(TASK_CURRENT, self.todo(fixture))

    def test_repeated_revise_hits_native_max_visits_and_preserves_work(self) -> None:
        fixture = self.make_fixture("max-visits", {"verdicts": [{"decision": "revise"}] * 10})
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 1, result["combined"])
        self.assertIn(TASK_CURRENT, self.todo(fixture))
        work = (fixture / "work.log").read_text()
        self.assertIn(f"implement_next_task:{TASK_CURRENT}", work)
        # Fabro 0.316 increments the visit count before checking the limit:
        # max_visits=3 stops before executing the third revision.
        self.assertEqual(work.count(f"revise_task:{TASK_CURRENT}"), 2, work)
        self.assertIn('node "revise_task" visited 3 times', result["combined"])
        self.assertNotIn("publish_to_main", result["stages"])

    def test_new_run_continues_the_checkpointed_pending_candidate(self) -> None:
        fixture = self.make_fixture("restart", {"verdicts": [{"decision": "blocked"}]})
        first = self.run_fixture(fixture)
        self.assertEqual(first["status"], 1, first["combined"])
        saved_work = (fixture / "work.log").read_text()
        self.assertIn(TASK_CURRENT, self.todo(fixture))
        (fixture / "scenario.json").write_text(json.dumps({"verdicts": [{"decision": "accept"}]}))
        second = self.run_fixture(fixture)
        self.assertEqual(second["status"], 0, second["combined"])
        self.assertNotEqual(first["run_id"], second["run_id"])
        work = (fixture / "work.log").read_text()
        self.assertTrue(work.startswith(saved_work))
        self.assertEqual(work.splitlines()[1], f"implement_next_task:{TASK_CURRENT}")
        self.assertNotIn("- [ ]", self.todo(fixture))

    def test_task_stopped_failure_does_not_report_publish_goal_gate_noise(self) -> None:
        fixture = self.make_fixture("task-stopped", {"verdicts": [{"decision": "accept", "task": "- [ ] not-the-real-task"}]})
        result = self.run_fixture(fixture)
        self.assertEqual(result["status"], 1, result["combined"])
        self.assertEqual(result["stages"][-1], "task_stopped")
        self.assertNotIn("publish_to_main", result["stages"])
        self.assertNotIn("goal gate unsatisfied", result["combined"].lower())


STEP_SCRIPT = r'''#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import sys

import subprocess

kind = sys.argv[1]
todo = Path("docs/iterations/009-runtime/todo.md").read_text().splitlines()
pending = next((line for line in todo if line.startswith("- [ ] ")), None)
if kind in ("dev_check", "publish_to_main"):
    assert pending is None, "Unaccepted work reached the final gates"
    if kind == "publish_to_main":
        Path("published.txt").write_text("Inert fixture publication only.\n")
    sys.exit(0)
assert pending is not None
with Path("work.log").open("a") as output:
    output.write(f"{kind}:{pending}\n")
# Checkpoint only fixture work and todo locally, with no configured git remote.
subprocess.run(["git", "add", "work.log", "docs/iterations/009-runtime/todo.md"], check=True)
subprocess.run(["git", "commit", "-qm", "candidate checkpoint"], check=True)
print(f"{kind} work for {pending}")
'''

VALIDATE_SCRIPT = r'''#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
import sys

scenario = json.loads(Path("scenario.json").read_text())
state_path = Path("state.json")
state = json.loads(state_path.read_text()) if state_path.exists() else {"validations": 0}
index = state["validations"]
state["validations"] = index + 1
state_path.write_text(json.dumps(state, indent=2) + "\n")
verdicts = scenario.get("verdicts", [])
template = verdicts[index] if index < len(verdicts) else verdicts[-1]
with Path("reviews.jsonl").open("a") as output:
    output.write(json.dumps(Path("docs/iterations/009-runtime/todo.md").read_text()) + "\n")
if "exit_code" in template:
    print("fixture reviewer execution failure", file=sys.stderr)
    sys.exit(template["exit_code"])

def first_pending() -> str:
    for line in Path("docs/iterations/009-runtime/todo.md").read_text().splitlines():
        if line.startswith("- [ ] "):
            return line
    return "- [ ] <no-pending-task>"

verdict = {
    "decision": template.get("decision", "accept"),
    "task": template.get("task", first_pending()),
    "reason": template.get("reason", f"scripted {template.get('decision', 'accept')} verdict #{index + 1}"),
}
verdict.update(template.get("extra", {}))
print(json.dumps(verdict))
'''


if __name__ == "__main__":
    unittest.main(verbosity=2)
