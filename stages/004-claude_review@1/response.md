This confirms the plan's description of the current implementation is accurate. Everything checks out — the plan's characterization of current code matches reality. Now I have sufficient evidence to produce the review.

## Report: Iteration 059 — Populated clubs always have an Admin

**Decision: READY**
**Confidence: High**

I read the full plan file (227 lines) directly and cross-checked its factual claims against the current codebase (`web/lib/memba/membership/club.ex`, `web/lib/memba/membership.ex`, `web/lib/memba/membership/router.ex`, `web/lib/memba/release.ex`, and `acceptance-tests/features/club_membership_administration.feature`). All architectural claims in the Background/Context and Technical Decisions sections match the current implementation exactly: `AddMember`/`RemoveMember` are routed to the `Membership` aggregate keyed by `membership_id` (not `Club`), the `Club` aggregate already owns `role_assignments` and emits `MemberRoleAssigned`/`MemberRoleRemoved`, the existing last-Admin guard in `remove_member_role_as_club_member/2` is a projection-backed preflight (`active_role_assignment_count`) with no equivalent guard for whole-member removal, and the release pipeline already has a `run_system_groups_backfill` step the plan proposes to gate. The plan's technical narrative is not speculative — it's an accurate diagnosis of real code.

### 1. Goal clarity — clear
The goal names the invariant, the actor (Staff performing removals, invitees joining), the business outcome (no populated club is ever left without an Admin), and the mechanism boundary (aggregate-protected, atomic). This is unambiguous and outcome-focused, not just a task list.

### 2. Scope focus — focused, single coherent outcome
Scope is one invariant enforced consistently across all activation/removal paths. The out-of-scope list is unusually disciplined (no archive/close, no bulk import, no saga/coordinator, no new roles, no UI redesign), which sharply bounds the work. It could not obviously be smaller while still closing the actual production gap, because the gap exists precisely in the paths (invitation acceptance, whole-member removal) that a narrower slice would have to leave unprotected.

### 3. Acceptance criteria / BDD / business decisions — resolved
- Iteration Type is explicitly classified as behaviour-facing, with reasoning.
- The `## Acceptance Scenarios / Feature Files` section names the exact feature file and enumerates each new/changed scenario, including a deliberate, well-justified decision to keep the concurrency scenario `@not-ui`/domain-only rather than force browser-timing Gherkin.
- 21 acceptance criteria are concrete and testable (idempotency semantics, error-precedence rule, audit gating, projection-preservation, etc.).
- "Open Business Decisions: None known" is followed by seven previously-resolved decisions restated as confirmed, including the tie-break rule (final-member feedback takes precedence over sole-Admin feedback) — this is exactly the kind of ambiguous product-copy decision that often gets left open, and it's closed here.

### 4. Implementation plan and technical decisions — resolved and specific
13 ordered steps name concrete modules, files, and test locations (`Memba.Membership.Club`, `web/test/memba/membership/club_test.exs`, `Memba.Membership.AdminInvariant.Audit.run!/0`, `Memba.Release.migrate/0`). The historical-compatibility strategy (native lifecycle facts permanently override delayed Everyone events) is precisely specified with a worked example. The Technical Decisions section closes out every major open question I'd expect a reviewer to raise: consistency boundary, atomicity boundary (explicitly excluding person/invitation/email from the atomicity claim), concurrency handling (relying on Commanded's own aggregate serialization, no new lock), release-audit ordering, and error precedence.

### 5. Expected capability and validation — clear
"New Capability" states the concrete post-iteration guarantee in one paragraph. The Validation Plan lists 10 concrete checks (pure aggregate tests, stream-replay comparison against projections, audit failure blocking the backfill, concurrent-dispatch integration test, failure-injection retry test, manual demo script, `dev check`). This is proof-oriented, not just "tests will pass."

### Blocking gaps
None.

### Non-blocking improvements
1. Step 4 says "remove the old aggregate module if it has no replay-only caller, otherwise mark it legacy/unregistered and create a named follow-up" — the plan could optionally pre-name that follow-up doc now rather than leaving it to be created mid-implementation, but this is a minor process nit, not a readiness blocker.
2. The plan doesn't state whether `Memba.Membership.Membership` (the old per-membership aggregate) has any other callers beyond `AddMember`/`RemoveMember` (e.g., is it also identified/dispatched for anything else in `router.ex`) — worth a quick grep at implementation start, but low risk since the plan already asks the implementer to verify this.
3. Risks/Follow-ups section is thorough; two forward-looking follow-ups (archive/close design, bulk-import first-Admin rule) are correctly deferred rather than solved here.

### Smallest viable iteration
The plan is already close to minimal. If it needed to shrink further, the smallest still-useful slice would be: move only `AddMember` (activation) to the Club aggregate with the atomic first-Admin assignment, covering onboarding conversion and both invitation-acceptance paths — deferring the whole-membership-removal invariant (final-member and sole-Admin-on-removal guards) to a follow-up iteration. That would fix the exact production defect (join paths missing Admin) but would leave the removal-side invariant gap open, which the plan's own Background explicitly identifies as an equally real boundary problem. I don't recommend this split — the plan's stated rationale for doing both together (one aggregate boundary now protects both directions of the same invariant, avoiding a second migration of the same commands later) is sound — but it is the direction to cut if timeline pressure forces a smaller slice.

### Required plan edits
None required for readiness.

### Validation plan (recap of what the plan itself specifies)
- Pure `Club` aggregate unit tests (no DB) for first/later/idempotent/duplicate/removed-ID/removal-guard decisions.
- Stream-replay tests comparing rehydrated aggregate state against current projections, including the native-vs-delayed-Everyone-event precedence example.
- Audit (`AdminInvariant.Audit.run!/0`) tested against complete and deliberately incomplete fact sets, plus a release-ordering test proving a failing audit blocks `run_system_groups_backfill` and smoke fixtures.
- One thin EventStore/dispatch integration test proving same-stream atomic append of `MemberAdded` + first `MemberRoleAssigned`.
- Concurrent-dispatch integration test for two simultaneous invitation acceptances.
- Failure-injection/retry tests for invitation acceptance idempotency.
- Full regression sweep (onboarding, both invitation paths, Staff removal LiveView, member-list, messaging, seeds, smoke fixtures).
- Cucumber runners exercised for all new/updated scenarios as runner-debt tags are removed.
- `dev check` on the exact committed delivery candidate.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}