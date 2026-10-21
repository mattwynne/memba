import hashlib
import re
import shutil
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


PLAN = Path(__file__).resolve().parents[1]
SCENARIO = PLAN.parent / "bdd-scenario-implementation"


def node_thread(graph, node):
    line = next(line for line in graph.splitlines() if re.match(rf"\s*{node} \[", line))
    match = re.search(r'thread_id="([^"]+)"', line)
    return match.group(1) if match else None


class ScenarioBoundaryTest(unittest.TestCase):
    def setUp(self):
        self.plan_config = tomllib.loads((PLAN / "workflow.toml").read_text())
        self.plan_graph_path = (PLAN / self.plan_config["workflow"]["graph"]).resolve()
        self.plan_graph = self.plan_graph_path.read_text()
        self.scenario_graph = (SCENARIO / "workflow.fabro").read_text()
        self.selector_prompt = (PLAN / "eval/selection/prompt.md").read_text()
        self.plan_readme = (PLAN / "README.md").read_text()
        self.scenario_prompt = (SCENARIO / "prompts/bdd-navigator.md").read_text()
        self.driver_prompt = (SCENARIO / "prompts/bdd-driver.md").read_text()

    def test_fresh_selector_is_separate_from_continuing_implementation_navigator(self):
        self.assertEqual(node_thread(self.scenario_graph, "navigator"), "bdd-navigator")
        self.assertIsNone(node_thread(self.plan_graph, "selector"))
        self.assertIn('navigator [prompt="@prompts/bdd-navigator.md", fidelity="full"', self.scenario_graph)
        self.assertIn('driver [prompt="@prompts/bdd-driver.md", fidelity="truncate"]', self.scenario_graph)
        selector = next(line for line in self.plan_graph.splitlines() if re.match(r"\s*selector \[", line))
        self.assertIn('fidelity="truncate"', selector)
        self.assertIn('prompt="@bdd-plan-implementation/eval/selection/prompt.md"', selector)
        self.assertEqual(self.plan_graph_path.parent, SCENARIO.parent)
        self.assertNotIn("thread_id=", selector)
        self.assertNotIn("output_schema=", selector)
        self.assertNotIn("thread_id=", next(
            line for line in self.scenario_graph.splitlines() if re.match(r"\s*driver \[", line)
        ))
        self.assertIn("fresh selector", self.plan_readme)
        self.assertIn("literal run input `HEAD`", self.plan_readme)

    def test_selector_prompt_keeps_canonical_body_with_only_head_input_substitution(self):
        self.assertEqual(
            hashlib.sha256(self.selector_prompt.encode()).hexdigest(),
            "dd77504e70b6171b8cd816cd6fee6ce87eebbaf410f94e0519e716e4cbc9d4e6",
        )
        self.assertEqual(self.plan_config["run"]["inputs"], {"commit": "HEAD"})
        rendered = self.selector_prompt.replace("{{ inputs.commit }}", "HEAD")
        self.assertEqual(
            rendered,
            self.selector_prompt.replace("At Git commit `{{ inputs.commit }}`", "At Git commit `HEAD`"),
        )

    def test_setup_rejects_overridden_binding_with_supported_script_substitution(self):
        setup = next(line for line in self.plan_graph.splitlines() if re.match(r"\s*setup \[", line))
        self.assertIn("script=\"node dev-tools/bdd/workflow.cjs setup {{ inputs.commit }}\"", setup)
        self.assertNotIn("setup '{{ inputs.commit }}'", setup)
        self.assertNotIn('setup "{{ inputs.commit }}"', setup)

    def test_declared_dependency_bootstrap_runs_once_before_inspection(self):
        self.assertIn(
            'bootstrap [shape=parallelogram, script="npm ci --prefix acceptance-tests --no-audit"]',
            self.plan_graph,
        )
        self.assertIn("start -> setup", self.plan_graph)
        self.assertIn('setup -> bootstrap [condition="outcome=succeeded && preferred_label=bootstrap"]', self.plan_graph)
        self.assertIn('bootstrap -> inspect [condition="outcome=succeeded"]', self.plan_graph)
        self.assertIn("bootstrap -> failed_stop", self.plan_graph)
        self.assertEqual(self.plan_graph.count("-> bootstrap"), 1)

    def test_native_routing_owns_inspect_select_pick_import_repeat_and_done(self):
        self.assertIn('inspect [shape=parallelogram, output_schema="routing"', self.plan_graph)
        self.assertIn('validate_pick [shape=parallelogram, stdin_source="response.selector", output_schema="routing"', self.plan_graph)
        self.assertIn('scenario [import="bdd-scenario-implementation/workflow.fabro"]', self.plan_graph)
        self.assertIn('inspect -> selector [condition="outcome=succeeded && preferred_label=choose"]', self.plan_graph)
        self.assertIn('inspect -> done [condition="outcome=succeeded && preferred_label=done"]', self.plan_graph)
        self.assertIn('validate_pick -> prepare_scenario [condition="outcome=succeeded && preferred_label=implement"]', self.plan_graph)
        self.assertIn("scenario -> inspect", self.plan_graph)
        self.assertNotIn("selector -> done", self.plan_graph)
        self.assertNotIn("domain_loop_done", self.plan_graph)

    def test_failed_commands_cannot_reach_normal_done(self):
        for node in ("bootstrap", "setup", "inspect", "selector", "validate_pick", "prepare_scenario"):
            self.assertIn(f"{node} -> failed_stop", self.plan_graph)
        self.assertNotRegex(self.plan_graph, r"failed_stop\s*->")
        self.assertEqual(self.plan_graph.count("-> done"), 1)

    def test_next_scenario_archives_all_prior_scratch_before_recreating_it(self):
        self.assertIn("prepare_scenario [shape=parallelogram", self.plan_graph)
        archive = "mv $scratch $archive_root/$sequence"
        recreate = "mkdir -p $scratch"
        self.assertIn("archive_root=.fabro/tmp/bdd-plan/scenarios", self.plan_graph)
        self.assertIn("scratch=.fabro/tmp/bdd", self.plan_graph)
        self.assertIn("test -e $scratch && ! test -d $scratch", self.plan_graph)
        self.assertIn("find $scratch -mindepth 1 -maxdepth 1 -print -quit", self.plan_graph)
        self.assertIn(archive, self.plan_graph)
        self.assertGreater(self.plan_graph.rindex(recreate), self.plan_graph.index(archive))
        self.assertIn(
            'validate_pick -> prepare_scenario [condition="outcome=succeeded && preferred_label=implement"]',
            self.plan_graph,
        )
        self.assertIn('prepare_scenario -> scenario [condition="outcome=succeeded"]', self.plan_graph)

    def test_prepare_command_preserves_each_scenario_directory(self):
        match = re.search(
            r'prepare_scenario \[shape=parallelogram, script="([^"]+)"\]',
            self.plan_graph,
        )
        self.assertIsNotNone(match)
        command = match.group(1)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["sh", "-c", command], cwd=root, check=True)
            scratch = root / ".fabro/tmp/bdd"
            self.assertTrue(scratch.is_dir())
            # Partial scratch without a base is still stale and must be archived.
            (scratch / "result.md").write_text("partial result\n")
            (scratch / "check.log").write_text("partial check\n")

            subprocess.run(["sh", "-c", command], cwd=root, check=True)
            first = root / ".fabro/tmp/bdd-plan/scenarios/1"
            self.assertFalse((first / "base").exists())
            self.assertEqual((first / "result.md").read_text(), "partial result\n")
            self.assertEqual((first / "check.log").read_text(), "partial check\n")
            self.assertEqual(list(scratch.iterdir()), [])
            (scratch / "base").write_text("second-base\n")
            (scratch / "result.md").write_text("second result\n")

            subprocess.run(["sh", "-c", command], cwd=root, check=True)
            second = root / ".fabro/tmp/bdd-plan/scenarios/2"
            self.assertEqual((second / "base").read_text(), "second-base\n")
            self.assertEqual((second / "result.md").read_text(), "second result\n")
            self.assertEqual((first / "result.md").read_text(), "partial result\n")
            self.assertEqual(list(scratch.iterdir()), [])

    def test_prepare_command_rejects_a_non_directory_scratch_path(self):
        match = re.search(
            r'prepare_scenario \[shape=parallelogram, script="([^"]+)"\]',
            self.plan_graph,
        )
        self.assertIsNotNone(match)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            scratch = root / ".fabro/tmp/bdd"
            scratch.parent.mkdir(parents=True)
            scratch.write_text("not a directory\n")
            result = subprocess.run(
                ["sh", "-c", match.group(1)],
                cwd=root,
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("not a directory", result.stderr)

    def test_prepare_command_rejects_a_symlinked_scratch_directory(self):
        match = re.search(
            r'prepare_scenario \[shape=parallelogram, script="([^"]+)"\]',
            self.plan_graph,
        )
        self.assertIsNotNone(match)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "old-scratch"
            old.mkdir()
            (old / "old.log").write_text("must not be reused\n")
            scratch = root / ".fabro/tmp/bdd"
            scratch.parent.mkdir(parents=True)
            scratch.symlink_to(old, target_is_directory=True)
            result = subprocess.run(
                ["sh", "-c", match.group(1)],
                cwd=root,
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("symbolic link", result.stderr)
            self.assertTrue(scratch.is_symlink())
            self.assertEqual((old / "old.log").read_text(), "must not be reused\n")

    def test_prepare_command_rejects_a_symlinked_archive_parent(self):
        match = re.search(
            r'prepare_scenario \[shape=parallelogram, script="([^"]+)"\]',
            self.plan_graph,
        )
        self.assertIsNotNone(match)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            victim = root / "archive-victim"
            victim.mkdir()
            plan = root / ".fabro/tmp/bdd-plan"
            plan.mkdir(parents=True)
            (plan / "scenarios").symlink_to(victim, target_is_directory=True)
            scratch = root / ".fabro/tmp/bdd"
            scratch.mkdir()
            (scratch / "check.log").write_text("must stay here\n")

            result = subprocess.run(
                ["sh", "-c", match.group(1)],
                cwd=root,
                text=True,
                capture_output=True,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("symbolic link", result.stderr)
            self.assertEqual(list(victim.iterdir()), [])
            self.assertEqual((scratch / "check.log").read_text(), "must stay here\n")

    def test_full_check_has_native_thirty_minute_allowance_and_supported_exit_boundary(self):
        check = next(line for line in self.scenario_graph.splitlines() if re.match(r"\s*check \[", line))
        self.assertIn('timeout="1800s"', check)
        self.assertIn('check -> checked [condition="outcome=succeeded"]', self.scenario_graph)
        self.assertIn("checked -> done", self.scenario_graph)
        self.assertIn('check -> navigator [condition="outcome=failed"]', self.scenario_graph)

    @unittest.skipUnless(shutil.which("fabro"), "Fabro CLI is not installed")
    def test_real_parent_import_resolves_both_reusable_role_prompt_files(self):
        source_root = PLAN.parents[2]
        result = subprocess.run(
            ["fabro", "--no-upgrade-check", "validate",
             str((PLAN / "workflow.toml").relative_to(source_root))],
            cwd=source_root,
            text=True,
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Validation: OK", result.stdout + result.stderr)

    def test_role_editing_guidance_does_not_contradict_the_native_editor(self):
        for prompt in (self.scenario_prompt, self.driver_prompt):
            self.assertIn("normal file-editing tools", prompt)
            self.assertNotIn("Use shell commands for all file writes", prompt)
            self.assertNotIn("Do not use `apply_patch`", prompt)
            self.assertIn("Do not repair ownership with chmod/chown", prompt)

    def test_prompts_distinguish_memory_from_current_evidence(self):
        self.assertIn("commit", self.selector_prompt)
        self.assertIn("current", self.scenario_prompt)
        self.assertIn("stale", self.scenario_prompt)
        self.assertNotIn("conversation continues", self.selector_prompt)
        self.assertIn("conversation continues", self.scenario_prompt)
        self.assertIn("fresh driver", self.scenario_prompt)
        self.assertIn("one assignment", self.driver_prompt)
        self.assertIn("already passes", self.scenario_prompt)
        self.assertIn("do not invent", self.scenario_prompt)


if __name__ == "__main__":
    unittest.main()
