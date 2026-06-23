# 045 — Stop-following page: minimal header

Date: 2026-06-23
Status: validated

## Goal

The conversation stop-following confirmation page (`GET /messages/conversations/stop-following/:token`)
uses a **minimal Memba-mark header** instead of the public marketing nav. A recipient
arriving from a "Stop following this conversation" email link should not be met with
`Sign in` / `Request access` marketing calls-to-action.

## Background / Context

`MembaWeb.ConversationFollowController` renders `stop_following.html.heex` inside
`<Layouts.app>`, whose header carries the marketing nav (`layouts.ex` ~lines 28–58:
`Sign in`, `Request access`). The replies-feature gap analysis (`docs/replies-wireframe-gaps.md`,
bucket D / E2) flagged this as the wrong chrome for an email-unsubscribe landing page. The
target design (`wireframes/conversation-stop-following.html`) uses a minimal Memba mark +
wordmark header with no nav.

## Related Problems

- [`docs/problems/2026-06-22-replies-feature-design-gaps.md`](../../problems/2026-06-22-replies-feature-design-gaps.md)
  — **resolves the last open bucket (D).** A (overview) shipped in 043, B (conversation
  page) in 044, C (emails) was reconciled in the app's favour with the designs updated.
  After this iteration the gap note is fully addressed.

## Scope

### In scope

- The stop-following page header chrome only, for both the `:success` and `:failure`
  (invalid-link) states: replace the marketing nav with a minimal Memba mark + wordmark.

### Out of scope

- The unfollow behaviour, token verification, and copy of the page (unchanged).
- Every other page that uses `Layouts.app` (its marketing header stays as-is).

## Iteration Type

Presentational alignment — no new user-observable rule. The page does the same thing; only
its surrounding chrome changes. Comparable to the design-system alignment iterations.

## Acceptance Scenarios / Feature Files

BDD decision: **Not useful for this slice.** The stop-follow behaviour is already covered by
`acceptance-tests/features/club_message_replies.feature` (the reply-email stop-follow link
and tampered-link scenarios, iterations 040–041). This slice changes only the page chrome,
not the rule. No Gherkin is added or changed.

## Designs

- Target design exists and is synced: `wireframes/conversation-stop-following.html`
  (minimal Memba mark + wordmark header, no nav; success and invalid-link states).
- No new design work needed.

## Acceptance Criteria

- The stop-following page (success and invalid states) renders a minimal header showing the
  Memba sprig mark and the "Memba" wordmark.
- The page does **not** render the marketing nav links (`Sign in`, `Request access`).
- The page content (eyebrow, heading, copy, and the "View the conversation" / "Go to Memba"
  action) is unchanged.

## Open Business Decisions

None known.

## Implementation Plan

1. Add a minimal "brand-bar" layout to `MembaWeb.Layouts` (e.g. `Layouts.brand_bar/1`):
   a header with the existing `<.sprig>` mark + "Memba" wordmark and no nav, wrapping
   `inner_block`, plus the standard flash group. Keep it small and reusable for other
   email-landing pages.
2. Change `stop_following.html.heex` to wrap its content in `<Layouts.brand_bar>` instead of
   `<Layouts.app>`. No change to the `:success` / `:failure` content.
3. No controller, routing, command, or behaviour changes.

## Open Technical Decisions

None known. (Prefer a dedicated minimal layout over an attr-flag on `Layouts.app`, so the
marketing header stays single-purpose and the minimal chrome is reusable.)

## New Capability

Email-unsubscribe and similar one-click landing pages can present a calm, minimal Memba
header instead of marketing CTAs — starting with the stop-following confirmation.

## Validation Plan

- A controller/template test for `ConversationFollowController` (or the HTML module)
  asserting the success and failure renders include the Memba mark/wordmark and do **not**
  include `Sign in` / `Request access`.
- Existing `club_message_replies.feature` stop-follow scenarios stay green.
- A `bin/dev gallery-walk` screenshot of the `conversation-stop-following` scene confirming
  the minimal header.

## Risks / Follow-ups

- If `Layouts.brand_bar` is reused elsewhere later, keep it free of page-specific copy.
- This closes the replies-feature design-gaps note; remaining replies follow-ups (the
  unread/new-activity indication) are tracked in their own problem note.
