#!/usr/bin/env python3
"""Native, no-model Fabro routing regression for the production code-review graph."""
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
WORKFLOW = ROOT / ".fabro/workflows/code-review"
FABRO = Path(os.environ.get("FABRO_BIN") or shutil.which("fabro") or "fabro").resolve()
TOKEN = "fabro_dev_" + "b" * 64


class CodeReviewRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        if not FABRO.is_file():
            raise RuntimeError("Install Fabro or set FABRO_BIN")
        cls.failed = True
        cls.tmp = Path(tempfile.mkdtemp(prefix="fabro-code-review-runtime-"))
        cls.addClassCleanup(cls.cleanup)
        (cls.tmp / "home").mkdir()
        (cls.tmp / "settings.toml").write_text("""_version=1
[server.auth]
methods=['dev-token']
[server.slatedb]
provider='local'
[server.artifacts]
provider='local'
""")
        cls.env = {
            "HOME": str(cls.tmp / "home"),
            "PATH": f"{FABRO.parent}:{Path(sys.executable).parent}:/usr/bin:/bin",
            "SESSION_SECRET": "0123456789abcdef0123456789abcdef",
            "FABRO_DEV_TOKEN": TOKEN,
            "OPENAI_API_KEY": "sk-test-never-used",
        }
        cls.log_handle = (cls.tmp / "server.log").open("w")
        cls.server = subprocess.Popen(
            [str(FABRO), "--no-upgrade-check", "server", "start", "--foreground", "--no-web",
             "--config", str(cls.tmp / "settings.toml"), "--storage-dir", str(cls.tmp / "storage"),
             "--bind", str(cls.tmp / "fabro.sock")],
            cwd=cls.tmp, env=cls.env, stdout=cls.log_handle, stderr=subprocess.STDOUT,
            start_new_session=True, text=True,
        )
        deadline = time.time() + 20
        while time.time() < deadline and not (cls.tmp / "fabro.sock").exists():
            if cls.server.poll() is not None:
                raise RuntimeError("Fabro server exited")
            time.sleep(.1)
        subprocess.run(
            [str(FABRO), "auth", "login", "--server", str(cls.tmp / "fabro.sock"),
             "--dev-token", TOKEN, "--no-upgrade-check"], env=cls.env, check=True, capture_output=True, text=True)
        cls.failed = False

    @classmethod
    def cleanup(cls) -> None:
        if hasattr(cls, "server") and cls.server.poll() is None:
            os.killpg(cls.server.pid, signal.SIGTERM)
            try:
                cls.server.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(cls.server.pid, signal.SIGKILL)
        if hasattr(cls, "log_handle"):
            cls.log_handle.close()
        if cls.failed:
            print(f"Preserved runtime fixture: {cls.tmp}", file=sys.stderr)
        else:
            shutil.rmtree(cls.tmp, ignore_errors=True)

    def run(self, result=None):  # type: ignore[override]
        outcome = super().run(result)
        if outcome.failures or outcome.errors:
            type(self).failed = True
        return outcome

    def make_fixture(self, name: str, scenario: dict) -> Path:
        fixture = self.tmp / name
        (fixture / "scripts").mkdir(parents=True)
        helper_dir = fixture / ".fabro/workflows/code-review/scripts"
        helper_dir.mkdir(parents=True)
        for helper in ("preflight_sandbox.sh", "collect_implementation_evidence.sh", "verify_review_repair.sh", "record_observability.sh"):
            shutil.copy2(WORKFLOW / "scripts" / helper, helper_dir / helper)
        (fixture / "bin").mkdir()
        (fixture / "bin/dev").write_text("#!/usr/bin/env bash\n[ \"${1:-}\" = sandbox-check ]\n")
        (fixture / "bin/dev").chmod(0o755)
        (fixture / "scenario.json").write_text(json.dumps(scenario))
        (fixture / "heal.txt").write_text("before\n")
        (fixture / "scripts/step.py").write_text(STEP)
        (fixture / "workflow.fabro").write_text(self.fixture_graph())
        (fixture / "workflow.toml").write_text(textwrap.dedent(f"""
            _version=1
            [workflow]
            graph='workflow.fabro'
            [run.environment]
            id='local'
            [environments.local]
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
        """).strip() + "\n")
        subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
        subprocess.run(["git", "config", "user.name", "Runtime"], cwd=fixture, check=True)
        subprocess.run(["git", "config", "user.email", "runtime@example.invalid"], cwd=fixture, check=True)
        subprocess.run(["git", "add", "."], cwd=fixture, check=True)
        subprocess.run(["git", "commit", "-qm", "fixture"], cwd=fixture, check=True)
        return fixture

    def fixture_graph(self) -> str:
        production = (WORKFLOW / "workflow.fabro").read_text()
        node_names = [name for name in re.findall(r"^    (\w+) \[", production, re.M) if name != "graph"]
        edges = [line for line in production.splitlines() if re.match(r"^    \w+ -> \w+", line)]
        self.assertIn("consequential_gate -> record_code_health [label=\"[R] Record / defer\"]", production)
        definitions = []
        for node in node_names:
            if node == "start":
                definitions.append("    start [shape=Mdiamond]")
            elif node == "exit":
                definitions.append("    exit [shape=Msquare]")
            elif node == "disposition":
                definitions.append("    disposition [shape=diamond]")
            elif node == "consequential_gate":
                definitions.append('    consequential_gate [shape=hexagon, question_type="multiple_choice", label="Safe disposition"]')
            elif node == "final_summary":
                definitions.append('    final_summary [shape=parallelogram, goal_gate=true, script="python3 scripts/step.py final_summary"]')
            elif node == "preflight_sandbox":
                definitions.append('    preflight_sandbox [shape=parallelogram, script="bash .fabro/workflows/code-review/scripts/preflight_sandbox.sh $(git rev-parse HEAD)"]')
            elif node == "collect_implementation_evidence":
                definitions.append('    collect_implementation_evidence [shape=parallelogram, script="bash .fabro/workflows/code-review/scripts/collect_implementation_evidence.sh $(git rev-parse HEAD)"]')
            elif node == "snapshot_before_heal":
                definitions.append('    snapshot_before_heal [shape=parallelogram, script="mkdir -p .fabro/tmp; git rev-parse HEAD > .fabro/tmp/review-repair-before-head.txt; git diff --binary HEAD > .fabro/tmp/review-repair-before.patch"]')
            elif node == "verify_heal_progress":
                definitions.append('    verify_heal_progress [shape=parallelogram, script="bash .fabro/workflows/code-review/scripts/verify_review_repair.sh"]')
            elif node.startswith("observe_") or node in {"consequential_context", "reviewer_unavailable"}:
                args = {
                    "observe_clean": "clean false false",
                    "observe_record": "record false false",
                    "observe_heal": "bounded_heal false true",
                    "observe_dismiss": "dismissed true false",
                    "consequential_context": "consequential true false",
                    "reviewer_unavailable": "provider_failure false false",
                }[node]
                suffix = "; exit 1" if node == "reviewer_unavailable" else ""
                definitions.append(f'    {node} [shape=parallelogram, script="bash .fabro/workflows/code-review/scripts/record_observability.sh {args}{suffix}"]')
            else:
                schema = ', output_schema="routing"' if node in {"focused_reviewer", "record_code_health", "prepare_followup"} else ""
                definitions.append(f'    {node} [shape=parallelogram{schema}, script="python3 scripts/step.py {node}"]')
        return "\n".join([
            'digraph CodeReviewRuntime {',
            '    graph [goal="native code review route test", max_node_visits=40]',
            *definitions, *edges, "}", "",
        ])

    def launch(self, fixture: Path, auto: bool = True, detach: bool = False) -> tuple[subprocess.CompletedProcess, str]:
        args = [str(FABRO), "--no-upgrade-check", "run", "--server", str(self.tmp / "fabro.sock"), str(fixture / "workflow.toml")]
        if auto:
            args.append("--auto-approve")
        if auto or detach:
            args.append("--detach")
        submitted = subprocess.run(args, cwd=fixture, env=self.env, text=True, capture_output=True, timeout=45)
        match = re.search(r"(?:Run:\s+|\b)([0-9A-Z]{26})\b", submitted.stdout + submitted.stderr)
        self.assertIsNotNone(match, submitted.stdout + submitted.stderr)
        run_id = match.group(1)  # type: ignore[union-attr]
        if not auto:
            return submitted, run_id
        waited = subprocess.run(
            [str(FABRO), "--no-upgrade-check", "wait", "--server", str(self.tmp / "fabro.sock"), run_id],
            cwd=fixture, env=self.env, text=True, capture_output=True, timeout=45)
        combined = subprocess.CompletedProcess(
            args, waited.returncode, submitted.stdout + waited.stdout, submitted.stderr + waited.stderr)
        return combined, run_id

    def events(self, run_id: str) -> list[dict]:
        done = subprocess.run(
            [str(FABRO), "--no-upgrade-check", "events", "--server", str(self.tmp / "fabro.sock"), run_id, "--json"],
            env=self.env, text=True, capture_output=True, timeout=20, check=True)
        records = [json.loads(line) for line in done.stdout.splitlines() if line.strip()]
        self.assertFalse(any(r["event"].startswith("agent.llm") for r in records))
        return records

    def read_observations(self, fixture: Path, combined: str) -> list[dict]:
        observation_file = fixture / ".fabro/tmp/code-review-observability.jsonl"
        self.assertTrue(observation_file.is_file(), combined)
        observations = [json.loads(line) for line in observation_file.read_text().splitlines()]
        for observation in observations:
            self.assertTrue(
                observation["run_id"] == "unknown" or re.fullmatch(r"[0-9A-Z]{26}", observation["run_id"]),
                observation["run_id"],
            )
            self.assertIsInstance(observation["human_paused"], bool)
            self.assertIsInstance(observation["heal_commit_published"], bool)
            self.assertIsInstance(observation["elapsed_seconds"], int)
            self.assertGreaterEqual(observation["elapsed_seconds"], 0)
        return observations

    def completed_stages(self, scenario: dict, name: str) -> list[str]:
        fixture = self.make_fixture(name, scenario)
        done, run_id = self.launch(fixture)
        records = self.events(run_id)
        combined = done.stdout + done.stderr + "\n".join(json.dumps(r) for r in records)
        self.assertEqual(done.returncode, 0, combined)
        expected = {
            "clean": [("clean", False, False)],
            "bounded_heal": [("bounded_heal", False, False)],
            "record": [("record", False, False)],
            "consequential": [("consequential", True, False), ("record", False, False)],
            "invalid": [("consequential", True, False), ("record", False, False)],
        }[scenario.get("disposition", "invalid")]
        if scenario.get("no_progress"):
            expected = [("consequential", True, False), ("record", False, False)]
        observations = self.read_observations(fixture, combined)
        actual = [
            (item["review_disposition"], item["human_paused"], item["heal_commit_published"])
            for item in observations
        ]
        self.assertEqual(actual, expected)
        return [r.get("node_id") for r in records if r["event"] == "stage.started"]

    def test_clean_heal_record_and_consequential_routes(self) -> None:
        clean = self.completed_stages({"disposition": "clean"}, "clean")
        self.assertIn("observe_clean", clean)
        self.assertNotIn("publish_followup", clean)

        heal = self.completed_stages({"disposition": "bounded_heal"}, "heal")
        self.assertEqual(heal.count("apply_bounded_heal"), 1)
        self.assertIn("dev_check", heal)
        self.assertIn("observe_heal", heal)

        record = self.completed_stages({"disposition": "record"}, "record")
        self.assertIn("record_code_health", record)
        self.assertIn("observe_record", record)

        consequential = self.completed_stages({"disposition": "consequential"}, "consequential-auto")
        self.assertIn("consequential_gate", consequential)
        self.assertIn("record_code_health", consequential, "--auto-approve must choose first safe record/defer option")
        self.assertNotIn("prepare_followup", consequential)
        self.assertNotIn("observe_dismiss", consequential)

    def test_invalid_fallthrough_and_no_progress_are_one_pass_and_safe(self) -> None:
        invalid = self.completed_stages({"disposition": "invalid"}, "invalid")
        self.assertIn("consequential_gate", invalid)
        no_progress = self.completed_stages({"disposition": "bounded_heal", "no_progress": True}, "no-progress")
        self.assertEqual(no_progress.count("apply_bounded_heal"), 1)
        self.assertEqual(no_progress.count("verify_heal_progress"), 1)
        self.assertIn("consequential_gate", no_progress)
        self.assertNotIn("dev_check", no_progress)

    def test_unanswered_human_gate_remains_paused(self) -> None:
        fixture = self.make_fixture("unanswered", {"disposition": "consequential"})
        done, run_id = self.launch(fixture, auto=False, detach=True)
        self.assertEqual(done.returncode, 0, done.stdout + done.stderr)
        deadline = time.time() + 15
        stages: list[str] = []
        while time.time() < deadline:
            stages = [r.get("node_id") for r in self.events(run_id) if r["event"] == "stage.started"]
            if "consequential_gate" in stages:
                break
            time.sleep(.2)
        self.assertIn("consequential_gate", stages)
        observations = self.read_observations(fixture, done.stdout + done.stderr)
        self.assertEqual(
            [(item["review_disposition"], item["human_paused"]) for item in observations],
            [("consequential", True)],
        )
        time.sleep(.3)
        stages = [r.get("node_id") for r in self.events(run_id) if r["event"] == "stage.started"]
        self.assertNotIn("record_code_health", stages)
        self.assertNotIn("prepare_followup", stages)
        self.assertNotIn("observe_dismiss", stages)

    def test_provider_failure_records_exact_observability_and_fails(self) -> None:
        fixture = self.make_fixture("provider-failure", {"provider_failure": True})
        done, run_id = self.launch(fixture)
        records = self.events(run_id)
        combined = done.stdout + done.stderr + "\n".join(json.dumps(r) for r in records)
        self.assertNotEqual(done.returncode, 0, combined)
        stages = [r.get("node_id") for r in records if r["event"] == "stage.started"]
        self.assertIn("reviewer_unavailable", stages)
        observations = self.read_observations(fixture, combined)
        self.assertEqual(len(observations), 1)
        self.assertEqual(observations[0]["review_disposition"], "provider_failure")
        self.assertFalse(observations[0]["human_paused"])
        self.assertFalse(observations[0]["heal_commit_published"])


STEP = r'''#!/usr/bin/env python3
import json
from pathlib import Path
import sys
node = sys.argv[1]
scenario = json.loads(Path("scenario.json").read_text())
if node == "focused_reviewer":
    if scenario.get("provider_failure"):
        raise SystemExit(1)
    print(json.dumps({"context_updates": {"review_disposition": scenario.get("disposition", "invalid")}}))
elif node in ("record_code_health", "prepare_followup"):
    print(json.dumps({"context_updates": {"code_health_recording_ok": True, "review_disposition": "record"}}))
elif node == "apply_bounded_heal" and not scenario.get("no_progress"):
    Path("heal.txt").write_text("after\n")
elif node in {"read_failed", "preflight_failed", "collect_evidence_failed", "reviewer_unavailable", "code_health_recording_failed", "artifact_failed", "publish_failed"}:
    raise SystemExit(1)
'''


if __name__ == "__main__":
    unittest.main(verbosity=2)
