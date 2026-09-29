# Problem: Technical planning left ADR triage implicit

Date: 2026-09-29

## Context

During planning for iteration 067 in BB thread `thr_32d5pa6ndi`, Matt and the facilitator explored a live-query boundary between LiveViews and projections, LiveView-owned subscriptions instead of separate processes, and a local package boundary. The existing [technical planning skill](../../.pi/skills/technical-iteration-planning/SKILL.md) called for ADRs for consequential choices.

## Expected standard

Before reviewing and publishing a design, the facilitator should surface consequential decisions, recommend which merit an ADR (or explain why none do), and let Matt decide. The [ADR skill](../../.pi/skills/record-architectural-decisions/SKILL.md) then owns drafting, review, acceptance and publication.

## What happened

The facilitator called the change consequential and read the ADR skill and existing ADR 0021, but later asked permission to review “the technical design and any ADR” without explicitly recommending a record. Matt had to ask, “have we written an ADR for this? Do you think we should?” Only then did the facilitator say yes and name the reasons.

## Impact

Minor planning friction and a quality risk: the decision was eventually captured, but without Matt's prompt a consequential choice could have reached plan assembly without explicit ADR triage.

## What allowed it to happen

The skill required ADRs for consequential choices at a later step and required the plan to link ADRs or justify none, but did not require a visible recommendation to Matt before the design review request. The conditional wording “any ADR” made the judgment easy to defer.

## Observations

- The choice affected the read-side responsibility boundary, process ownership and package boundary; this was not an ADR-for-every-technical-iteration request.
- Matt's question exposed the gap before publication, not after implementation.

## Why this matters

An explicit early recommendation makes architecture decisions reviewable while alternatives are still open and avoids relying on the stakeholder to remember the ADR gate.

## Possible prevention ideas

Name candidate decisions and recommend ADR or no ADR with a reason before requesting design review; revisit the classification if review changes the design. Preserve “none required” for technical work without a consequential durable choice.
