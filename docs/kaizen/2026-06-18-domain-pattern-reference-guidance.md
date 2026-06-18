# Problem: Domain architecture guidance was implicit and not visible enough to reviewers

Date: 2026-06-18

## Context

Matt asked for deep research summaries on Greg Young's CQRS/Event Sourcing work, Eric Evans's Domain-Driven Design, and Rebecca Wirfs-Brock's Responsibility-Driven Design. The resulting guidance was added under `docs/reference/`:

- `docs/reference/domain-driven-design.md`
- `docs/reference/cqrs.md`
- `docs/reference/event-sourcing.md`
- `docs/reference/responsibility-driven-design.md`

Memba already has accepted ADRs that rely on these ideas, especially around Commanded, event sourcing, aggregates, bounded contexts, Ecto projections, read-model change publication, and projection barriers.

## What happened

After adding the reference docs, Matt asked that the Fabro code-review prompts use them as guidelines for the patterns we want to follow, and that relevant ADRs signpost to them.

We updated:

- `docs/reference/README.md` to index all four pattern reference docs.
- `.fabro/workflows/iteration-review/prompts/review.md` and `synthesize_review.md` to require reviewers and synthesis to use the four docs as design-quality guidance when reviewing domain modeling, Commanded/CQRS, event streams, projections, aggregates, read models, and responsibility boundaries.
- `.fabro/workflows/iteration-implementation/prompts/review.md` and `synthesize_review.md` with the same guidance for the older implementation-review prompt set.
- `.fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh` so the four reference docs are printed into the review evidence context.
- `.fabro/workflows/iteration-review/scripts/test_review_report_routing.sh` and `test_collect_implementation_evidence.sh` so future workflow edits must keep these pattern references visible.
- Relevant ADRs (`0002`, `0004`, `0005`, `0007`, `0008`, `0009`, `0011`, `0021`, `0022`) with “Related reference guidance” links to the applicable pattern docs.

The change was committed and pushed as:

- `ca5c1267 Add domain pattern reference guidance`

## Impact

Before this change, agents reviewing or implementing Memba's domain architecture could see binding ADR decisions, but the deeper design tradition behind those decisions was mostly tacit. A reviewer could check “uses Commanded” while missing more subtle drift, such as:

- CRUD-shaped domain workflows that should be commands and events.
- Passive/anemic aggregates with behavior pushed into orchestration code.
- Messaging code reaching through Membership's read-model storage instead of its public query boundary.
- Projections that ignore replay, idempotency, or eventual consistency.
- Objects and services with unclear responsibilities or god-controller behavior.

The new reference docs make the desired design taste explicit and give reviewers shared vocabulary for non-blocking code-health findings as well as ADR violations.

## What allowed the gap

The project had strong ADRs, but ADRs are necessarily decision-specific. They say what Memba chose, but not always enough about the surrounding design principles to help future agents interpret edge cases.

Fabro review prompts already required ADR conformance, but they did not explicitly load or name the broader reference guidance. If a model did not already have DDD/CQRS/Event Sourcing/RDD context in its prompt window, it could review only against local code shape and generic Elixir/Phoenix conventions.

## Why this matters

Memba's core architecture depends on domain design discipline. Commanded and EventStore are not just libraries in this project; they encode a way of modeling behavior, history, read models, and consistency boundaries.

If agents apply these tools mechanically, the codebase can still drift toward procedural transaction scripts, direct projection coupling, or generic CRUD. That kind of drift is expensive because it usually remains green at the test level until later workflows become hard to evolve.

Making the reference guidance visible to both ADR readers and Fabro reviewers improves the chance that architectural drift is caught early and described in a common language.

## Validation

We ran:

- `bash .fabro/workflows/iteration-review/scripts/test_review_report_routing.sh`
- `bash .fabro/workflows/iteration-review/scripts/test_collect_implementation_evidence.sh`
- `fabro validate .fabro/workflows/iteration-review/workflow.toml --no-upgrade-check`

Fabro validation passed with the existing expected goal-gate retry warnings.

## Follow-up ideas

- Consider adding similar reference-doc visibility to planning or plan-validation prompts when a plan proposes new domain architecture.
- Add examples from Memba's own code to the reference docs as the domain model matures.
- Periodically review `docs/code-health.md` for recurring findings that should become ADRs, reference guidance, or automated review checks.
- Check whether the old `iteration-implementation` review prompts are still active; if obsolete, remove them or document why they remain.
