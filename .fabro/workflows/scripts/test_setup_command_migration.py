#!/usr/bin/env python3
"""Offline contracts for the two run.prepare -> setup_mix migrations.

No scripts, workflows, hooks, sandboxes, or models are executed. The projection
snapshots below are from 5a6a2152813bd92147c7dd6aea0156834de252e2: remove only
run.prepare from TOML, and undo only the setup node/edges in DOT. They protect
checkout/environment scope and every downstream node, edge attribute, prompt,
and model selector; refresh deliberately when those authored contracts change.
"""

import hashlib
import json
from pathlib import Path
import re
import shlex
import tomllib
import unittest

WORKFLOWS = Path(__file__).resolve().parents[1]
CONTRACTS = {
    "code-review": {
        "successor": "read_plan",
        "graph_sha256": "7a562a44e660b64324be03a4e7c7f1706dea80542c8227635305d1b81b6b9df4",
        "config_sha256": "6844e200a25a352b15745b7ab9c18d3270b7b5f4746e0e79b9fd9370f1e551d4",
    },
    "iteration-implementation": {
        "successor": "verify_source_head",
        "graph_sha256": "fd37d5a8c99063b856f330245c6216ce3567e6d970a56939b47757e7ea90cf12",
        "config_sha256": "e691d1047d547b3d781f2fd3b43161195052e5c5813fb584eba7d1af349a546d",
    },
}
SETUP_NODE = re.compile(
    r"    // Preparation used a five-minute per-command timeout and stopped on failure\.\n"
    r"    setup_mix \[\n(?P<attributes>.*?)    \]\n\n",
    re.DOTALL,
)
ATTRIBUTE = re.compile(r'\s*(\w+)\s*=\s*("(?:[^"\\]|\\.)*"|\w+)\s*,?\s*')
EDGE = re.compile(r"^\s*(\w+)\s*->\s*(\w+)([^\n]*)$", re.MULTILINE)


def setup_attributes(test, graph):
    matches = list(SETUP_NODE.finditer(graph))
    test.assertEqual(len(matches), 1)
    remaining = matches[0]["attributes"]
    attributes = {}
    while remaining:
        match = ATTRIBUTE.match(remaining)
        test.assertIsNotNone(match, "Unparsed setup attribute")
        key, value = match.groups()
        test.assertNotIn(key, attributes)
        attributes[key] = json.loads(value) if value.startswith('"') else value
        remaining = remaining[match.end():]
    return attributes


class SetupCommandMigrationTest(unittest.TestCase):
    def test_no_retired_prepare_setting_in_any_authored_workflow(self):
        configs = sorted(WORKFLOWS.rglob("*.toml"))
        self.assertTrue(configs)
        for path in configs:
            with self.subTest(workflow=path.relative_to(WORKFLOWS)):
                config = tomllib.loads(path.read_text())
                # Presence, including an empty table, is rejected by 0.408.
                self.assertNotIn("prepare", config.get("run", {}))

    def test_literal_argv_after_dot_and_shell_decoding(self):
        for name in CONTRACTS:
            with self.subTest(workflow=name):
                graph = (WORKFLOWS / name / "workflow.fabro").read_text()
                script = setup_attributes(self, graph)["script"]
                expected_argv = [
                    "bash",
                    f"/workspace/memba/.fabro/workflows/{name}/prepare_mix.sh",
                ]
                self.assertTrue(
                    shlex.split(script, posix=True) == expected_argv,
                    "Setup must decode to the original literal argv",
                )
                # Every original argument is a shell literal, not an expansion.
                self.assertTrue(
                    script == " ".join(f"'{arg}'" for arg in expected_argv),
                    "Each setup argument must be single-quoted",
                )

    def test_five_minute_fail_closed_setup_without_retries(self):
        for name in CONTRACTS:
            with self.subTest(workflow=name):
                graph = (WORKFLOWS / name / "workflow.fabro").read_text()
                attributes = setup_attributes(self, graph)
                script = attributes.pop("script")
                self.assertTrue(script)
                self.assertEqual(attributes, {
                    "label": "Prepare Mix",
                    "shape": "parallelogram",
                    "timeout": "5m",
                    "on_failure": "exit",
                    "max_retries": "0",
                })
                # No inherited retry/exhaustion overrides or alternate scope.
                for key in (
                    "default_max_retries", "on_retries_exhausted", "retry_target",
                    "fallback_retry_target", "working_dir", "environment",
                ):
                    self.assertNotRegex(graph, rf"\b{key}\s*=")

    def test_setup_precedes_original_first_node_without_bypass(self):
        for name, contract in CONTRACTS.items():
            with self.subTest(workflow=name):
                graph = (WORKFLOWS / name / "workflow.fabro").read_text()
                edges = EDGE.findall(graph)
                self.assertEqual(
                    [edge for edge in edges if edge[0] in ("start", "setup_mix")],
                    [("start", "setup_mix", ""), ("setup_mix", contract["successor"], "")],
                )
                self.assertEqual(
                    [edge for edge in edges if edge[1] == "setup_mix"],
                    [("start", "setup_mix", "")],
                )

    def test_downstream_graph_and_remaining_settings_are_unchanged(self):
        for name, contract in CONTRACTS.items():
            with self.subTest(workflow=name):
                folder = WORKFLOWS / name
                graph = (folder / "workflow.fabro").read_text()
                original, removed = SETUP_NODE.subn("", graph)
                self.assertEqual(removed, 1)
                successor = contract["successor"]
                chain = f"    start -> setup_mix\n    setup_mix -> {successor}\n"
                self.assertEqual(original.count(chain), 1)
                original = original.replace(chain, f"    start -> {successor}\n")
                self.assertEqual(hashlib.sha256(original.encode()).hexdigest(), contract["graph_sha256"])
                config = tomllib.loads((folder / "workflow.toml").read_text())
                self.assertEqual(
                    hashlib.sha256(json.dumps(config, sort_keys=True).encode()).hexdigest(),
                    contract["config_sha256"],
                )


if __name__ == "__main__":
    unittest.main()
