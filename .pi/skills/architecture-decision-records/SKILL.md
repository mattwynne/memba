---
name: architecture-decision-records
description: Identify, draft, review, and record consequential architecture decisions with Matt from an agreed behaviour model or technical design before implementation.
---

# Architecture Decision Records

Use this skill after Matt has agreed the domain model or technical design. It is shared by behaviour-changing and technical/refactoring planning.

## Boundary

- ADR candidates must emerge from the agreed model/design and its constraints; do not invent architecture to make the plan look complete.
- Matt decides the option and explicitly accepts the record. Reviewers advise.
- An ADR records a consequential decision and its trade-offs; it does not own product policy, domain vocabulary, feature formulation, or implementation.
- Existing accepted ADRs remain authoritative until Matt explicitly supersedes them.
- `None required` is a valid result when no consequential, durable choice exists.

## Inputs

Require:

- the relevant behaviour/domain model or technical design;
- relevant accepted ADRs and `docs/adr/README.md`;
- the decision pressure and constraints;
- viable options already identified, including the status quo;
- unresolved consequences or questions;
- the calling planning skill as the feedback route.

If the model/design is not agreed, return to its owning skill.

## Collaboration

For each candidate, work with Matt to establish:

1. the concrete decision and why it is needed now;
2. whether it is consequential enough for an ADR;
3. viable alternatives, including doing nothing or deferring;
4. the option Matt chooses;
5. positive and negative consequences, reversibility, migration and operational effects;
6. conflicts with existing ADRs and whether any must be superseded.

Draft the ADR only after the choice is clear. Use the repository's ADR format and next-number convention. Mark it accepted only after the review loop below and Matt's explicit acceptance.

## Caller-Owned Ensemble Brief

Call `ensemble-review` with:

- **Subject:** whether the draft faithfully records the consequential decision from the agreed model/design.
- **Artifact:** agreed model/design, draft ADR, relevant accepted ADRs, options and constraints.
- **Focus:** (1) necessity and simpler/deferred options, (2) failure and consequence analysis, (3) fidelity, conflicts and decision-record coherence.
- **Rubric:** Is this a real consequential choice? Is the decision context accurate? Are viable alternatives represented fairly? Are consequences, reversibility, migration and operational effects plain? Does the draft introduce unagreed product policy, vocabulary, domain modelling or architecture?
- **Known questions:** the unresolved consequences from collaboration, or `None`.
- **Constraints:** read-only review; reviewers must not choose the option, rewrite policy, accept the ADR, or broaden scope. Matt is decision owner.
- **Feedback route:** this skill for recording defects; domain/vocabulary/product discoveries return to their owning specialist skill.

Present deduplicated evidence, disagreements and questions to Matt. Revise through this skill and repeat review when the decision or material consequences change. Obtain Matt's explicit acceptance after review.

## Publication

- Write accepted records under `docs/adr/` using the repository convention.
- Update `docs/adr/README.md`.
- Link accepted ADRs from the iteration plan.
- If review exposes an upstream issue, stop ADR work and return it to the calling planning skill. After that ingredient repeats its review and Matt checkpoint, reassess whether the ADR is still needed.

## Output

Return:

- accepted ADR paths and the model/design decision each records;
- existing ADRs confirmed or superseded;
- `None required` with a reason when appropriate;
- unresolved questions or upstream feedback;
- confirmation that Matt explicitly accepted each new or superseding ADR.
