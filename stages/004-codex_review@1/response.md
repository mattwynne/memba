## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/041-reply-by-email-threading/plan.md` lines 1–148.

## Blocking gaps

1. None.

## Non-blocking improvements

1. The implementation plan could optionally name the exact persistence shape once chosen, such as a dedicated table versus fields on an existing delivery/request record, but the current constraints are sufficient for implementation.
2. The validation plan could explicitly mention replay/idempotency behavior for inbound provider retries if that is already part of the existing inbound pipeline, but this is not required to start.
3. The acceptance scenarios could eventually include a `References`-only case in addition to `In-Reply-To`, since the routing model depends on both. The plan already calls for header parsing/lookup tests, so this is not blocking.

## Smallest viable iteration

The smallest useful slice is the plan as written: support email replies to Memba-generated emails sent after this change by persisting outbound RFC `Message-ID` values, matching inbound `In-Reply-To` / `References` headers for the addressed club, posting authorized member replies into the existing conversation, and preserving the no-header fallback to new club-wide messages.

This slice is coherent and hard to reduce further without losing the core user outcome: “reply from email and have it land in the right Memba conversation.”

## Required plan edits

None.

## Validation plan

To prove the iteration succeeded:

1. Add or extend acceptance scenarios in `acceptance-tests/features/club_message_replies.feature` tagged `@iteration-041`.
2. Verify generated outbound club/reply emails include persisted Memba-controlled RFC `Message-ID` values.
3. Verify reply notification emails use the club inbound address and include correct email threading headers.
4. Verify inbound `In-Reply-To` and `References` headers resolve only to same-club conversations.
5. Verify a current member’s email reply is posted into the correct conversation, attributed to them, auto-follows them, and fans out to followers.
6. Verify no recognized same-club reply header preserves existing behavior by creating a new club-wide message.
7. Verify non-member, ambiguous sender, malformed/unsupported, and blank-body cases reuse existing safe rejection behavior.
8. Verify cross-club header matches do not create cross-club replies.
9. Run the relevant automated tests and full `dev check`.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}