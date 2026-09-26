---
name: ensemble-review
description: Run a generic read-only review by up to three independent model families using a caller-supplied artifact, focus, rubric, questions, and constraints.
---

# Ensemble Review

Use this skill when a caller needs independent perspectives on a bounded artifact. This skill knows how to assemble and synthesize reviewers; it does not know what makes any particular artifact good. The caller owns the review brief and all decisions.

## Contract

- Review only. Neither reviewers nor synthesizer edit files or rewrite the artifact.
- Do not infer a domain-specific rubric. Reject an incomplete brief instead of inventing quality criteria.
- Reviewers provide evidence, alternatives, disagreements, and questions. They do not decide product policy, architecture, scope, wording, or acceptance.
- The caller routes findings to the responsible specialist and discusses consequential choices with Matt.
- Run at most one bounded review round unless the caller explicitly requests another after revising the artifact.

## Required Review Brief

Require the caller to supply all of:

- **Subject** — what is being reviewed and why.
- **Artifact** — inline content or exact paths and relevant source context.
- **Focus** — the distinct perspective each reviewer should apply.
- **Rubric** — concrete questions or criteria for this artifact.
- **Known questions** — uncertainties reviewers should investigate, including `None` when there are none.
- **Constraints** — agreed outcome, boundaries, non-goals, decision owners, and prohibited actions.
- **Feedback route** — the caller or specialist that owns revisions.

The focus may define one common perspective or up to three complementary lenses. Artifact-specific knowledge belongs in this brief, not in this skill.

## Discover a Diverse Panel

Prefer three independent reviewers from three model families when they are available:

1. one Anthropic Claude model;
2. one OpenAI GPT model;
3. one Google Gemini model.

Discover current providers and model catalogs in the execution environment; do not hardcode model versions. In BB, inspect `bb provider list` and `bb provider models <provider-id>` for the current environment, then spawn child threads with explicit provider and model selections. A provider's name alone is not proof of model family; use its reported catalog/model identity.

Choose a current suitable reasoning-capable model from each family. Use no more than one reviewer from a family. Dispatch all selected reviewers independently and in parallel with the same artifact, constraints, and known questions; give each only its assigned focus/lens and the shared rubric. Explicitly instruct each reviewer to remain read-only, cite evidence, separate defects from optional ideas, and report uncertainty.

When a requested family, provider, model catalog, or independent delegation mechanism is unavailable:

- continue with the remaining distinct families rather than substituting a duplicate family;
- state which family is missing and why;
- label the result with the actual panel used;
- never claim three-family or independent consensus when it was not obtained.

If no independent delegation is available, perform at most three clearly separated passes, disclose that they are not independent, and retain the family limitation in the result.

## Reviewer Output

Ask each reviewer for:

- significant findings ordered by impact;
- evidence tied to the supplied artifact or context;
- rubric question(s) implicated;
- a concise alternative or question where useful;
- confidence and material uncertainty;
- `No significant findings` when appropriate.

Reviewers must not broaden the brief, silently resolve an open question, or turn preferences into requirements.

## Synthesis

Record the actual provider/model family for each completed report. Then:

1. normalize findings around the caller's rubric;
2. deduplicate findings that share the same evidence and consequence;
3. prioritize significant contradictions, risks, missing evidence, and unanswered questions;
4. preserve substantive disagreement and family-specific uncertainty rather than voting or averaging it away;
5. separate high-confidence findings from optional suggestions;
6. identify the supplied feedback route for each finding.

Return:

- panel used and any degraded coverage;
- significant agreements;
- significant disagreements;
- prioritized evidence-backed findings;
- questions for the decision owner;
- optional ideas, clearly labelled;
- feedback route for each actionable item.

The synthesis is advice. The caller and Matt retain ownership of product policy, architecture, vocabulary, scope, and acceptance decisions.
