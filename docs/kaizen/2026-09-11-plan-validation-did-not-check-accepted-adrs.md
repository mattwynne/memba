# Problem: plan validation approved a direct contradiction with an accepted ADR

Date: 2026-09-11

## Context

Iteration 059, [`docs/iterations/059-populated-clubs-always-have-an-admin/plan.md`](../iterations/059-populated-clubs-always-have-an-admin/plan.md), changes the Membership write boundary so `AddMember` and `RemoveMember` are routed to the Club aggregate by `club_id`. The plan explicitly de-registers the membership-ID write route and moves duplicate active-membership decisions from a projection preflight into Club state.

Plan-validation run `01M23NZ7CH5874T5YKPD78C683` marked that plan validated. Implementation run `01M23P8GASTPS25GCXAZ8TF95X` then completed twelve of twenty-three tasks before task validation stopped for human input.

This observation is related to [`2026-05-27-iteration-implementation-adr-gate-plan.md`](2026-05-27-iteration-implementation-adr-gate-plan.md). That earlier note records a resolved requirement for implementation to treat accepted ADRs as binding. The current failure occurred earlier, in plan validation, and also shows that the intended implementation ADR guardrail has regressed or become inconsistent.

## Expected standard

A plan that materially changes aggregate identity, command routing, consistency boundaries, or projection responsibility should be compared with relevant accepted ADRs before it can be marked validated.

If a plan conflicts with an accepted ADR, validation should stop for Matt to choose one of three explicit outcomes:

- keep the ADR and revise the plan;
- supersede the affected ADR decision with a successor ADR; or
- abandon the iteration.

A plan cannot silently supersede an accepted ADR merely because its proposed design is internally coherent. Implementation task validation should enforce the same rule at the first contradictory task, not after later work has accumulated.

## What happened

The conflict was explicit in repository text.

Accepted [`docs/adr/0011-use-caller-generated-uuid-aggregate-identities.md`](../adr/0011-use-caller-generated-uuid-aggregate-identities.md) says:

- “Membership aggregate identity: `membership_id`, with `club_id` and `person_id` stored as event fields.”
- “Enforce [duplicate active membership] in the application service using Membership's public query API/projections before dispatching `AddMember`.”

The validated iteration plan says:

- route membership activation and removal to the Club aggregate by `club_id`;
- de-register the membership-ID write route; and
- use rehydrated aggregate state, not projections, to decide duplicate active membership.

Despite that direct contradiction, all three plan reviewers returned `READY` with High confidence and zero blocking gaps in run `01M23NZ7CH5874T5YKPD78C683`.

The durable validation artifacts show:

- `.fabro/workflows/plan-validation/prompts/{gemini_review,claude_review,codex_review}.md` require reviewers to read the complete plan, but do not require them to inspect `docs/adr/README.md`, read relevant accepted ADRs, or report an ADR-conformance table.
- Gemini's complete response was only routing JSON: `READY`, High confidence, zero gaps.
- Claude's complete response was only routing JSON: `READY`, High confidence, zero gaps.
- The plan-validation synthesis prompt explicitly says the required routing fields are sufficient reviewer evidence, so those evidence-free votes were accepted as full independent reviews.
- GPT-5.6 Sol returned a substantive report, but assessed only the plan's internal completeness and did not identify ADR 0011.
- Synthesis saw three `READY` votes, performed no independent ADR check, and published `validated`.

The implementation workflow had another opportunity to catch the conflict when task 006 changed the router. Instead, its validator declared the task valid and said the implementation preserved “the applicable identity intent of ADR 0011.” That narrowed the ADR to its title while ignoring its explicit membership-routing and projection-preflight decisions. Task 007's validator similarly treated “the validated plan's newer Club consistency-boundary decision” as sufficient, although a plan has no authority to supersede an accepted ADR silently.

Task 012's validator finally read and enforced the complete ADR. It stopped at checkpoint `61a844686` and also found that inactive-target validation for role removal had been removed from the application service without yet being transferred to Club state.

The current `.fabro/workflows/iteration-implementation/workflow.fabro` contains no `adr_coherence_gate` node or route, although `.fabro/workflows/iteration-implementation/prompts/adr_coherence_gate.md` still exists and the May kaizen note records the gate as implemented. The protection appears to have been lost as the workflow evolved.

## Impact

- A plan with a direct accepted-ADR contradiction was labelled validated and allowed to reserve the implementation WIP slot.
- Twelve task implementations and validations accumulated before the conflict stopped the run.
- Matt had to re-enter an architecture decision that should have been raised during planning.
- Multiple validators reported High confidence without evidence proportionate to that confidence.
- The run is recoverable because Fabro preserved checkpoints, but delivery is blocked and substantial model time and elapsed time were wasted.
- If the late validator had also accepted the contradiction, the implementation could have reached final publication with architecture documentation and code disagreeing about the write model.

## What allowed it to happen

1. **Plan validation checks internal readiness, not repository architecture conformance.** Its reviewer checklist asks whether technical decisions are clear, but not whether they contradict accepted ADRs.
2. **The final-output contract and reviewer prompt conflict.** The prompt asks for a substantive Markdown report plus routing JSON, while the injected Fabro contract requests one JSON object. Two reviewers satisfied routing with no visible analysis.
3. **Synthesis treats assertions as evidence.** It accepts routing fields as sufficient even when a reviewer returns no report, ADR list, quotations, file paths, or comparison.
4. **There is no deterministic ADR evidence requirement.** A `READY` response need not name which accepted ADRs were inspected or quote the decisions that constrain the plan.
5. **Implementation validators can cherry-pick an ADR's “intent.”** Task 006 and task 007 validators cited ADR 0011 while ignoring clauses that directly contradicted the changes they approved.
6. **The intended final ADR coherence gate is absent from the current graph.** Its prompt remains in the repository, but the workflow no longer routes through it.
7. **Planning did not list ADRs affected by the architecture change.** The plan and planning process discussed CQRS, Event Sourcing, and aggregate boundaries without explicitly reviewing the ADR index or recording that ADR 0011 needed supersession.

## Observations

- The eventual stop demonstrates that the repository contained enough evidence for an agent to find the conflict. The problem was not missing documentation; it was when and how validation was instructed to use it.
- Three-model fan-out did not provide independent protection because all reviewers shared the same incomplete readiness checklist.
- High-confidence unanimity amplified the weakness rather than compensating for it.
- The exact conflict was present before implementation and became concrete no later than task 006, six task cycles before the stop at task 012.
- Focused product tests were green when the run stopped. Test success could not prove that the chosen architecture was an approved one.
- The implementation work remains preserved on `origin/fabro/run/01M23P8GASTPS25GCXAZ8TF95X`; this note does not decide whether ADR 0011 should be retained or superseded.

## Why this matters

ADRs are useful only if plans and implementations treat them as current constraints or explicitly supersede them. A workflow that reads plans but not ADRs can produce internally polished, thoroughly tested work that quietly reverses architectural decisions. Finding that conflict halfway through implementation is safer than publishing it, but still much later and more expensive than necessary.

## Open questions

- Why was the ADR coherence node removed from the implementation graph while its prompt and the resolved May note remained?
- Should every behaviour-facing plan inspect all ADRs, or should an architecture-change classifier trigger the ADR review only when aggregate, persistence, routing, context, or framework boundaries change?
- Can Fabro enforce a non-empty substantive reviewer report rather than accepting routing fields alone?
- Should the plan template require an “ADRs considered / superseded” section for architectural work?
- Should task validation quote each relevant ADR decision instead of reporting conformance to an inferred “intent”?

## Possible prevention ideas

- Add an ADR-conformance section to all three plan-review prompts. Require reviewers to read `docs/adr/README.md`, inspect relevant accepted ADRs, and return a table of ADR, binding decision, plan evidence, and result.
- Add a plan-validation regression fixture containing an internally complete plan that directly contradicts an accepted ADR. The expected result must be `NEEDS MATT`, never `READY` or automatic repair.
- Reject a reviewer branch as incomplete when it supplies only routing fields without a substantive report and repository evidence.
- Remove the conflicting reviewer output instructions or define one structured schema that requires both routing and substantive evidence.
- Make synthesis fail closed unless every `READY` reviewer names the ADRs considered or explicitly demonstrates why no ADR is relevant.
- Restore a hard ADR coherence gate in the implementation workflow before substantial task execution, or add a deterministic pre-implementation ADR gate immediately after reading the plan.
- Strengthen per-task validation so a plan/ADR conflict always means human input; a validated plan cannot be described as a “newer decision” that silently overrides an accepted ADR.
- Update the iteration-planning skill to inspect `docs/adr/README.md` whenever a proposed plan changes aggregate boundaries, command routing, persistence ownership, or projection authority.
