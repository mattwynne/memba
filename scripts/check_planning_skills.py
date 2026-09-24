#!/usr/bin/env python3
"""Structural contracts for the composable iteration-planning skills."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / ".pi" / "skills"


def text(name: str) -> str:
    path = SKILLS / name / "SKILL.md"
    if not path.is_file():
        raise AssertionError(f"missing skill: {path.relative_to(ROOT)}")
    return path.read_text()


def require(content: str, needles: list[str], subject: str) -> None:
    missing = [needle for needle in needles if needle.lower() not in content.lower()]
    if missing:
        raise AssertionError(f"{subject} missing: {', '.join(missing)}")


# Every project-local skill must remain discoverable and named after its directory.
for path in sorted(SKILLS.glob("*/SKILL.md")):
    content = path.read_text()
    match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    if not match:
        raise AssertionError(f"invalid frontmatter: {path.relative_to(ROOT)}")
    frontmatter = match.group(1)
    name = re.search(r"^name:\s*(.+)$", frontmatter, re.MULTILINE)
    description = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
    if not name or not description:
        raise AssertionError(f"incomplete frontmatter: {path.relative_to(ROOT)}")
    if name.group(1).strip() != path.parent.name:
        raise AssertionError(f"skill name/directory mismatch: {path.relative_to(ROOT)}")

ensemble = text("ensemble-review")
require(
    ensemble,
    [
        "Subject",
        "Artifact",
        "Focus",
        "Rubric",
        "Known questions",
        "Constraints",
        "Feedback route",
        "Anthropic Claude",
        "OpenAI GPT",
        "Google Gemini",
        "bb provider list",
        "bb provider models",
        "do not hardcode model versions",
        "deduplicate",
        "disagreement",
        "degraded coverage",
    ],
    "ensemble-review generic contract",
)
for leaked_rubric in ["gherkin", "example map", "domain model", "technical scope", "adr"]:
    if leaked_rubric in ensemble.lower():
        raise AssertionError(f"ensemble-review contains caller-specific rubric term: {leaked_rubric}")
if re.search(r"\b(?:claude|gpt|gemini)[-_ ]?\d", ensemble, re.IGNORECASE):
    raise AssertionError("ensemble-review hardcodes a model version")

callers = {
    "bdd-discovery": ["Subject", "Artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
    "behaviour-iteration-planning": ["Subject/artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
    "technical-iteration-planning": ["Subject/artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
    "architecture-decision-records": ["Subject", "Artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
}
for name, fields in callers.items():
    content = text(name)
    require(content, fields, f"{name} caller-owned review brief")
    if "`ensemble-review` in" in content or re.search(r"ensemble-review.*\bmode\b", content, re.IGNORECASE):
        raise AssertionError(f"{name} still delegates a hardcoded ensemble mode")

behaviour = text("behaviour-iteration-planning")
formulation = text("bdd-formulation")
modelling = text("domain-modelling")
vocabulary = text("domain-vocabulary")
technical = text("technical-iteration-planning")
adr = text("architecture-decision-records")

for name, content in {
    "behaviour-iteration-planning": behaviour,
    "bdd-formulation": formulation,
    "domain-modelling": modelling,
    "domain-vocabulary": vocabulary,
}.items():
    require(content, ["docs/problem-domain-terms.md", "Matt"], f"{name} vocabulary ownership")

require(formulation, ["Temporal Formulation", "decision", "later state change", "ordering", "temporary", "backfilled"], "bdd-formulation temporal checks")
require(modelling, ["bdd-formulation", "domain-vocabulary", "solution-domain", "repeat"], "domain-model vocabulary feedback loop")
require(vocabulary, ["problem-domain", "solution-domain", "explicit agreement", "bdd-formulation"], "domain-vocabulary boundary")
require(behaviour, ["architecture-decision-records", "domain-vocabulary", "repeat the formulated-feature ensemble"], "behaviour planning composition")
require(technical, ["architecture-decision-records", "domain-vocabulary", "problem-domain lexicon"], "technical planning composition")
require(adr, ["agreed behaviour/domain model or technical design", "explicit acceptance", "None required"], "shared ADR collaboration")

print("Planning skill structural check passed")
