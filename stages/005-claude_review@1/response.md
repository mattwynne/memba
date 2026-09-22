I have enough evidence to assess the plan. Let me finalize.

## Report

**Decision: READY**
**Confidence: High**

I read the complete plan file at `docs/iterations/064-leave-and-remove-group-members/plan.md` (115 lines, all sections present) and cross-checked its claims against the actual codebase and referenced artifacts.

### Verification performed
- **Feature files**: Both cited files (`custom_group_membership.feature`, `custom_group_lifecycle.feature`) exist and contain the exact `@iteration-064 @todo-domain @todo-ui` tagged Rules/Scenarios the plan describes — removal by member/outside-admin, non-member refusal, system-group guards, immediate access/mail revocation, delivered-copy non-recall, re-add without old follows, explicit re-follow, and last-member departure/repopulation. Scenario content matches every acceptance criterion in the plan line-for-line.
- **Designs**: All three referenced design files exist (`club-group-members.html`, `club-group-non-member.html`, `custom-groups-prototype.html`) and contain the Remove/Leave confirmation states, empty-group handling, and outside-admin/former-member placeholder views the plan describes.
- **Current code state**: Confirmed the plan's diagnosis is accurate. `Memba.Membership.Projections.GroupMembership` (`web/lib/memba/membership/projections/group_membership.ex`) is exactly the "reusable active/inactive relation" the plan says must be replaced with first-class group memberships. `ClearRemovedGroupMemberFollows` (`web/lib/memba/membership/policies/clear_removed_group_member_follows.ex`) is the fan-out cleanup policy the plan says is being replaced by a Messaging-owned subscription ledger with a durable receipt. This matches the plan's stated rationale for the architecture revision, and the working tree is clean (no stray implementation drift).
- **Prior related ADR**: ADR 0024 explicitly defers the consistency-boundary decision for "future arbitrary group membership" to be made when needed — consistent with the plan's Implementation Plan step 1 requiring a new architecture decision before further coding.
- **Dependency chain**: 062/063 plans are merged and their scope/out-of-scope boundaries (departure/rejoin cleanup, add-member picker) align with what 064 builds on.

### Assessment against the five readiness dimensions

1. **Goal clarity** — Clear. States who (group members/club admins), what (remove/leave), and the business outcome (ends access/emails immediately, preserves empty group for later repopulation). The Background section sharply distinguishes club membership from group membership, which is the crux of the redesign.

2. **Scope focus** — Coherent single outcome (ending group participation) with an unusually well-specified boundary given the architecture pivot. Out-of-scope list is explicit (archiving, renaming, notifications, new error UI). This is not the smallest possible slice — it bundles a domain-model refactor (first-class group memberships) with a cross-context messaging-subscription redesign — but the plan explains why: the previous smaller/incremental approach (cutoff-based cleanup) was tried and demonstrably failed under review for finding valid event orderings that escaped inferred cutoffs. That failure is documented in the plan's Background and matches the actual retired code in the repo. Splitting further would recreate the same correctness gap the plan is explicitly avoiding.

3. **Acceptance criteria / BDD / business decisions** — Concrete and testable; all traced to real, already-existing Gherkin scenarios (not merely promised). Iteration Type correctly classified Behaviour-facing, and both required feature files/rules are named with rationale. "Open Business Decisions: None known" is substantiated — Matt's specific choices (empty-but-existing groups, no archive, full history + fresh follows on re-add) are cited and reflected precisely in the acceptance criteria and scenarios.

4. **Implementation plan / technical decisions** — Eight ordered, specific steps naming the consistency boundary (Membership), the new subscription ledger owner (Messaging), migration/reconciliation strategy for historic data, and a broad, named test matrix (replay, retry, aggregate restart, projection replay, historic reconciliation, delivered-copy limits). "Open Technical Decisions: None known" is reasonable given step 1 explicitly defers exact event/command names to a required architecture decision record — that's a scoped, bounded first implementation step, not an unresolved planning gap.

5. **Expected capability and validation** — New Capability section is a clear before/after statement. Validation Plan enumerates concrete proof points (per-actor/target removal, follow-then-remove-then-reply delivery checks, race conditions between removal/re-add/follow, replay-safety, and preserving existing system-group/last-admin tests) plus both acceptance runners and `dev check`. Stop condition is implicit but adequate: `dev check` passing plus the enumerated scenario/test matrix on the exact final delivery state.

### Blocking gaps
None found.

### Non-blocking improvements
1. Step 1 of the Implementation Plan says "Record the architecture decision before further implementation" but doesn't name where (presumably `docs/adr/`, following the pattern of ADR 0024). Naming the expected ADR file/number explicitly would tighten execution but isn't blocking since the pattern is well-established in this repo.
2. The Validation Plan's "Test each actor/target combination" could enumerate the specific combinations (self/other, member/admin-outside, non-member) the way the feature file already does, purely for cross-reference convenience — the feature file already covers this so it's redundant rather than missing.
3. "New Capability" and "Validation Plan" sections don't explicitly name a stop condition beyond `dev check`; an explicit one-line stop condition (e.g., "done when all @iteration-064 scenarios pass untagged and dev check is clean on the final commit") would remove any ambiguity for the implementer, though this is standard practice elsewhere in the repo and inferable.

### Smallest viable iteration
The plan as scoped is already close to minimal given the constraint that a smaller/incremental fix was tried and failed (documented in Background). Removal alone without the group-membership/subscription-authorization redesign would recreate the same race conditions previously found. If further slicing were desired, one could theoretically split "first-class group memberships in Membership" (steps 1–3) from "Messaging subscription ledger + revocation receipt" (steps 4–6) as two iterations, but the plan's Background explains why doing so previously produced an incoherent half-migrated state — the current single-iteration scope is the defensible minimum.

### Required plan edits
None required for readiness. Optional: name the expected ADR location in step 1 (non-blocking).

### Validation plan (independent, for this review)
- Confirmed both feature files and all cited scenarios/tags exist and match every acceptance criterion (done above).
- Confirmed both cited design files and the prototype exist with the described states (done above).
- Confirmed the plan's technical diagnosis matches actual code (`GroupMembership` projection, `ClearRemovedGroupMemberFollows` policy) rather than being speculative (done above).
- Confirmed dependency plans (062, 063) are merged and their scope boundaries are consistent with 064's stated dependencies (done above).
- Did not execute `dev check` or the acceptance runners, since this is a docs-only planning review and no code changes are proposed by this validation step, per the project's `dev check` policy for docs-only edits.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}