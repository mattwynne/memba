# Iteration 057 Review Summary

- **Result:** `REVIEW_ACCEPTED`
- **Plan:** `docs/iterations/057-admin-group-email-conversations/plan.md`
- **Base SHA:** `19a51a338fa1e414391d184d264ab4a5cce73b7c`
- **Reviewed range:** `19a51a338fa1e414391d184d264ab4a5cce73b7c..fcaa33930ee7e4ae0a939a4c8b25dd58c012f46d`
- **Published commit:** `fcaa33930ee7e4ae0a939a4c8b25dd58c012f46d`

## Review outcome

The implementation was accepted. All three independent reviewers returned **ACCEPT** and **ADR conformance: PASS**. Review synthesis likewise concluded:

- `implementation_accepted: true`
- `review_fixes_available: false`

No production-code ADR violations or merge-blocking behavioral defects were identified.

Confidence varied from medium to high because the collected implementation transcript was heavily truncated, but the reviewers converged on the same architectural assessment and the complete automated validation passed.

## ADR conformance

The reviews found that the implementation preserves the intended event-sourced/CQRS architecture:

- Email slugs are aggregate-owned, stable routing identities distinct from group names and deterministic system-group IDs.
- Production writes continue through commands, aggregates, events, and projectors.
- Direct Ecto insertion is limited to test read-model fixtures.
- Conversation access is represented explicitly by projected conversation-to-group grants rather than reconstructed from message recipients.
- Inbound idempotency remains based on provider/message identity.
- `club_members_only` remains a named policy boundary rather than an unplanned persisted setting.
- The group-aware read API did not expose Admin conversations through existing Everyone-only web surfaces.

## Final artifact evidence

The final artifact gate examined the implementation relative to base SHA `19a51a338fa1e414391d184d264ab4a5cce73b7c` and passed:

> `82 files changed, 3426 insertions(+), 447 deletions(-)`  
> `Final artifact evidence confirmed.`  
> `Final artifact gate passed.`

It also explicitly confirmed that the acceptance feature changes were permitted by the plan, including:

- `acceptance-tests/features/club_message_replies.feature`
- `acceptance-tests/features/member_message_deliverability.feature`

Representative implementation and test files shown by the final artifact evidence include:

- `web/lib/memba_web/member_message_detail.ex`
- `web/priv/repo/migrations/..._add_email_slug_to_membership_groups.exs`
- `web/test/memba/membership/club_test.exs`
- `web/test/memba/membership/create_club_dispatch_test.exs`
- `web/test/memba/membership/group_projection_test.exs`
- `web/test/memba/membership/query_test.exs`
- `web/test/memba/membership/system_groups_backfill_test.exs`
- `web/test/memba/membership/system_groups_replay_parity_test.exs`
- `web/test/memba/messaging/group_email_posting_policy_test.exs`
- `web/test/memba/messaging/inbound_club_destination_test.exs`
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
- `web/test/memba/messaging/message_projection_test.exs`
- `web/test/memba/messaging/send_club_message_test.exs`
- `web/test/memba_web/controllers/member_message_detail_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/support/messaging_fixtures.ex`

## Finding disposition

### Fixed

1. **Test Repo starvation under single-scheduler CI**
   - A strong-consistency controller test timed out because the scheduler-derived pool could be only two connections while reset handling and concurrent Commanded projectors needed more.
   - The test Repo configuration was adjusted to retain scheduler-based sizing while enforcing a tested minimum pool size of 16.
   - Focused tests and the complete checks subsequently passed.

2. **Projection fixture contract was insufficiently explicit**
   - The fixture documentation was clarified to state that it directly creates read-model rows, root messages create the conversation-to-group access grant, and replies require an existing root and grant.
   - `web/test/support/messaging_fixtures.ex` is present in the final artifact evidence.

3. **Groups policy documentation alignment**
   - The review repair reported aligning the Groups vision with the accepted distinction between:
     - starting a new group conversation under `club_members_only`, and
     - replying, which still requires group write access.
   - The final artifact gate passed after review repair and before publication.

### Recorded in code health

`docs/code-health.md` was updated successfully with five factual, actionable Iteration 057 notes. This was a documentation-only recording, so no additional `dev check` was required for that stage.

The recorded judgement-worthy themes were:

1. Direct read-model construction in messaging fixtures may drift from production projector behavior.
2. Root/reply fixture semantics rely on the `message_id == conversation_id` convention.
3. The fixed test Repo pool floor is coupled to current projector concurrency and CI topology.
4. Raw/default access-level vocabulary in fixtures could drift from the production model if that vocabulary evolves.
5. An Admin sender currently receives a redundant root-message copy; this is explicitly accepted and deferred pending a product decision about sender-copy semantics.

These are non-blocking maintenance signals, not current correctness failures.

### Dismissed with reason

- **Direct Ecto fixture insertion as an ADR violation:** dismissed because it is confined to query/read-model test setup. Production write paths continue through the aggregate/event architecture, and separate domain/projector tests exercise the real path.
- **Redundant Admin-sender delivery as a defect:** dismissed for this iteration because the plan explicitly defers it.
- **Need for an immediate root/reply fixture API split:** dismissed as unnecessary churn now that the fixture contract is documented; it remains a possible future cleanup.
- **Review repair verification failure:** treated as a workflow-tooling artifact rather than a failed product repair. The repair agent staged its edits, while the verifier compared unstaged `git diff` output and therefore saw no working-tree delta. Subsequent evidence collection, full validation, the final artifact gate, and publication completed successfully.

### Unhandled

No substantive review finding remained unhandled. The stale `review_blockers` context entries were superseded by the applied repairs, second review synthesis, passing final artifact gate, and publication.

## Validation

Validation completed successfully on the reviewed state:

- Sandbox runtime preflight passed.
- Final `dev ci`/`dev check` passed.
- Elixir test suite: **1,129 tests, 0 failures**.
- Browser acceptance suite: **122 scenarios, 877 steps, all passed**.
- Focused `MembaWeb.DevTestSupportControllerTest` checks passed after the Repo pool adjustment.
- Formatting and static checks passed.
- Diff whitespace checks passed.
- The final artifact gate passed.
- Acceptance feature changes were explicitly recognized by the gate as plan-permitted.

An intermediate combined check hit an external 600-second terminal-wrapper limit after successful acceptance cleanup, but its quick and acceptance components passed independently. A later complete `dev ci` succeeded.

## Publish outcome

Review polish was pushed to `main`:

> `0a3f734..fcaa339  fcaa33930ee7e4ae0a939a4c8b25dd58c012f46d -> main`

The plan and iteration index were already marked merged, so finalization required no additional commit.

## Manual checks still recommended

No manual check is required to accept the iteration. Useful optional checks are:

- Send a real provider-shaped Admin email from:
  - an active non-Admin member,
  - an active Admin,
  - an inactive member,
  - and a member of another club.
- Replay the same provider message to visually confirm no duplicate conversation or delivery appears.
- Confirm existing member-facing pages still show only Everyone conversations.
- Confirm an Admin reply is accepted while a non-Admin reply to the Admin conversation is rejected.

## Non-blocking follow-ups

- Consider separate test fixture entry points for conversation roots and replies if invalid read-model setup becomes recurring.
- Consider centralizing access-level constants if a canonical production vocabulary is introduced.
- Revisit the minimum test Repo pool size if projector count or CI topology changes.
- Keep the redundant Admin-sender root delivery unchanged until product semantics for sender copies are explicitly decided.