Now I'll review the complete plan against the five readiness dimensions.

---

# Iteration 042 Review: Club Email Subdomains

## Decision: READY

## Confidence: High

## Blocking Gaps

None.

## Non-blocking Improvements

1. **Future maintainer clarity:** The plan states iteration 041 "is in progress" (line 26), but the git log shows 041 completed/validated. Consider updating to "iteration 041 (completed)" or "iteration 041's header-based routing" for precision.

2. **Edge case verbosity:** Acceptance criteria could explicitly name the "old flat address rejection" error copy or handling to prevent implementation from silently swallowing those emails.

3. **Subdomain label count:** Destination resolution (step 3, line 146) says "parse... where `host` is `<club-slug>.<configured inbound domain>`" – this correctly implies a single label before `.clubs.memba.io`, but does not state whether `nested.kmc.clubs.memba.io` should be rejected. This is very likely implicit (unknown club), but an explicit "reject multi-label club subdomains" note would eliminate ambiguity.

## Smallest Viable Iteration

The plan is already appropriately scoped.

The hard cutover to `everyone@<club-slug>.clubs.memba.io` is a single coherent outcome. Splitting out rejection handling, reply-destination updates, or smoke-test changes would leave incomplete semantics or untested production integration.

## Required Plan Edits

None.

The plan meets all readiness criteria:

1. **Goal clarity:** Clear user/business outcome – members use a subdomain-based email shape (`everyone@kmc.clubs.memba.io`) with explicit beneficiary (members) and outcome (clearer namespace foundation).

2. **Scope focus:** Tightly focused on changing the canonical inbound address shape, resolving club subdomains, rejecting unsupported routes, and updating member-facing surfaces. Non-goals are explicit and well-bounded.

3. **Acceptance criteria, BDD, and business decisions:**
   - Criteria are concrete, complete, and objectively testable. They cover happy paths (primary/alternate address), edge cases (unsupported local parts, unknown subdomains), rejection (old address, unsupported routes), data changes (club resolution), reply integration (iteration 041), and smoke tests.
   - Iteration type is classified as behaviour-facing.
   - BDD scenarios are marked **required** with clear rationale ("address shape is the product behaviour").
   - Named feature files: `member_message_deliverability.feature`, `club_message_replies.feature`, `inbound_club_email.feature`.
   - All business decisions resolved. Hard cutover, namespace choice, and `everyone`-only route are confirmed.

4. **Implementation plan and technical decisions:**
   - Steps are clear, ordered, and specific. Named touchpoints include helpers, resolvers, parsers, dashboard, compose surfaces, reply-email generation, acceptance step support, docs (`postmark-email.md`), and smoke config (`smoke-tests/lib/config.js`).
   - Data model (existing slug lookup), integration points (Postmark inbound, iteration 041 reply headers), and environment configuration (inbound namespace) are specified.
   - All technical decisions resolved or intentionally deferred to implementer with stated constraints.

5. **Expected capability and validation:**
   - Clear stop condition: `dev check` green, production smoke test passes after Matt's Postmark/DNS setup.
   - Validation plan names unit/domain tests for address generation/resolution, acceptance test reruns, dashboard/compose tests, docs review, and production smoke test.
   - Explicit new capability: club-owned subdomain namespace foundation for future routes/channels.

## Validation Plan

After implementation:

1. **Code review:**
   - Verify inbound address helper returns `everyone@<slug>.clubs.memba.io` for all club slugs.
   - Verify destination resolver accepts `everyone@<club>.<namespace>` and rejects unsupported local parts, unknown club subdomains, and old flat addresses.
   - Verify member dashboard and compose surfaces display the new address.
   - Verify reply-notification emails use `everyone@<club>.clubs.memba.io` as the `Reply-To` destination while preserving iteration 041's header logic.

2. **Test review:**
   - Confirm unit/domain tests for address generation and destination parsing.
   - Confirm acceptance scenarios in `member_message_deliverability.feature` and `club_message_replies.feature` are executable (no `@todo-domain`/`@todo-ui` on the new canonical scenarios).
   - Confirm production smoke config updated to `everyone@test.clubs.memba.io`.

3. **Runtime validation:**
   - After Matt's Postmark/DNS setup, production smoke test passes.
   - `dev check` passes.

4. **Stakeholder confirmation:**
   - Matt confirms wildcard inbound setup at Postmark/DNS.
   - Acceptance scenarios match expected member experience and rejection policy.

---

## Summary

This iteration plan is comprehensive, well-structured, and ready for implementation. Goals, scope, acceptance criteria, BDD decision, implementation steps, and validation approach are all clearly articulated. Business and technical decisions are resolved. The plan correctly identifies external prerequisites (Postmark/DNS setup by Matt) and integration dependencies (iteration 041 reply routing) with appropriate risk notes.

No blocking gaps. Minor improvements are optional clarifications, not requirements.

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}