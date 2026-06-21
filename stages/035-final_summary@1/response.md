Result: **REVIEW_ACCEPTED**

## Plan path

`docs/iterations/041-reply-by-email-threading/plan.md`

## Base SHA and reviewed commit range

- Base SHA used for implementation evidence collection: `108b67402cf434f05fa988a72bd67992052b623c`
- Published reviewed/polished main commit: `17ce647f437df97a8190be7811e4ab07d7a20ce9`
- Reviewed range: `108b67402cf434f05fa988a72bd67992052b623c..17ce647f437df97a8190be7811e4ab07d7a20ce9`

## ADR conformance summary

Independent reviews and synthesis agreed that the implementation conforms to the relevant architectural decisions:

- **ADR-0048 / Topicbox-style reply routing:** Pass. The implementation uses standard email headers to distinguish replies from new inbound club messages, persists outbound Memba-controlled `Message-ID` values, parses inbound `In-Reply-To` / `References`, restricts matches to the same club, and falls back to creating a new club-wide message when no recognized same-club header exists.
- **ADR-0050 / optimistic query-command bridging:** Pass. Auto-follow on reply is handled through the existing query/command flow after successful reply posting rather than direct read-model mutation.
- **CQRS / DDD / event-sourcing fit:** Pass. Durable messaging state continues through existing Messaging commands/projections, while persisted outbound delivery metadata is used as a read-side lookup key for inbound routing.

No ADR violations were reported.

## Independent review outcome

All three independent reviews returned **ACCEPT** with high confidence.

Summary:

- No blocking implementation defects found.
- Plan-conforming behaviours were verified by implementation evidence and tests:
  - outbound `Message-ID` generation and persistence;
  - reply email `Reply-To`, `In-Reply-To`, and `References` headers;
  - Postmark and Resend inbound header parsing;
  - same-club conversation matching;
  - cross-club reply prevention;
  - fallback to new club-wide inbound messages;
  - rejection paths for non-member, ambiguous sender, malformed payload, and unsupported inbound content;
  - reply attribution;
  - auto-follow on reply;
  - follower fan-out;
  - basic quoted-history stripping.

The review synthesis set:

```json
{
  "implementation_accepted": true,
  "review_fixes_available": false
}
```

## Final artifact gate evidence

The final artifact gate passed and confirmed the reviewed implementation evidence.

It reported:

- **54 files changed**
- **2544 insertions**
- **150 deletions**
- Acceptance `.feature` changes were explicitly permitted by the plan:
  - `acceptance-tests/features/club_message_replies.feature`
  - `acceptance-tests/features/member_message_deliverability.feature`

Final artifact gate output explicitly concluded:

> `Final artifact evidence confirmed.`  
> `Final artifact gate passed.`

This is the artifact evidence used for the reviewed implementation.

## Finding disposition

### Fixed / already addressed

The synthesized bounded-safe review items were found to already be addressed in the implementation/polish state; no additional repair diff was produced during the later repair pass.

1. **Move inbound message-id conversation lookup behind Messaging context**  
   - Disposition: **fixed / already addressed**
   - Evidence: inbound reply resolution lives in `Memba.Messaging`; outbound message reference lookup is exposed through `Messaging.get_outbound_message_reference/1`; same-club filtering is applied in the Messaging inbound path.
   - Relevant file in final artifact evidence:
     - `web/lib/memba/messaging.ex`

2. **Deduplicate inbound RFC message-id parsing across providers**  
   - Disposition: **fixed / already addressed**
   - Evidence: shared provider-neutral parser exists and provider parsers delegate to it.
   - Relevant files in final artifact evidence:
     - `web/lib/memba_web/inbound_email_headers.ex`
     - `web/lib/memba_web/postmark_inbound_email_parser.ex`
     - `web/lib/memba_web/resend_inbound_email_parser.ex`
     - `web/test/memba_web/inbound_email_headers_test.exs`
     - `web/test/memba_web/postmark_inbound_email_parser_test.exs`
     - `web/test/memba_web/resend_inbound_email_parser_test.exs`

3. **Document inbound email routing strategy and invariants**  
   - Disposition: **fixed / already addressed**
   - Evidence from repair inspection: `receive_inbound_club_email/2` documents Topicbox-style routing, same-club matching, fallback-to-new-message behaviour, and unchanged authorization/rejection semantics.
   - Relevant file in final artifact evidence:
     - `web/lib/memba/messaging.ex`

4. **Clarify/enforce persisted `Message-ID` uniqueness/determinism invariant**  
   - Disposition: **fixed / already addressed**
   - Evidence: projection docs state the invariant, and a DB constraint test covers duplicate `outbound_message_id` rejection.
   - Relevant files in final artifact evidence:
     - `web/lib/memba/messaging/projections/email_delivery.ex`
     - `web/test/memba/messaging/email_delivery_status_constraints_test.exs`

### Dismissed with reason

None of the substantive review findings were dismissed as invalid.

### Recorded

`docs/code-health.md` was **not** updated.

The `record_code_health` stage reported:

> `docs/code-health.md was not updated.`  
> Reason given: no visible reviewer-report or synthesis artifact in that checkout contained code-health findings, and independent inspection found no new judgement-worthy, unrecorded findings.

However, the independent review text visible in this run did include judgement-worthy non-blocking findings. Because those were not recorded in `docs/code-health.md`, they are listed below as unhandled workflow gaps rather than treated as fully handled.

### Unhandled workflow gaps

The following non-blocking review findings were raised by independent reviewers but were neither fixed nor recorded in `docs/code-health.md` during this run. This is a workflow gap in the review record, not a merge blocker for the implementation.

1. **Outbound `Message-ID` opacity/privacy**
   - Files referenced by reviewers:
     - `web/lib/memba/messaging/member_message_email.ex`
     - `web/lib/memba/messaging/projections/email_delivery.ex`
   - Finding: outbound `Message-ID` format may expose implementation details such as club slug and/or delivery identity.
   - Status: **unhandled / not recorded**
   - Follow-up: privacy/security review may decide whether to switch to fully opaque random identifiers.

2. **Multiple recognized header candidate ordering**
   - File referenced:
     - `web/lib/memba/messaging.ex`
   - Finding: conversation matching appears to rely on ordering/limit semantics when multiple recognized message-id candidates are present.
   - Status: **unhandled / not recorded**
   - Follow-up: if real `References` chains include multiple recognized Memba messages across conversations, decide whether to prefer `In-Reply-To`, preserve header order, reject ambiguity, or keep newest-match behaviour.

3. **Basic quoted-history stripping**
   - File referenced:
     - `web/lib/memba/messaging.ex`
   - Finding: quote stripping is intentionally heuristic.
   - Status: **unhandled / not recorded**
   - Follow-up: monitor real email replies and consider a stronger email reply parser if stored content quality suffers.

4. **Reply-by-email abuse/autoresponder controls**
   - File referenced:
     - `web/lib/memba/messaging.ex`
   - Finding: authenticated member replies are accepted without reply-specific rate limiting, autoresponder-loop detection, or additional spam controls beyond the current trust model.
   - Status: **unhandled / not recorded**
   - Follow-up: consider rate limiting, loop detection, and abuse controls as usage grows.

5. **Inbound routing responsibility growth**
   - File referenced:
     - `web/lib/memba/messaging.ex`
   - Finding: inbound club email routing is accumulating responsibilities.
   - Status: **unhandled / not recorded**
   - Follow-up: consider extracting header matching, body extraction, reply dispatch, or auto-follow orchestration if later inbound features increase complexity.

6. **RFC/email-client header parsing edge cases**
   - Files referenced:
     - `web/test/memba_web/inbound_email_headers_test.exs`
     - `web/test/memba_web/postmark_inbound_email_parser_test.exs`
     - `web/test/memba_web/resend_inbound_email_parser_test.exs`
   - Finding: parser coverage is good for common cases but limited for real-world RFC/client/provider quirks.
   - Status: **unhandled / not recorded**
   - Follow-up: expand tests using production inbound payload examples.

## Repairs applied during review

A later `apply_review_fixes` pass made **no additional working-tree changes**, because the bounded-safe review items were already present.

That repair verification stage failed only because it expected a diff and none was produced:

> `review repair produced no working-tree diff change since repair started.`

This was a workflow expectation mismatch, not an implementation defect.

The publish step did push a review polish commit:

```text
[e853f9a] review polish: iteration 041
7 files changed, 226 insertions(+), 143 deletions(-)
create mode 100644 web/lib/memba_web/inbound_email_headers.ex
create mode 100644 web/test/memba_web/inbound_email_headers_test.exs
```

Only files present in final artifact evidence are treated as reviewed/repaired.

## Code-health note status

- `docs/code-health.md` was **not updated**.
- The code-health recording stage reported success and no diff to `docs/code-health.md`.
- Because visible independent reviews did contain non-blocking code-health findings, the lack of code-health recording is called out above as an **unhandled workflow gap** for those findings.

## Key files reviewed or repaired

From final artifact gate evidence, key files include:

### Messaging core and inbound routing

- `web/lib/memba/messaging.ex`
- `web/lib/memba/messaging/inbound_email.ex`
- `web/lib/memba/messaging/inbound_email_reply_headers.ex`
- `web/lib/memba/messaging/member_message_email.ex`
- `web/lib/memba/messaging/outbound_message_id.ex`
- `web/lib/memba/messaging/email_delivery_request.ex`
- `web/lib/memba/messaging/email_delivery_dispatcher.ex`
- `web/lib/memba/messaging/local_delivery_facts.ex`

### Email delivery providers and projection

- `web/lib/memba/messaging/email_delivery_providers/local.ex`
- `web/lib/memba/messaging/email_delivery_providers/postmark.ex`
- `web/lib/memba/messaging/email_delivery_providers/resend.ex`
- `web/lib/memba/messaging/projections/email_delivery.ex`
- `web/lib/memba/messaging/projectors/email_delivery.ex`

### Provider-neutral inbound header parsing

- `web/lib/memba_web/inbound_email_headers.ex`
- `web/lib/memba_web/postmark_inbound_email_parser.ex`
- `web/lib/memba_web/resend_inbound_email_parser.ex`

### Migration

- `web/priv/repo/migrations/*add_outbound_message_id_to_messaging_email_deliveries.exs`

### Tests

- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
- `web/test/memba/messaging/inbound_email_api_test.exs`
- `web/test/memba/messaging/inbound_email_reply_headers_test.exs`
- `web/test/memba/messaging/message_projection_test.exs`
- `web/test/memba/messaging/email_delivery_dispatcher_test.exs`
- `web/test/memba/messaging/email_delivery_provider_test.exs`
- `web/test/memba/messaging/email_delivery_providers/fake_test.exs`
- `web/test/memba/messaging/email_delivery_providers/local_test.exs`
- `web/test/memba/messaging/email_delivery_providers/postmark_test.exs`
- `web/test/memba/messaging/email_delivery_providers/resend_test.exs`
- `web/test/memba/messaging/email_delivery_status_constraints_test.exs`
- `web/test/memba_web/inbound_email_headers_test.exs`
- `web/test/memba_web/postmark_inbound_email_parser_test.exs`
- `web/test/memba_web/resend_inbound_email_parser_test.exs`
- `web/test/memba_web/postmark_webhook_controller_test.exs`

### Acceptance files

Final artifact gate confirmed acceptance `.feature` changes were permitted by the plan:

- `acceptance-tests/features/club_message_replies.feature`
- `acceptance-tests/features/member_message_deliverability.feature`

## Publish outcome

Review polish was pushed to `main`.

Publish step output:

```text
Published review polish to main: 17ce647f437df97a8190be7811e4ab07d7a20ce9
```

The iteration status finalization then marked the plan/index as merged and reported no additional finalization commit was needed.

## Tests and validation run

Validation evidence includes:

- Preflight sandbox check passed:
  - `dev sandbox-check`
- Full dev CI passed:
  - `PATH="$PWD/bin:$PATH" dev ci`
- ExUnit evidence:
  - `891 tests, 0 failures`
- Browser acceptance evidence:
  - `82 scenarios passed`
  - `493 steps passed`
- Quick repair-pass validation:
  - `PATH="$PWD/bin:$PATH" dev check --quick`
  - `891 tests, 0 failures`
- Final artifact gate passed and confirmed reviewed implementation evidence.

## Manual demo/checks still recommended

No manual demo is required before accepting the implementation, but the following checks are useful before/after production exposure:

1. Send real replies from common clients — Gmail, Apple Mail, Outlook, mobile clients — and confirm headers are preserved and routed correctly.
2. Verify real provider inbound payloads from Postmark and Resend match parser assumptions.
3. Inspect stored reply bodies from real clients to evaluate quoted-history stripping quality.
4. Review outbound `Message-ID` format for privacy/security implications.
5. Watch operational logs for autoresponder loops or unusually high reply volume.

## Non-blocking follow-ups

1. Consider switching outbound `Message-ID` values to fully opaque identifiers if exposing slug/delivery identity is undesirable.
2. Decide explicit behaviour for multiple recognized same-club header candidates, if real `References` chains expose ambiguity.
3. Improve quoted-history stripping based on real-world email replies.
4. Add reply-by-email rate limiting, autoresponder-loop detection, or spam controls if operational signals warrant.
5. Extract inbound routing collaborators if the function grows with future features such as attachments, moderation, mentions, or richer threading.
6. Expand inbound header parser tests with real provider payloads and RFC/client edge cases.