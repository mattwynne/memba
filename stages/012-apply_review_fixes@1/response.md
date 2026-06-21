Implemented the bounded review repairs without changing product behavior or acceptance features.

## Issue-to-fix mapping

| Review issue | Resolution | Files/modules/tests |
|---|---|---|
| `fix-inbound-lookup-context-boundary` — Move inbound message-id conversation lookup behind Messaging context | No web `InboundRouter` exists in the current implementation; inbound reply routing already lives inside `Memba.Messaging`. I documented the context-owned routing strategy and deterministic outbound lookup invariant. | `web/lib/memba/messaging.ex` |
| `fix-shared-inbound-header-parser` — Deduplicate inbound RFC message-id parsing across providers | Extracted provider-neutral inbound header extraction to a shared module. Postmark/Resend parsers now delegate original `Message-ID`, `In-Reply-To`, and `References` extraction to one place. | `web/lib/memba_web/inbound_email_headers.ex`, `web/lib/memba_web/postmark_inbound_email_parser.ex`, `web/lib/memba_web/resend_inbound_email_parser.ex`, `web/test/memba_web/inbound_email_headers_test.exs` |
| `fix-document-inbound-routing-strategy` — Document inbound email routing strategy and invariants | Added docs explaining Topicbox-style same-club header matching, fallback-to-new-message behavior, and unchanged sender authorization/rejection behavior. | `web/lib/memba/messaging.ex` |
| `fix-clarify-message-id-invariant` — Clarify/enforce persisted Message-ID uniqueness/determinism invariant | Confirmed the existing migration already enforces non-null unique `outbound_message_id`. Added schema/context documentation and a DB constraint test proving uniqueness. | `web/lib/memba/messaging.ex`, `web/lib/memba/messaging/projections/email_delivery.ex`, `web/test/memba/messaging/email_delivery_status_constraints_test.exs` |

## Files changed

### Shared inbound header parsing
- Added `web/lib/memba_web/inbound_email_headers.ex`
- Added `web/test/memba_web/inbound_email_headers_test.exs`
- Updated `web/lib/memba_web/postmark_inbound_email_parser.ex`
- Updated `web/lib/memba_web/resend_inbound_email_parser.ex`

### Routing/invariant documentation
- Updated `web/lib/memba/messaging.ex`
- Updated `web/lib/memba/messaging/projections/email_delivery.ex`

### Message-ID invariant verification
- Updated `web/test/memba/messaging/email_delivery_status_constraints_test.exs`

## Tests and checks run

- `cd web && mix format --check-formatted ...` — passed
- `git diff --check` — passed
- Raw focused `mix test ...` — failed because Postgres was not available at `/tmp/devenv/postgres/.s.PGSQL.15432` outside the dev wrapper; no product code changed for this sandbox/runtime boundary.
- `PATH="$PWD/bin:$PATH" dev check --quick`
  - First run found one new test setup issue, fixed.
  - Rerun passed: `891 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" dev check` — passed:
  - ExUnit: `891 tests, 0 failures`
  - Acceptance: `82 scenarios (82 passed)`, `493 steps (493 passed)`

## Remaining gaps / human questions

- No remaining blocker from the synthesized review issues.
- The generated outbound `Message-ID` format privacy/opacity concern remains judgement-worthy but was not one of the bounded automatic repairs beyond documenting/proving uniqueness.
- `.fabro/tmp/` remains untracked from the review workflow; I did not remove workflow artifacts.