Implemented the selected review repair.

## 1. Review issue from the gate

| Issue | Status |
|---|---|
| `centralize-conversation-id-derivation` — centralize conversation ID derivation | Fixed |

## 2. Concrete changes made

There was no router-level `"conversation-" <> root_message_id` derivation in the current implementation. The actual convention was spread across the app service, aggregate, and projector: **a conversation is keyed by the root message ID**.

I centralized that convention in a new module:

- Added `Memba.Messaging.ConversationReference`
  - `root_conversation_id/1`
  - `reply_to_message_id/1`

Then updated existing call sites to use it without changing behavior.

## 3. Files changed

### Issue: `centralize-conversation-id-derivation`

- Added:
  - `web/lib/memba/messaging/conversation_reference.ex`
  - `web/test/memba/messaging/conversation_reference_test.exs`

- Updated:
  - `web/lib/memba/messaging.ex`
  - `web/lib/memba/messaging/message.ex`
  - `web/lib/memba/messaging/projectors/message.ex`

Issue-to-fix mapping:

| Issue | Files/modules/tests addressing it |
|---|---|
| `centralize-conversation-id-derivation` | `Memba.Messaging.ConversationReference`; usages in `Memba.Messaging`, `Memba.Messaging.Message`, `Memba.Messaging.Projectors.Message`; tests in `Memba.Messaging.ConversationReferenceTest` |

Note: `.fabro/tmp/` remains untracked from the review workflow baseline artifacts.

## 4. Tests run

- `cd web && mix format --check-formatted lib/memba/messaging.ex lib/memba/messaging/message.ex lib/memba/messaging/projectors/message.ex lib/memba/messaging/conversation_reference.ex test/memba/messaging/conversation_reference_test.exs`
  - Passed

- `PATH="$PWD/bin:$PATH" dev check --quick`
  - Passed
  - `850 tests, 0 failures`

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed
  - ExUnit: `850 tests, 0 failures`
  - Acceptance: `86 scenarios passed`, `531 steps passed`

A direct `mix test ...` attempt outside the dev wrapper failed before running because PostgreSQL was not available at the expected `/tmp/devenv/postgres/.s.PGSQL.15432` socket. The dev-wrapper checks completed successfully afterward.

## 5. Remaining gaps or human questions

None for the selected repair. No product behavior was added or changed.