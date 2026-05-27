# Plan: ADR-aware iteration implementation harness

Date: 2026-05-27

## Goal

Make the `iteration-implementation` workflow build ADR coherence in from the start, and add a hard ADR gate that fails or routes to rework when the implementation contradicts accepted ADRs.

This is harness/workflow work. We will implement it locally rather than running it through Fabro.

## Problem observed

The last implementation run passed `dev check` and ended as successful, but the implementation and review cycle did not treat the iteration's ADRs as binding constraints.

Specific failure modes:

- The implementor prompt told the agent to use the plan and project guidance, but did not explicitly require reading or obeying ADRs referenced by the plan.
- The implementation substituted plain Elixir modules for ADR-mandated Commanded/EventStore/CQRS structure.
- Reviewers noticed missing architecture, but the synthesis step later accepted the result by reframing explicit plan/ADR requirements as optional implementation strategy.
- Passing tests were treated as sufficient evidence even though the tests did not prove ADR coherence.

## Desired outcome

A future implementation run should:

1. Read and internalize the relevant ADRs before coding.
2. Treat ADR decisions and consequences as binding architectural constraints.
3. Stop for human input when the plan and ADRs conflict, or when an ADR-mandated approach is blocked.
4. Prove ADR coherence after `dev check` and before general implementation reviews.
5. Route ADR incoherence to bounded rework, not final acceptance.
6. Never accept a result with unresolved accepted-ADR violations.

## Scope

### In scope

- Update the implementor prompt to shift ADR quality left.
- Add a dedicated ADR coherence gate after `dev_check` and before independent reviews.
- Add a dedicated ADR rework stage/prompt for repairable ADR violations.
- Strengthen independent review prompt to require ADR assessment.
- Strengthen synthesis prompt so unresolved ADR violations cannot be accepted.
- Add final-summary requirements for ADR conformance/deviations.
- Validate the workflow graph locally.

### Out of scope

- Running this harness change through Fabro.
- Implementing a fully static ADR parser or custom linter.
- Changing product ADR contents.
- Changing application/domain code as part of this plan.

## Proposed workflow shape

Current relevant path:

```text
implement -> dev_check -> review_fork -> synthesize_review -> review_gate
```

Proposed path:

```text
implement -> dev_check -> adr_coherence_gate -> adr_gate_decision

adr_gate_decision accepted -> review_fork
adr_gate_decision rework   -> fix_adr_coherence -> dev_check
adr_gate_decision blocked  -> fail_needs_human_adr_review
```

Normal reviews still run after ADR coherence passes.

## Implementation tasks

### 1. Update `prompts/implement.md`

Add a prominent ADR contract near the top.

Required behaviour:

- Before editing, read every ADR referenced by the plan.
- Also inspect nearby/current ADRs under `docs/adr/` when the plan touches architecture affected by them.
- Extract binding decisions and consequences.
- Build a short implementation checklist mapping ADRs to concrete modules, config, migrations, tests, and acceptance plumbing.
- Treat ADRs as constraints, not suggestions.
- If an ADR-mandated design seems too large, blocked, or incompatible, stop and report a blocker rather than substituting a simpler architecture.
- Final response must include an ADR conformance table:
  - ADR
  - Required decision
  - Implementation evidence
  - Tests/evidence
  - Deviations/blockers

Also tighten the existing vertical-slice escape hatch:

- A smaller vertical slice may reduce breadth, but it may not silently violate or replace ADR-mandated architectural decisions for the slice it claims to deliver.

### 2. Add ADR coherence gate prompt

Create `.fabro/workflows/iteration-implementation/prompts/adr_coherence_gate.md`.

Purpose:

- Read the plan, cited ADRs, implementation summary, working tree state, and successful `dev_check` output.
- Decide whether the current implementation is coherent with accepted ADR decisions.

Output:

- `ADR_COHERENT`, `ADR_REWORK`, or `HUMAN_INPUT`.
- Blocking ADR violations, each with:
  - ADR file/number
  - violated decision/consequence
  - observed implementation evidence
  - required fix
- Exact repair brief if rework is safe and bounded.
- Final routing JSON.

Routing JSON examples:

```json
{"context_updates":{"adr_coherent":true,"adr_rework_available":false}}
```

```json
{"context_updates":{"adr_coherent":false,"adr_rework_available":true}}
```

```json
{"context_updates":{"adr_coherent":false,"adr_rework_available":false}}
```

Acceptance rules:

- Passing `dev check` is necessary but not sufficient.
- If code contradicts an accepted ADR, do not pass the gate.
- If the plan explicitly cites an ADR and the implementation omits that ADR's central decision, route to ADR rework or human input.
- If the same ADR violation recurs after rework, prefer human input over repeated repair loops.
- If ADRs conflict with the plan, route to human input.

### 3. Add ADR rework prompt

Create `.fabro/workflows/iteration-implementation/prompts/fix_adr_coherence.md`.

Required behaviour:

- Fix only the ADR violations identified by the ADR gate.
- Do not reinterpret or weaken ADRs.
- Do not replace ADR-mandated architecture with simpler local substitutes.
- Add or update automated tests proving the ADR-relevant behaviour or structure.
- If a fix requires changing feature files, changing ADRs, or making a product decision, stop and request human input.
- Final response must map each ADR violation to concrete changes and tests.

### 4. Update workflow graph

Edit `.fabro/workflows/iteration-implementation/workflow.fabro`:

Add nodes:

- `adr_coherence_gate` — prompt node, probably `claude-opus` or other strong reviewer model, `output_schema="routing"`.
- `adr_gate` — conditional node.
- `fix_adr_coherence` — agent node, max visits likely 2.
- `adr_not_ready` — fail/human-input node.

Add edges:

```text
dev_check -> adr_coherence_gate [condition="outcome=succeeded"]
dev_check -> fix_dev_check
adr_coherence_gate -> adr_gate
adr_gate -> review_fork [condition="context.adr_coherent=true"]
adr_gate -> fix_adr_coherence [condition="context.adr_rework_available=true"]
adr_gate -> adr_not_ready
fix_adr_coherence -> dev_check
adr_not_ready -> exit
```

Keep existing `fix_dev_check` loop.

Consider reducing max visits so repeated ADR rework cannot spin too long.

### 5. Update `prompts/review.md`

Add ADR review as a first-class section.

Reviewers must:

- Read the ADR contract/cited ADRs.
- Reject if implementation conflicts with accepted ADRs.
- Treat missing ADR-mandated infrastructure as blocking unless the plan explicitly deferred it.
- Explain whether tests prove the ADR-relevant behaviour/architecture.

Add output section:

- ADR conformance: PASS/FAIL
- ADR violations: numbered list with ADR number and evidence

### 6. Update `prompts/synthesize_review.md`

Add hard synthesis rules:

- Never accept when unresolved accepted-ADR violations remain.
- Never downgrade a cited ADR's central decision to optional implementation strategy.
- If reviewers agree on an ADR violation, route to FIX or HUMAN_INPUT.
- If ADR rework has already been attempted and the violation remains, route to HUMAN_INPUT.
- If a plan/ADR conflict exists, route to HUMAN_INPUT.

### 7. Update `prompts/final_summary.md`

Require the final summary to include:

- ADR conformance summary.
- ADRs considered.
- Evidence for each ADR-relevant implementation decision.
- Any ADR deviations or human follow-ups.

### 8. Optional script preflight/gate support

Consider adding a lightweight script node before the LLM ADR gate to collect evidence:

- list cited ADRs from plan;
- list changed files;
- grep for obvious architecture markers relevant to cited ADRs, such as `Commanded`, `EventStore`, `commanded_ecto_projections`, Cucumber config, migrations, command/event modules.

This should support the LLM gate, not replace it.

## Acceptance criteria for this harness change

- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` passes.
- Implementor prompt explicitly requires ADR reading, checklisting, and conformance evidence before/while coding.
- Workflow contains a hard ADR coherence gate between `dev_check` and independent reviews.
- ADR gate can route to review, ADR rework, or human-input failure.
- ADR rework loops back through `dev_check` before another ADR gate/review.
- Review and synthesis prompts cannot accept unresolved accepted-ADR violations.
- Final summary reports ADR conformance.

## Manual test scenario

Use the previous failure as a mental regression test:

- Plan cites ADR 0002, 0007, 0008, 0009, 0010.
- Implementation uses only plain Elixir modules and lacks Commanded/EventStore/projections/Cucumber.
- `dev check` passes.

Expected harness result after this change:

- `dev_check` passes.
- `adr_coherence_gate` returns `ADR_REWORK` or `HUMAN_INPUT`, not `ADR_COHERENT`.
- If rework fails to add ADR-mandated architecture, synthesis cannot accept the implementation.

## Risks

- The ADR gate may be too strict for intentionally lightweight slices. Mitigation: the plan should explicitly state which ADR-mandated decisions are in or out of scope; otherwise accepted ADRs remain binding.
- LLM gates can still be inconsistent. Mitigation: use explicit routing rules, require ADR/evidence tables, and add simple script evidence where useful.
- Rework may become large. Mitigation: cap ADR rework visits and route repeated or architectural uncertainty to human input.
