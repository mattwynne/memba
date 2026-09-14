# Iteration 062 review summary

- **Result:** `REVIEW_ACCEPTED`
- **Plan:** `docs/iterations/062-create-custom-groups/plan.md`
- **Base SHA:** `7b7ee1b8594cecb7bbd0bee562fa08815d8aa5e0`
- **Reviewed implementation range:** `7b7ee1b8594cecb7bbd0bee562fa08815d8aa5e0..03978b3`
- **Published review-polish commit:** `453fac71aaad129bde5493e7ca0973ea2289a5b3`

## Outcome

The completed implementation was accepted as plan-conforming. The review synthesis set:

- `implementation_accepted: true`
- `review_fixes_available: false`

All three independent reviews accepted the iteration:

- Codex: **ACCEPT**, high confidence
- Claude: **ACCEPT**, medium confidence
- Gemini: **ACCEPT**, medium confidence

No blocking product, authorization, privacy, or acceptance-criteria defect was identified.

## ADR conformance

The independent reviews and synthesis concluded **ADR conformance passed**, with no blocking ADR violation.

The implementation was assessed as preserving the established CQRS/event-sourcing boundaries:

- Authorization, name uniqueness, slug allocation, and creator membership are decided at the Club aggregate boundary rather than by projections.
- Creation emits domain facts rather than directly modifying read models.
- Cross-context follow cleanup uses a named policy and public Messaging APIs rather than projector side effects.
- Trusted historical/backfill paths and replay behavior remain supported.
- Custom groups are distinguished structurally rather than by display-name checks.

One architectural concern was recorded rather than treated as an immediate violation: the Club aggregate now owns an expanding custom-group membership matrix, which is in tension with the direction described by ADR 0024. That boundary should be decided before iterations 063/064 expand membership management.

## Finding disposition

### Fixed during review

None. The synthesis found no bounded-safe implementation repair appropriate for this review, and `review_fixes_available` was false.

### Recorded

The final artifact gate showed an update to `docs/code-health.md` under:

> `## 2026-09-14 — Iteration 062: Admins create usable custom groups`

The exact finding headings recorded were:

1. **Follow cleanup can acknowledge a group-member removal before Messaging has projected every affected conversation.**
   - **Disposition:** Recorded for follow-up.
   - The documented risk is stale follows surviving projection lag and becoming effective after a later custom-group re-add.

2. **Origin replay of follow cleanup is idempotent only against current boolean follow state, not against the removal that caused it.**
   - **Disposition:** Recorded for follow-up.
   - The documented risk is replay of an old removal clearing a newer legitimate follow.

3. **Membership projection progress is globally coupled to a cross-context Messaging cleanup handler.**
   - **Disposition:** Recorded for architectural follow-up.
   - The documented risk is unrelated Membership progress being delayed by Messaging cleanup failures or latency.

4. **The Club aggregate is becoming the owner of an unbounded custom-group membership matrix.**
   - **Disposition:** Recorded for an explicit consistency-boundary decision before general group membership management expands.
   - The note specifically identifies the tension with ADR 0024.

5. **Custom group email-slug allocation does full-set work per live preview and linear probing for collision families.**
   - **Disposition:** Recorded as a scale-sensitive optimization concern.
   - The suggested path is to establish expected scale first, then consider debounce, indexed candidate lookups, an allocation index, or a dedicated email-slug value object.

6. **Iteration 062's domain Cucumber scenarios execute twice.**
   - **Disposition:** Recorded as test-suite duplication.
   - The suggested cleanup is to retain scenario execution in `DomainCucumberAcceptanceTest` and make the feature-specific modules lightweight selection assertions.

### Dismissed or excluded

The code-health entry explicitly excluded:

- Already tracked rename, archive, and sender-copy product follow-ups.
- Speculative documentation suggestions.
- Speculative concurrency-test suggestions that the implementation already satisfies.

The independent suggestion to add module documentation, migration commentary, or shared truncation helpers was not applied because it was conditional and not supported as a concrete defect in the reviewed state.

### Unhandled

None. Substantive supported concerns were either accepted as non-blocking and recorded in `docs/code-health.md`, or explicitly excluded with a stated reason. There is no review-workflow gap in the disposition of findings.

## Repairs applied during review

No product or implementation repairs were applied.

The only file shown as changed by the final artifact gate was:

- `docs/code-health.md`

No other changed file is claimed.

## Final artifact confirmation

The final artifact gate explicitly reported:

- The `docs/code-health.md` Iteration 062 entry and its six findings.
- `Final artifact evidence confirmed.`
- `Final artifact gate passed.`

This confirms that the reviewed implementation evidence and the recorded code-health artifact were present at the final gate. No acceptance feature or product-behavior file was edited during code-health recording.

## Key files identified in final artifact evidence

The final artifact evidence referenced these implementation and test files while documenting the findings:

- `docs/code-health.md`
- `web/lib/memba/membership/policies/clear_removed_group_member_follows.ex`
- `web/lib/memba/membership/projectors/membership.ex`
- `web/lib/memba/membership/club.ex`
- `web/lib/memba/membership/application.ex`
- `web/lib/memba/messaging/conversation_followers.ex`
- `web/lib/memba_web/live/member_group_live/new.ex`
- `web/test/memba/messaging/send_club_message_test.exs`
- `web/test/features/domain_cucumber_acceptance_test.exs`
- `custom_group_creation_steps_test.exs`
- `custom_group_conversation_steps_test.exs`
- `custom_group_lifecycle_steps_test.exs`

Of these, only `docs/code-health.md` was shown as repaired or changed by the review.

## Tests and validation

Validation completed successfully:

- Sandbox dependency compilation and runtime preflight passed.
- Full `dev ci` passed on the reviewed delivery state.
- Acceptance suite:
  - **177 scenarios passed**
  - **1,319 steps passed**
  - No failures reported
  - Runtime approximately **16m44s**
- The implementation evidence covered the planned authorization, uniqueness, slug allocation, replay, LiveView, messaging, email-routing, privacy, and departure/rejoin behaviors.
- The final artifact gate passed.

## Publish outcome

Review polish was pushed to `main`:

- Previous main: `03978b3`
- Published commit: `453fac71aaad129bde5493e7ca0973ea2289a5b3`
- Push range: `03978b3..453fac7`

Iteration 062 was already marked merged, so finalization required no additional status commit.

## Manual checks still recommended

No manual check is required to accept the iteration.

As non-blocking architectural follow-up, maintainers should review the cleanup ordering and replay model before extending explicit group removal in iteration 064, particularly:

- lagging Messaging projections during departure;
- removal → cleanup → re-add → legitimate refollow → policy replay;
- whether Membership projection progress should remain globally gated by Messaging cleanup;
- the custom-group membership consistency boundary before iterations 063/064 increase aggregate load.

## Non-blocking follow-ups

1. Make follow cleanup causally tied to the specific removal or membership generation.
2. Ensure cleanup waits for relevant Messaging projection progress and durable follow projection completion.
3. Replace global cross-context projection coupling with scoped durable integration work.
4. Decide and document ownership of the custom-group membership consistency boundary.
5. Monitor group scale before optimizing preview and slug allocation.
6. Remove duplicate execution of the Iteration 062 domain Cucumber scenarios.