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


def frontmatter_values(path: Path, content: str) -> dict[str, str]:
    match = re.match(r"---\n(.*?)\n---\n", content, re.DOTALL)
    if not match:
        raise AssertionError(f"invalid frontmatter delimiters: {path.relative_to(ROOT)}")
    values: dict[str, str] = {}
    parent_key: str | None = None
    for line in match.group(1).splitlines():
        if not line.strip() or "\t" in line:
            raise AssertionError(f"invalid frontmatter line: {path.relative_to(ROOT)}: {line!r}")
        if line.startswith(" "):
            if parent_key is None or not re.match(r"^  [A-Za-z][A-Za-z0-9_-]*:\s*\S.*$", line):
                raise AssertionError(f"invalid nested frontmatter: {path.relative_to(ROOT)}: {line!r}")
            continue
        item = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):\s*(.*)$", line)
        if not item or item.group(1) in values:
            raise AssertionError(f"invalid frontmatter entry: {path.relative_to(ROOT)}: {line!r}")
        parent_key, value = item.groups()
        if value[:1] in {'"', "'"} and (len(value) < 2 or value[-1] != value[0]):
            raise AssertionError(f"unclosed frontmatter quote: {path.relative_to(ROOT)}: {line!r}")
        values[parent_key] = value.strip().strip('"\'')
    return values


def validate_dot(path: Path, content: str) -> None:
    for index, graph in enumerate(re.findall(r"```dot\n(.*?)```", content, re.DOTALL), start=1):
        if graph.count("{") != graph.count("}") or "->" not in graph:
            raise AssertionError(f"invalid or edgeless DOT graph: {path.relative_to(ROOT)} #{index}")
        definitions = set(re.findall(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\[", graph, re.MULTILINE))
        references: set[str] = set()
        for line in graph.splitlines():
            if "->" in line:
                references.update(re.findall(r"(?:^|->)\s*([A-Za-z_][A-Za-z0-9_]*)", line))
        missing = references - definitions
        if missing:
            raise AssertionError(f"undefined DOT nodes in {path.relative_to(ROOT)} #{index}: {sorted(missing)}")


# Every project-local skill must remain discoverable, structurally valid, and named after its directory.
all_skill_text = ""
for path in sorted(SKILLS.glob("*/SKILL.md")):
    content = path.read_text()
    values = frontmatter_values(path, content)
    if not values.get("name") or not values.get("description"):
        raise AssertionError(f"incomplete frontmatter: {path.relative_to(ROOT)}")
    if values["name"] != path.parent.name:
        raise AssertionError(f"skill name/directory mismatch: {path.relative_to(ROOT)}")
    validate_dot(path, content)
    all_skill_text += content

if "architecture-decision-records" in all_skill_text or (SKILLS / "architecture-decision-records").exists():
    raise AssertionError("obsolete architecture-decision-records skill reference remains")

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
    "record-architectural-decisions": ["Subject", "Artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
    "ux-design": ["Subject", "Artifact", "Focus", "Rubric", "Known questions", "Constraints", "Feedback route"],
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
adr = text("record-architectural-decisions")
ux = text("ux-design")
progress = text("planning-progress")
router = text("iteration-planning")
discovery = text("bdd-discovery")

for name, content in {
    "behaviour-iteration-planning": behaviour,
    "bdd-formulation": formulation,
    "domain-modelling": modelling,
    "domain-vocabulary": vocabulary,
}.items():
    require(content, ["docs/problem-domain-terms.md", "Matt"], f"{name} vocabulary ownership")

require(formulation, ["Temporal Formulation", "decision", "later state change", "ordering", "temporary", "backfilled"], "bdd-formulation temporal checks")
if "membership, preferences, permissions, messages, deliveries" in formulation:
    raise AssertionError("bdd-formulation temporal guidance is over-fitted to Memba examples")
require(discovery, ["smallest useful, coherent slice we could deliver", "invoke `ensemble-review` once"], "bdd-discovery product challenge and review ownership")
require(behaviour, ["Do not run a second ensemble when the map is unchanged"], "single example-map review checkpoint")
if "### Example-map brief" in behaviour or "map_review" in behaviour:
    raise AssertionError("behaviour planning duplicates bdd-discovery's example-map ensemble")
require(modelling, ["bdd-formulation", "domain-vocabulary", "solution-domain", "any scenarios that use the changed concept", "when Gherkin changed", "Model the problem well enough"], "domain-model vocabulary feedback loop")
require(vocabulary, ["problem-domain", "solution-domain", "explicit agreement", "bdd-formulation", "If no scenario uses the changed term", "preserving behaviour"], "domain-vocabulary boundary")
require(behaviour, ["record-architectural-decisions", "domain-vocabulary", "ux-design", "planning-progress", "session/thread storage", "repeat the formulated-feature ensemble"], "behaviour planning composition")
require(technical, ["record-architectural-decisions", "domain-vocabulary", "planning-progress", "session/thread storage", "problem-domain lexicon", "acceptance Gherkin wording only", "Vocabulary-coherence brief", "rules, examples, timing, actors, and outcomes are preserved"], "technical planning composition")
if "DesignSync" in behaviour or "## Design Check" in behaviour:
    raise AssertionError("behaviour planning duplicates ux-design procedure")
require(ux, ["`DesignSync` is unavailable", "checked-in sources are insufficient", "blocking handoff", "stop before drafting, publishing, or validating", "visible state", "Matt", "## Designs"], "standalone UX design")
require(progress, ["iteration-planning-progress.html", "pending", "current", "complete", "rework", "blocked", "artifact links", "flow diagram", "inline SVG"], "live planning progress")
require(router, ["planning-progress"], "planning router progress handoff")
require(router, ["docs/iterations/roadmap.md", "docs/iterations/README.md", "docs/problem-domain-terms.md", "docs/problems/README.md", "current problem records", "recent or related iteration plans", "acceptance features", "With that context"], "context-informed router interview")
require(adr, ["stands alone", "understanding of the context", "one or more ADRs", "explicit acceptance", "None required"], "standalone ADR collaboration")
require(behaviour, ["validated -> validation_route", "validation_route -> map", "validation_route -> formulate", "validation_route -> model", "validation_route -> adr"], "behaviour validation feedback routes")
require(technical, ["validated -> validation_route", "validation_route -> capability", "validation_route -> design", "validation_route -> adr"], "technical validation feedback routes")
require(technical, ["naming -> vocabulary", "vocabulary -> vocabulary_agreed", "vocabulary_agreed -> vocabulary_policy", "vocabulary_policy -> behaviour_route", "vocabulary_policy -> gherkin_affected", "gherkin_affected -> design", "gherkin_affected -> formulation", "formulation -> policy_changed", "policy_changed -> behaviour_route", "policy_changed -> wording_agreed", "wording_agreed -> formulation", "wording_agreed -> design"], "technical vocabulary feedback route")

print("Planning skill structural check passed")
