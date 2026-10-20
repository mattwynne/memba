import re
from pathlib import Path
import subprocess
import tempfile
import unittest


PLAN = Path(__file__).resolve().parents[1]
SCENARIO = PLAN.parent / "bdd-scenario-implementation"


def navigator_thread(graph):
    line = next(line for line in graph.splitlines() if re.match(r"\s*navigator \[", line))
    match = re.search(r'thread_id="([^"]+)"', line)
    return match.group(1) if match else None


class ScenarioBoundaryTest(unittest.TestCase):
    def setUp(self):
        self.plan_graph = (PLAN / "workflow.fabro").read_text()
        self.scenario_graph = (SCENARIO / "workflow.fabro").read_text()
        self.plan_prompt = (PLAN / "prompts/navigator.md").read_text()
        self.plan_readme = (PLAN / "README.md").read_text()
        self.scenario_prompt = (SCENARIO / "prompts/bdd-navigator.md").read_text()
        self.driver_prompt = (SCENARIO / "prompts/bdd-driver.md").read_text()

    def test_only_implementation_navigator_uses_the_continuing_thread(self):
        self.assertEqual(navigator_thread(self.scenario_graph), "bdd-navigator")
        self.assertNotEqual(navigator_thread(self.plan_graph), "bdd-navigator")
        self.assertIn('navigator [prompt="@prompts/bdd-navigator.md", fidelity="full"', self.scenario_graph)
        self.assertIn('driver [prompt="@prompts/bdd-driver.md", fidelity="truncate"]', self.scenario_graph)
        self.assertNotIn("thread_id=", next(
            line for line in self.scenario_graph.splitlines() if re.match(r"\s*driver \[", line)
        ))
        self.assertIn("fresh session", self.plan_readme)
        self.assertIn("only the current commit", self.plan_readme)

    def test_next_scenario_archives_all_prior_scratch_before_recreating_it(self):
        self.assertIn("prepare_scenario [shape=parallelogram", self.plan_graph)
        archive = "mv .fabro/tmp/bdd $archive_root/$sequence"
        recreate = "mkdir -p .fabro/tmp/bdd"
        self.assertIn("archive_root=.fabro/tmp/bdd-plan/scenarios", self.plan_graph)
        self.assertIn("scratch=.fabro/tmp/bdd", self.plan_graph)
        self.assertIn("test -e $scratch && ! test -d $scratch", self.plan_graph)
        self.assertIn("find $scratch -mindepth 1 -maxdepth 1 -print -quit", self.plan_graph)
        self.assertIn(archive, self.plan_graph)
        self.assertGreater(self.plan_graph.rindex(recreate), self.plan_graph.index(archive))
        self.assertIn(
            'navigator -> prepare_scenario [condition="outcome=succeeded && preferred_label=implement"]',
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

    def test_full_check_has_native_thirty_minute_allowance_and_supported_exit_boundary(self):
        check = next(line for line in self.scenario_graph.splitlines() if re.match(r"\s*check \[", line))
        self.assertIn('timeout="1800s"', check)
        self.assertIn('check -> checked [condition="outcome=succeeded"]', self.scenario_graph)
        self.assertIn("checked -> done", self.scenario_graph)
        self.assertIn('check -> navigator [condition="outcome=failed"]', self.scenario_graph)

    def test_prompts_distinguish_memory_from_current_evidence(self):
        for prompt in (self.plan_prompt, self.scenario_prompt):
            self.assertIn("current", prompt)
            self.assertIn("stale", prompt)
        self.assertNotIn("conversation continues", self.plan_prompt)
        self.assertIn("conversation continues", self.scenario_prompt)
        self.assertIn("fresh driver", self.scenario_prompt)
        self.assertIn("one assignment", self.driver_prompt)
        self.assertIn("already passes", self.scenario_prompt)
        self.assertIn("do not invent", self.scenario_prompt)


if __name__ == "__main__":
    unittest.main()
