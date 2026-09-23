#!/usr/bin/env python3
"""Structural policy checks; runtime routing is covered by test_code_review_runtime.py."""
from pathlib import Path
import json
import re
import tomllib

ROOT = Path(__file__).resolve().parents[4]
WORKFLOW = ROOT / ".fabro/workflows/code-review"
graph = (WORKFLOW / "workflow.fabro").read_text()
prompt = (WORKFLOW / "prompts/review.md").read_text()
dev = (ROOT / "bin/dev").read_text()
config = tomllib.loads((WORKFLOW / "workflow.toml").read_text())

# Slack is an optional delivery surface for the existing web-backed interviewer.
# The human gate remains available in Fabro web/CLI if Slack delivery is unavailable.
assert config["run"]["interviews"] == {
    "provider": "slack",
    "slack": {"channel": "#memba"},
}

# Provider/design policy that cannot be inferred from command-only runtime fixtures.
assert '#focused_reviewer { provider: openai; model: gpt-5.6-terra;' in graph
for obsolete in ("review_fork", "review_merge", "claude_review", "gemini_review", "synthesize_review"):
    assert obsolete not in graph
for disposition in ("clean", "bounded_heal", "record", "consequential"):
    assert f"`{disposition}`" in prompt

# Historical findings are source-backed contract examples, not simulated model
# classifications. They prove that the prompt names the applicable threshold
# and that the retained source excerpt still exists.
fixture_path = WORKFLOW / "test/fixtures/historical_contract_examples.json"
fixture = json.loads(fixture_path.read_text())
assert "do not test or claim LLM classification effectiveness" in fixture["description"]
for example in fixture["examples"]:
    source = ROOT / example["source"]
    assert example["source_excerpt"] in source.read_text(), example["name"]
    for term in example["required_contract_terms"]:
        assert term in prompt, (example["name"], term)
assert not (WORKFLOW / "test/fixtures/routing.json").exists()

# Exactly one repair entry and no repair loop; runtime coverage proves both the
# successful and no-progress outgoing routes execute as encoded.
assert graph.count("snapshot_before_heal -> apply_bounded_heal") == 1
assert len(re.findall(r"^\s*\w+ -> apply_bounded_heal\b", graph, re.M)) == 1
assert "dev_check -> apply_bounded_heal" not in graph
assert 'verify_heal_progress -> consequential_context [label="No progress; escalate"]' in graph

# The first human choice is deliberately non-mutating because Fabro's explicit
# --auto-approve mode selects it. Canonical review launch itself must omit that flag.
gate_edges = re.findall(r"^\s*consequential_gate -> .*", graph, re.M)
assert gate_edges[0].endswith('[label="[R] Record / defer"]')
review_function = dev[dev.index("_fabro_code_review() {"):dev.index("_fabro_is_review_cleanup_candidate() {")]
assert "--auto-approve" not in review_function
assert '-I "candidate_sha=$candidate_sha"' in review_function
assert "--detach 2>&1" in review_function

print("code-review structural provider, one-pass, human-choice, and detached-launch policy checks passed")
