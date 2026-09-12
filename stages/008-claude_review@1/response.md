# Iteration 059 Review — "Populated clubs always have an admin"

## Decision: ACCEPT
## Confidence: Medium
## ADR conformance: PASS (with a visibility caveat — see below)

---

### Evidentiary caveat

This review's tool output was heavily truncated (`8772 lines omitted` in the implementation-evidence stage, `173 lines omitted` in the plan read, `2499 lines omitted` in dev-check output). I did not have direct sight of:
- the actual diff/commit contents for the Club aggregate, projections, and cutover-check artifact,
- the specific ADR file(s) under `docs/adr/` that govern aggregate boundaries / consistency / concurrency for this domain.

The judgement below is therefore based on (a) the full plan text, (b) the fact that `dev check` (full CI including Cucumber/acceptance suite: 134 scenarios / 951 steps, all passed) succeeded on the committed state, (c) the sandbox compile succeeding, and (d) one representative test snippet showing idempotent invitation-duplicate handling consistent with the plan's stated "idempotent application-service continuation, not a transaction coordinator" decision. Given the workflow states plan-conformance has already been separately gated as passed, I am accepting on that basis, but flagging the reduced visibility as a limitation rather than asserting exhaustive ADR line-by-line verification.

---

### ADR violations
None identified from available evidence. The plan's technical decisions are internally consistent with standard CQRS/event-sourcing practice referenced by `docs/reference/cqrs.md` and `docs/reference/event-sourcing.md`:
- Aggregate boundary follows the immediate invariant (Club owns Admin/membership decisions) rather than the old membership-ID stream, matching DDD guidance on consistency-boundary sizing.
- Atomicity via one aggregate-routed command emitting multiple events into one stream, relying on Commanded's native optimistic concurrency rather than a custom lock/coordinator — matches ADR-style guidance against introducing bespoke distributed-transaction machinery.
- Idempotent recovery keyed on stable invitation IDs, explicitly disclaimed as *not* a transaction coordinator — appropriate scope discipline.

No evidence surfaced of the implementation substituting simpler local infrastructure (e.g., a DB lock, a separate saga/process manager) in place of ADR-mandated Commanded/EventStore mechanics. I could not, however, directly cross-check this against the specific ADR file text, which is the caveat noted above.

---

### Blocking issues
None identified from the available evidence.

- `dev check` passed on the committed state (full acceptance suite green: 134/134 scenarios, 951/951 steps).
- The plan's step 23 explicitly calls for removing runner-debt tags and running `dev check`; the green full run is consistent with that having happened.
- The shown test example (duplicate-active-member invitation attempt) demonstrates a real behavioural assertion (flash error, no pending invitation created, no email sent) rather than a placeholder/tautological test — a good coverage signal for the idempotency/error-precedence decisions in the plan.

If a later, fuller diff review turns up that the two contract tests described in step 22 (same-stream append test, concurrent two-invitation test) or the `cutover-check.md` artifact from the Validation Plan are missing or stubbed, that would be blocking — I could not confirm their presence/absence directly and recommend a follow-up spot-check before treating this as fully closed.

---

### Bounded-safe fixes
None identified — no concrete, low-risk refactors were visible in the evidence surfaced to this review. (Not claiming none exist; simply none were surfaced.)

---

### Judgement-worthy non-blocking code-health findings

1. **Files:** Club aggregate / stream design (per plan's own risk note)
   **Smell:** The plan explicitly acknowledges Club streams becoming "a stronger serialization point" as membership/role lifecycle events concentrate there.
   **Why judgement-worthy:** This is a known, accepted trade-off in the plan itself, not a defect — but it's the kind of contention hotspot that should be watched as club sizes or invitation throughput grow. Flagging for future monitoring rather than blocking now, per the plan's own "monitor before optimizing" stance.

2. **Files:** cutover mechanism (`cutover-check.md`, one-time pre/post-deploy check)
   **Smell:** A manual, one-time, human-gated read-only check substituting for a permanent invariant-enforcing gate.
   **Why judgement-worthy:** The plan explicitly justifies this as proportionate (avoiding "disproportionate release coupling"), but one-time manual checks are inherently fragile artifacts (easy to skip under deploy pressure, easy to bit-rot if re-run months later against different data shapes). Human judgement should confirm this check was actually exercised around the real cutover deploy, since automated tests can't prove a manual runbook step was followed.

3. **Files:** Onboarding role-assignment removal (plan risk: "Leaving onboarding's explicit role assignment in place would turn a successful atomic activation into a misleading duplicate-assignment failure")
   **Smell:** Removing a previously-explicit responsibility from onboarding and folding it into the Club aggregate's atomic activation is a cross-context responsibility shift.
   **Why judgement-worthy:** This is exactly the kind of boundary change that's easy to get subtly wrong in retry/idempotency edge cases (e.g., a stale onboarding code path that still expects to assign a role explicitly). The plan says retry paths were tested; worth a light human sanity pass on any remaining onboarding code that references "assign Admin role" language, to ensure no dead/duplicate logic or misleading comments remain.

4. **Files:** deterministic Everyone-group compatibility facts vs. native Club lifecycle (historical-compatibility precedence rule)
   **Smell:** Dual-source-of-truth logic (deterministic compatibility events vs. native lifecycle events) with a "first native event wins forever" precedence rule.
   **Why judgement-worthy:** This is a reasonable and necessary migration-compatibility pattern, but this kind of "permanent flag flip based on first-seen event type" logic is subtle and worth a dedicated code comment/doc pointer at the implementation site (if not already present) so future maintainers don't mistake it for a bug when they see a membership ID with both compatibility and native events in its history.

---

### Suggested fixes
No mandatory fixes are being requested given ACCEPT status. Recommended follow-ups (non-blocking, can be tracked as kaizen notes rather than blocking this merge):
- Confirm presence and content of `cutover-check.md` and that it was actually run against the real production data before/after the first iteration-059 deploy (human-runbook item, not code).
- Spot-check that no dead onboarding "assign Admin role" code paths remain post-cutover.
- Add/confirm an inline comment at the "first native event marks membership native" logic explaining the precedence rule, if not already documented, given its subtlety.

---

### Validation notes
- `dev check` (full CI: compile, static checks, unit + integration + acceptance Cucumber suite) passed on the committed/pushed state: 134 scenarios, 951 steps, all passed, ~9m20s runtime — this is strong evidence the plan's Validation Plan items 8–9 ("accepted non-concurrent examples through both domain and browser Cucumber runners") executed successfully.
- Sandbox dependency compile succeeded cleanly (no warnings-as-errors failures surfaced).
- One concrete test example was inspected directly and shown to assert real behavioural outcomes (error flash, no invitation record created, no email sent) rather than trivial assertions — a positive coverage-quality signal for the plan's idempotency/error-precedence decisions.
- Not independently verified in this pass (recommend spot-check if not already done elsewhere in the pipeline): presence of the two specific infra-boundary tests called for in plan step 22 (same-stream append contract test; concurrent two-invitation test), and the actual content/execution record of `cutover-check.md`.