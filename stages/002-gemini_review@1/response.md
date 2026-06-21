## Decision: READY

## Confidence: High

## Blocking gaps

None.

## Non-blocking improvements

1. Acceptance criteria could explicitly mention unsupported attachments/body handling, since it is listed in scope and implementation steps but not as its own acceptance criterion.
2. The plan could name the likely existing domain functions for “post via the 039 reply path” and follower fan-out if known, but the current guidance is specific enough for implementation.
3. The plan could state whether inbound replies to original club-wide message emails and replies to reply-notification emails both produce the same `References` chain expectations, though this is implied by persisted outbound `Message-ID` mappings.

## Smallest viable iteration

The smallest useful slice is the one already described: persist Memba-controlled outbound `Message-ID` mappings, emit reply/threading headers on outbound conversation emails, and route inbound club-address mail with recognized same-club reply headers into the existing conversation reply path while preserving the no-header new-message fallback.

Further reducing it would likely remove the core user outcome: replying from an email client and having the reply land in the tracked conversation.

## Required plan edits

None required.

## Validation plan

To prove the iteration succeeded:

1. Add/update `@iteration-041` acceptance scenarios in `acceptance-tests/features/club_message_replies.feature` covering:
   - member email reply lands in the conversation;
   - reply is attributed to the sender;
   - replier auto-follows;
   - followers receive the reply;
   - same club address without recognized reply headers creates a new club-wide message;
   - non-member reply is rejected;
   - headers matching a message in another club do not create a cross-club reply.

2. Add focused automated tests for:
   - outbound emails including persisted Memba-controlled RFC `Message-ID`;
   - reply notification emails using `<club-slug>@clubs.memba.io` as reply destination;
   - `In-Reply-To` / `References` generation;
   - parsing `In-Reply-To` and `References`, including angle brackets, whitespace, folded values, and multiple references;
   - lookup requiring same-club match;
   - missing, malformed, unknown, and different-club message ids falling back safely;
   - inbound matched reply posting through the existing reply path;
   - non-member and ambiguous sender rejection;
   - basic quoted-history stripping and blank-body rejection.

3. Confirm existing 019/020 inbound club-message behaviour still works when no same-club reply header is recognized.

4. Confirm existing 039/040 conversation, reply, follow, and follower-delivery behaviour remains green.

5. Run `dev check`.

{"context_updates":{"gemini_review_decision":"READY","gemini_review_confidence":"High","gemini_review_blocking_gap_count":0,"gemini_review_blocking_gaps":"None","gemini_review_required_edits":"None"}}