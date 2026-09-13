Both the `GroupMemberRemoved` event and `UnfollowConversation` command already exist from the 062 work, confirming the plan's implementation strategy builds on real existing infrastructure rather than speculative naming.

## Report

**Decision: READY**
**Confidence: High**

### Verification performed
- Read the full plan file directly (`docs/iterations/064-leave-and-remove-group-members/plan.md`), all 107 lines.
- Confirmed both dependency iterations (062, 063) are `Status: validated`.
- Confirmed the two referenced feature files (`custom_group_membership.feature`, `custom_group_lifecycle.feature`) exist and already contain the `@iteration-064 @todo-domain @todo-ui` tagged scenarios the plan names — five rules/scenario groups covering removal-by-member/outside-admin, system-group guards, immediate access/email revocation with an open view, delivered-copy non-recall, re-add without follow restoration, follow-again restoration, and last-member departure/repopulation. Scenario content matches every Acceptance Criteria bullet in the plan.
- Confirmed the three referenced design files exist (`club-group-members.html`, `club-group-non-member.html`, `custom-groups-prototype.html`).
- Confirmed the domain building blocks the implementation plan relies on already exist in code: `Memba.Membership.Events.GroupMemberRemoved` (club.ex, projector) and `Memba.Messaging.Commands.UnfollowConversation` (router, conversation_followers.ex) — so the plan's reuse strategy is grounded, not speculative.

### Assessment against the five readiness questions

1. **Goal clarity** — Clear. States the actors (group members, club admins, leaving members), the outcome (ending access/email/follow immediately while preserving club role and group history), and explicitly separates "leaving a group" from "leaving the club."

2. **Scope focus** — Tight and coherent. In/out-of-scope lists are explicit; three related problems (archiving, renaming, CQRS drift) are explicitly deferred with rationale rather than left ambiguous. The scope could not obviously be split smaller — the leave/remove/follow-cleanup/re-add-without-follow set is one coherent behavioral rule with tightly coupled edge cases (open views, queued email, last member).

3. **Acceptance criteria / BDD** — Concrete, testable, and already expressed as Gherkin scenarios that exist in the repo (not just promised). Covers happy path, permissions (outside admin, non-member, self-removal), edge cases (last member, admin-as-target, already-delivered email, race between removal/re-add/follow), and system-group protections. Iteration correctly classified as behaviour-facing with required BDD. No unresolved business decisions — "Open Business Decisions: None known" is substantiated by specific prior decisions (empty-but-existing groups, no archive-on-empty, full history on re-add, fresh follows after re-add).

4. **Implementation plan** — Specific and ordered: reuses `GroupMemberRemoved`, extends the 062 follow-cleanup policy with named ordering/idempotency concerns, names the read-model refresh points (`MemberDashboardLive`, conversation views, membership panels), specifies UI reuse of existing member-row/tab-action patterns, and lists the test types (aggregate, follower-policy, queued-delivery, race, LiveView) plus `dev check` as the final gate. Open Technical Decisions section correctly scopes remaining design freedom (ordering mechanism) without leaving core architecture unresolved.

5. **Expected capability and validation** — New Capability statement is a clear before/after. Validation Plan gives concrete manual/automated proof steps (follow → remove → send → verify no delivery; re-add → verify no follow restore; replay/race testing; run both acceptance runners and `dev check`) with a clear stop condition (existing system-group/last-member tests preserved, both runners and `dev check` green).

No blocking gaps found.

### Non-blocking improvements
1. The plan says "cloud sync is pending" for the reviewed local design — worth doing before/alongside implementation but not a blocker for starting.
2. Could explicitly name the aggregate/module file paths (e.g., which module hosts the new removal command) rather than only class-level ("actor-bearing custom-group removal use case/command"), though this is a minor implementation-time detail, not a planning gap, since it clearly builds on the existing 063 pattern.

### Smallest viable iteration
The plan as scoped is already close to minimal for a coherent slice: it could theoretically be split into (a) removal by member/admin + immediate access revocation, and (b) follow-cleanup + re-add/re-follow semantics as a follow-on iteration — but doing so would leave a half-finished security-relevant behavior (revocation without follow-cleanup is not safe to ship), so the current scope is the right minimal unit.

### Required plan edits
None required for readiness.

### Validation plan (to prove the iteration succeeded)
- Run the acceptance runner(s) against `custom_group_membership.feature` and `custom_group_lifecycle.feature`, confirming all `@iteration-064` scenarios pass and prior `@iteration-062`/`@iteration-063` scenarios still pass unmodified.
- Run `dev check` on the final committed/staged state.
- Manually exercise: remove a club-admin from a custom group (verify role/authority retained, group access lost); remove the last member (verify group persists, unarchived); attempt access via a stale link/open LiveView/direct reply after removal (verify denied); re-add and confirm history restored but follow not restored; follow again and confirm new-reply delivery resumes.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}