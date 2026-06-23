Implemented the plan-conformance repair and left the tracked code changes passing `dev check`.

## 1. Plan requirement gap from the gate

The actionable conformance gap in the current state was:

- The iteration plan’s validation requires the new `@todo-domain` read-model Cucumber scenarios in `club_message_replies.feature` to go green **and the tag to be removed once implemented**.
- Current repository state still had the iteration-043 Rule tagged `@todo-domain`, so the domain Cucumber runner excluded it.
- The domain Cucumber step definitions for those new “club home recent conversations” scenarios were missing.

## 2. Changes made

### Requirement: iteration-043 Cucumber scenarios go green and are no longer skipped

Changed:

- Removed `@todo-domain` from the iteration-043 Rule in:
  - `acceptance-tests/features/club_message_replies.feature`

Added domain Cucumber step support in:

- `web/test/features/step_definitions/messaging_steps.exs`

The new steps assert the plan’s read-model behavior through `Messaging.list_conversations_for_club/1`:

- Alice’s club home lists exactly one conversation row for the root message.
- A replied-to conversation shows the expected reply count.
- The latest replier id/name is shown.
- A no-reply conversation has `reply_count == 0` and no latest replier.
- Conversations are ordered by original/root message order, not by newer reply activity.

No production code changes were required for this repair.

## 3. Files changed, grouped by requirement

### Unskip and execute iteration-043 acceptance scenarios

- `acceptance-tests/features/club_message_replies.feature`
  - Changed `@iteration-043 @todo-domain` to `@iteration-043`.

### Domain Cucumber step implementation for the unskipped scenarios

- `web/test/features/step_definitions/messaging_steps.exs`
  - Added step definitions and helper assertions for the club-home conversation overview read model.

## 4. Automated tests added/updated

Updated automated acceptance coverage by enabling existing shared Cucumber scenarios:

- `club_message_replies.feature`
  - `Scenario: A replied-to message appears once, with its reply count`
  - `Scenario: A message with no replies shows none yet`
  - `Scenario: Conversations are ordered by original message, newest first`

These now run under `web/test/features/domain_cucumber_acceptance_test.exs`.

## 5. Tests run and results

Passed:

- `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted test/features/step_definitions/messaging_steps.exs`
- `devenv shell -- bin/mix test test/features/domain_cucumber_acceptance_test.exs`
  - `86 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" dev check`
  - Passed
  - Acceptance summary: `85 scenarios (85 passed)`, `523 steps (523 passed)`

Runtime/sandbox issue encountered:

- `PATH="$PWD/bin:$PATH" bin/mix test test/features/domain_cucumber_acceptance_test.exs`
  - Failed before running tests due to the known sandbox Postgres readiness/socket mismatch.
  - I did not patch app code or scripts for this.
- `PATH="$PWD/bin:$PATH" bin/dev gallery-walk`
  - Failed because the readiness check timed out on `http://localhost:4000/` while the Phoenix log showed Bandit running at `127.0.0.1:4000`.
  - Per the sandbox/runtime boundary, I did not patch `bin/dev` or product code to compensate.

## 6. Remaining gaps / human questions

- `dev check` passes with the repaired tracked diff.
- The gallery-walk screenshot validation remains blocked by the local runtime readiness mismatch described above. If that screenshot evidence is required for final plan signoff, the sandbox/runtime issue around `localhost` vs `127.0.0.1` reachability needs to be resolved outside product-code repair scope.

## Requirement-to-fix mapping

| Plan requirement | Fix |
|---|---|
| New `club_message_replies.feature` read-model scenarios go green and `@todo-domain` is removed once implemented | Removed `@todo-domain` from the `@iteration-043` Rule in `acceptance-tests/features/club_message_replies.feature` |
| Domain scenarios assert one conversation row, reply count, latest replier, no replies, and original-send ordering | Added domain Cucumber steps/helpers in `web/test/features/step_definitions/messaging_steps.exs` using `Messaging.list_conversations_for_club/1` |
| Leave codebase passing validation | Ran and passed full `dev check` |