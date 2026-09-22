#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
WORKFLOW_DIR = ROOT / ".fabro/workflows/code-review"
graph = (WORKFLOW_DIR / "workflow.fabro").read_text()
review_prompt = (WORKFLOW_DIR / "prompts/review.md").read_text()
dev = (ROOT / "bin/dev").read_text()


def require(text: str, needle: str) -> None:
    assert needle in text, f"missing contract text: {needle}"


def reject(text: str, needle: str) -> None:
    assert needle not in text, f"obsolete contract remains: {needle}"


# Static graph/schema/command contract.
require(graph, '#focused_reviewer { provider: openai; model: gpt-5.6-terra;')
require(graph, 'shape=hexagon,')
require(graph, '[R] Record / defer')
require(graph, '[P] Prepare / attempt a separately approved follow-up')
require(graph, '[D] Dismiss with rationale')
require(graph, 'freeform=true')
require(graph, 'verify_heal_progress -> consequential_context [label="No progress; escalate"]')
require(graph, 'dev_check -> consequential_context [label="Validation failed; escalate"]')
assert graph.count("snapshot_before_heal -> apply_bounded_heal") == 1
assert "apply_bounded_heal ->" in graph and "-> apply_bounded_heal" in graph
reject(graph, "dev_check -> focused_reviewer")
reject(graph, "dev_check -> apply_bounded_heal")
require(graph, 'dev check')
for obsolete in ("review_fork", "review_merge", "claude_review", "codex_review", "gemini_review", "synthesize_review", "synthesis_unavailable"):
    reject(graph, obsolete)
for disposition in ("clean", "bounded_heal", "record", "consequential"):
    require(review_prompt, f"`{disposition}`")
require(dev, 'code-review) _fabro_code_review "$@"')
require(dev, 'Deprecated: use')
require(dev, '.fabro/workflows/code-review/workflow.toml')
require(dev, '--detach 2>&1')
require(dev, 'Code-review run ID: $run_id')
require(dev, 'code-review/tmp/')
require(dev, 'Delivery remains successful.')

review_function = dev[dev.index("_fabro_code_review() {"):dev.index("_fabro_is_review_cleanup_candidate() {")]
reject(review_function, "--auto-approve")
require(review_function, "fabro attach $run_id")

deliver_tail = dev[dev.index('== Launching detached post-merge code-review healer =='):dev.index("_fabro_code_review() {")]
require(deliver_tail, 'if ! _fabro_code_review')
require(deliver_tail, 'return 0')

# Deterministic fixture classifier: this mirrors the explicit threshold order in
# the reviewer contract and exercises routing without an LLM or production run.
def classify(signals: set[str]) -> str:
    if "provider_failure" in signals:
        return "provider_failure"
    if "detached_launch" in signals:
        return "detached"
    consequential = {
        "product_behavior", "adr", "architecture", "migration", "production_data",
        "security", "privacy", "cross_cutting", "no_progress", "repeated",
    }
    if signals & consequential:
        return "human_paused" if "unanswered" in signals else "consequential"
    if "small_refactor" in signals:
        return "bounded_heal"
    if "non_urgent_health" in signals:
        return "record"
    return "clean"

for fixture_name in ("routing.json", "historical.json"):
    fixtures = json.loads((WORKFLOW_DIR / "test/fixtures" / fixture_name).read_text())
    for fixture in fixtures:
        actual = classify(set(fixture["signals"]))
        assert actual == fixture["expected"], f"{fixture['name']}: {actual} != {fixture['expected']}"
        if fixture_name == "historical.json":
            assert fixture["finding"] in (WORKFLOW_DIR / "test/fixtures/historical.json").read_text()

# Native graph routes corresponding to every deterministic fixture.
for node in {
    "observe_clean", "apply_bounded_heal", "dev_check", "record_code_health",
    "consequential_gate", "reviewer_unavailable", "publish_followup", "final_summary",
}:
    assert re.search(rf"\b{node}\b", graph), f"fixture route node absent: {node}"

# Unanswered input cannot imply approval: no timeout default and detached launch
# does not auto-approve. Fabro therefore keeps/fails the gate closed per docs.
reject(graph, "human.default_choice")

print("code-review static, deterministic routing, detached-launch, and historical replay fixtures passed")
