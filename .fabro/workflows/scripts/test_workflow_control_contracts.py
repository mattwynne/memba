#!/usr/bin/env python3
"""Memba control retention and pinned 0.389/0.408 provenance, without execution.

The default suite checks authored source. --upstream-root additionally checks the
reviewed public source archives and compares both CLIs' offline validators under
macOS network/child-exec denial. It never starts a server, workflow or sandbox.
Source tracing is not a functional test of Slack, Docker or provider readiness.
"""

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import tomllib
import unittest

WORKFLOWS = Path(__file__).resolve().parents[1]
UPSTREAM = None
VERSIONS = {
    "0.389.0-nightly.0": (
        "fabro-5c90ad2e0c6662207a952afb303422e3388425d2",
        "petri-56ec3849ca693974ff778aa5ad4f9f9410d47d29",
        "old-binary/fabro-aarch64-apple-darwin/fabro",
    ),
    "0.408.0-nightly.0": (
        "fabro-77df2763f996f480f63156de55da281973fc40fd",
        "petri-f30a12df140fb60f55a7c6cff3d7f45673c7a7c5",
        "fabro-aarch64-apple-darwin/fabro",
    ),
}
SLACK = (
    "code-review", "iteration-implementation", "iteration-clarification",
    "slack-prose-smoke", "slack-question-smoke",
)
BDD = ("bdd-plan-implementation", "bdd-plan-implementation/scenario")
GATES = {
    "code-review": "final_summary",
    "iteration-implementation": "publish_to_main",
    "plan-validation": "publish_ready",
}


def config(name):
    return tomllib.loads((WORKFLOWS / name / "workflow.toml").read_text())


def graph(name):
    return (WORKFLOWS / name / "workflow.fabro").read_text()


def section(text, start, end):
    return text[text.index(start):text.index(end, text.index(start))]


class WorkflowControlContracts(unittest.TestCase):
    def test_checkpoint_exclusions_are_retained(self):
        for name in ("code-review", "iteration-implementation", *BDD):
            expected = [".fabro/tmp/**", ".fabro/blobs/**"] if name in BDD else [
                ".fabro/tmp", ".fabro/tmp/**",
            ]
            self.assertEqual(config(name)["run"]["checkpoint"], {"exclude_globs": expected})

    def test_artifact_selection_and_no_requested_integration_token_are_retained(self):
        for name in BDD:
            expected = [".fabro/tmp/bdd/**"]
            if name == "bdd-plan-implementation":
                expected.insert(0, ".fabro/tmp/bdd-plan/**")
            run = config(name)["run"]
            self.assertEqual(run["artifacts"], {"include": expected})
            # An explicit empty permissions map clears inherited token requests.
            self.assertEqual(run["integrations"], {"github": {"permissions": {}}})

    def test_slack_destination_intent_and_human_approval_are_not_weakened(self):
        for name in SLACK:
            run = config(name)["run"]
            self.assertEqual(run["interviews"], {
                "provider": "slack", "slack": {"channel": "#memba"},
            })
            self.assertEqual(run.get("execution", {}).get("approval", "prompt"), "prompt")

    def test_docker_resource_intent_is_retained_not_claimed_enforced(self):
        for name in SLACK:
            environment = config(name)["environments"]["memba-dev"]
            self.assertEqual(environment["provider"], "docker")
            self.assertEqual(environment["resources"], {
                "cpu": 2 if name == "iteration-implementation" else 1,
                "memory": "2048MB" if name == "code-review" else "1536MB",
            })

    def test_goal_gates_remain_fail_closed_without_automatic_reentry(self):
        for name, node in GATES.items():
            text = graph(name)
            declaration = re.search(rf"\b{node}\s*\[(.*?)\]", text, re.DOTALL)
            self.assertIsNotNone(declaration)
            self.assertRegex(declaration[1], r"\bgoal_gate\s*=\s*true\b")
            self.assertNotRegex(text, r"\b(?:fallback_)?retry_target\s*=")

    def test_imported_and_standalone_bdd_stylesheets_have_identical_rules(self):
        styles = [re.search(r'model_stylesheet="([^"]+)"', graph(name))[1] for name in BDD]
        self.assertEqual(styles[0], styles[1])
        self.assertEqual(styles[0], "* { provider: openai; model: gpt-5.6-sol; reasoning_effort: high; }")

    def test_compatibility_note_distinguishes_host_controls_and_owner_choices(self):
        note = (WORKFLOWS / "COMPATIBILITY-0.408.md").read_text()
        for term in (
            "5c90ad2e0c6662207a952afb303422e3388425d2",
            "77df2763f996f480f63156de55da281973fc40fd",
            "standalone", "HooksSpec::for_run", "default_channel",
            "pre-existing", "owner choices",
        ):
            self.assertIn(term, note)


class PinnedControlProvenance(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if UPSTREAM is None:
            raise unittest.SkipTest("Pass --upstream-root for pinned source/binary checks")
        cls.sources = []
        for version, (fabro, petri, binary) in VERSIONS.items():
            source = UPSTREAM / fabro
            metadata = tomllib.loads((source / "Cargo.toml").read_text())
            if metadata["workspace"]["package"]["version"] != version:
                raise AssertionError("Unexpected Fabro source version")
            cls.sources.append((source, UPSTREAM / petri, UPSTREAM / binary))

    def test_fabro_worker_supplies_checkpoint_and_artifact_controls_in_both_versions(self):
        checkpoints = []
        for source, _, _ in self.sources:
            hooks = (source / "lib/components/fabro-petri/src/hooks.rs").read_text()
            self.assertIn("git: RunGitSettings::from(settings)", hooks)
            self.assertIn("artifacts: settings.artifacts.include.clone()", hooks)
            self.assertIn("list_artifacts(env.as_ref(), globs)", hooks)
            self.assertIn("const ARTIFACT_MAX_FILES: usize = 100;", hooks)
            self.assertIn("const ARTIFACT_MAX_TOTAL_BYTES: u64 = 50 * 1024 * 1024;", hooks)
            artifact = (source / "lib/foundation/fabro-types/src/artifact_source.rs").read_text()
            self.assertIn("pub const ARTIFACT_MAX_FILE_BYTES: usize = 10 * 1024 * 1024;", artifact)
            worker = (source / "lib/apps/fabro-cli/src/commands/run/petri_worker.rs").read_text()
            self.assertIn("HooksSpec::for_run(", worker)
            self.assertIn("&worker.run_state.spec.settings.run,", worker)
            checkpoint = (source / "lib/components/fabro-petri/src/checkpoint.rs").read_text()
            for expression in (
                "checkpoint: settings.checkpoint.clone()",
                "exclude_globs: settings.exclude_globs.clone()",
                'format!(":(glob,exclude){glob}")',
            ):
                self.assertIn(expression, checkpoint)
            checkpoints.append(checkpoint)
        self.assertEqual(checkpoints[0], checkpoints[1])

    def test_platform_github_token_request_policy_is_unchanged(self):
        for source, _, _ in self.sources:
            settings = (source / "lib/foundation/fabro-types/src/settings/run.rs").read_text()
            self.assertIn("pub fn is_token_requested(&self) -> bool {\n        !self.permissions.is_empty()", settings)
            layer = (source / "lib/foundation/fabro-config/src/layers/run.rs").read_text()
            self.assertIn("permissions:             self.permissions.or(other.permissions)", layer)
            credentials = (source / "lib/components/fabro-petri/src/stage_credentials.rs").read_text()
            self.assertIn("let api_tokens = integration\n            .is_token_requested()", credentials)

    def test_server_default_slack_route_is_preexisting_not_a_new_regression(self):
        methods = []
        for source, _, _ in self.sources:
            server = (source / "lib/apps/fabro-server/src/server.rs").read_text()
            method = section(server, "    async fn post_question(", "    fn posted_question_text(")
            self.assertIn("self.default_channel.as_deref()", method)
            self.assertIn(".post_message(default_channel, &blocks, None)", method)
            self.assertNotIn(".interviews", method)
            methods.append(method)
            worker = (source / "lib/apps/fabro-cli/src/commands/run/petri_worker.rs").read_text()
            self.assertIn("ApprovalMode::Auto", worker)
            self.assertIn("Approval::Prompt", worker)
            interview = (source / "lib/components/fabro-petri/src/interview.rs").read_text()
            self.assertIn("Approval::Prompt => tokio::select!", interview)
            self.assertIn("submission = self.answers.ask(legacy)", interview)
        self.assertEqual(methods[0], methods[1])

    def test_docker_resource_wiring_gap_exists_in_both_versions(self):
        for source, petri, _ in self.sources:
            engine = (source / "lib/components/fabro-petri/src/engine.rs").read_text()
            self.assertIn("if backend == SandboxBackend::Daytona {\n        options.sandbox.daytona_resources", engine)
            executor = (petri / "crates/core/executor-sandbox/src/lib.rs").read_text()
            docker = section(executor, "fn build_spec(\n    scope:", "fn registry_auth(")
            self.assertNotIn(".resources", docker)
            frontend = (petri / "crates/attractor/frontend/src/lower/mod.rs").read_text()
            self.assertIn("options:     ir::ContainerOptions::default()", frontend)

    def test_goal_gate_and_default_budget_lowering_are_identical(self):
        loops = [(petri / "crates/attractor/frontend/src/lower/loops.rs").read_text()
                 for _, petri, _ in self.sources]
        for _, petri, _ in self.sources:
            lowering = (petri / "crates/attractor/frontend/src/lower/mod.rs").read_text()
            self.assertIn("pub const MAX_FIRINGS: u32 = 500;", lowering)
        self.assertEqual(loops[0], loops[1])
        for expression in (
            '"attractor.goal_gate_without_target"',
            '"info.budget.default"',
            'self.b.exprs().path("nodes", &[&gate.id, "success_like"])',
            "explicit.map_or(MAX_FIRINGS",
        ):
            self.assertIn(expression, loops[1])

    def test_both_offline_validators_report_identical_controls_for_all_nine_entrypoints(self):
        self.assertTrue(Path("/usr/bin/sandbox-exec").is_file(), "macOS sandbox-exec required")
        with tempfile.TemporaryDirectory(prefix="memba-controls-", dir=UPSTREAM) as temporary:
            scratch = Path(temporary).resolve()
            checkout = scratch / "source"
            shutil.copytree(WORKFLOWS, checkout / ".fabro/workflows", ignore=shutil.ignore_patterns("__pycache__"))
            (scratch / "home").mkdir()
            binaries = [binary.resolve() for _, _, binary in self.sources]
            profile = scratch / "offline.sb"
            profile.write_text(
                '(version 1)\n(allow default)\n(deny network*)\n(deny process-exec)\n'
                + '(allow process-exec ' + ' '.join(f'(literal "{binary}")' for binary in binaries) + ')\n'
                + f'(deny file-write* (require-not (subpath "{scratch}")))\n'
            )
            environment = {
                "HOME": str(scratch / "home"), "FABRO_HOME": str(scratch / "home/.fabro"),
                "XDG_CACHE_HOME": str(scratch / "home/cache"), "PATH": "/usr/bin:/bin",
                "FABRO_TELEMETRY": "off", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
            }
            results = []
            for binary, version in zip(binaries, VERSIONS):
                version_result = subprocess.run(
                    ["/usr/bin/sandbox-exec", "-f", str(profile), str(binary), "--version"],
                    cwd=checkout, env=environment, capture_output=True, text=True, timeout=10,
                )
                self.assertEqual(version_result.returncode, 0)
                self.assertIn(version, version_result.stdout)
                summaries = {}
                for path in sorted((checkout / ".fabro/workflows").rglob("workflow.toml")):
                    result = subprocess.run(
                        ["/usr/bin/sandbox-exec", "-f", str(profile), str(binary),
                         "--json", "validate", str(path.relative_to(checkout))],
                        cwd=checkout, env=environment, capture_output=True, text=True, timeout=60,
                    )
                    self.assertEqual(result.returncode, 0, "Offline validation failed; raw diagnostics withheld")
                    parsed = json.loads(result.stdout)
                    self.assertTrue(parsed["valid"])
                    summaries[str(path.relative_to(checkout))] = {
                        key: parsed[key] for key in ("nodes", "edges", "diagnostics")
                    }
                self.assertEqual(len(summaries), 9)
                results.append(summaries)
            self.assertTrue(results[0] == results[1], "Old/target control diagnostics differ")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--upstream-root", type=Path)
    arguments, remaining = parser.parse_known_args()
    UPSTREAM = arguments.upstream_root.resolve() if arguments.upstream_root else None
    unittest.main(argv=[__file__, *remaining])
