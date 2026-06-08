# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The supplied plan/evidence did not identify any specific ADR by number. Against the architecture-relevant decisions stated in the iteration plan and visible implementation evidence, the implementation is conformant:

- Invitation links use separate invitation-token storage rather than ordinary sign-in tokens.
- Unknown invitees remain pending invitations until profile completion; no incomplete `Person` is created on first link open.
- Profile-completion state lives in the invitation/session journey for this slice.
- Tokens are not consumed when an unknown invitee first opens the link; they are consumed only after successful profile completion / membership activation.
- Existing complete people can accept directly: membership is created, token is consumed, they are signed in, and they are routed to the club.
- Staff invite routing is additive under `/admin/clubs/:club_id/...` and does not replace the existing person edit route.
- Direct Staff club-member creation from arbitrary name/email appears decommissioned in favour of invitations.
- Email normalization and duplicate checks appear aligned with the new person-email-address model.

## ADR violations

None identified.

## Blocking issues

None.

The implementation appears plan-conforming, behaviourally covered, and production-ready for this slice. The remaining pipeline blocker, `make-gemini-review-visible`, is a workflow/provider artifact issue caused by the failed `gemini_review` stage, not an implementation defect.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Invitation token generation occurs in projection/read-model handling**

   - **Files:** `web/lib/memba/membership/projections/invitation.ex`, related invitation token/read-model code
   - **Smell:** `InvitationToken.build_hashed_token()` appears to be called while handling the invitation projection rather than having deterministic token material included in command/event data.
   - **Why it may need human judgement:** Event-sourced projection rebuilds are ideally deterministic. If rebuilding projections regenerates token hashes, outstanding invitation links may be invalidated. This is acceptable for an MVP if projection rebuilds are rare and pending invitations can be reissued, but it should be documented or revisited before operational projection rebuilds become routine.

2. **Invitation email delivery is synchronous in the Staff invite flow**

   - **Files:** `web/lib/memba/invitations.ex`
   - **Smell:** Invitation email delivery appears to happen during the Staff HTTP request.
   - **Why it may need human judgement:** This is simple and reasonable for low-volume Staff use, but it couples UI latency and failure behaviour to the mail provider. If invitation volume, reliability, or retry semantics become important, this should likely move behind a durable async job.

3. **Pending invitation uniqueness is application-enforced**

   - **Files:** `web/lib/memba/invitations.ex`, invitation table migration/projection code
   - **Smell:** Duplicate pending invitation handling appears to rely on application-level lookup/resend logic rather than a partial unique database constraint on `{club_id, normalized_email}` for pending invitations.
   - **Why it may need human judgement:** Concurrent Staff invites for the same club/email could theoretically create duplicate pending invitations or duplicate emails. The practical risk is low for this slice, but if “one pending invite per club/email” is a hard invariant, a database constraint would be stronger.

4. **`Person.email` remains a virtual field after persisted email addresses moved elsewhere**

   - **Files:** `web/lib/memba/accounts/person.ex`, callers that need primary email data
   - **Smell:** Persisted email addresses now live in `person_email_addresses`, while `Person.email` is virtual/form-oriented. Loaded `Person` structs may therefore have `person.email == nil`.
   - **Why it may need human judgement:** Future maintainers may accidentally read `person.email` expecting persisted data. A helper such as `Person.primary_email/1` or `Accounts.primary_email_for_person/1` could make the intended access path clearer.

5. **Migration timestamp anomaly**

   - **Files:** `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`, `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`
   - **Smell:** The backfill migration is timestamped in 2026 while related schema work is timestamped in 2025.
   - **Why it may need human judgement:** The migration ordering is numerically valid, so this is not a functional issue. However, future-dated migration filenames can confuse maintainers or deployment audits if this branch is merged long before that date.

## Suggested fixes

No required fixes for this merge.

Optional follow-ups:

- Document or revisit projection-time invitation token generation before relying on projection rebuilds.
- Consider async/durable email delivery if invitation volume or retry requirements grow.
- Consider a partial unique index for pending invitations if duplicate pending invites become operationally meaningful.
- Add an explicit primary-email accessor to reduce confusion around the virtual `Person.email` field.
- Consider normalizing future-dated migration timestamps before production deployment if that matters operationally.

## Validation notes

- `dev ci` passed.
- ExUnit suite passed: `722 tests, 0 failures`.
- Acceptance suite passed: `69 scenarios`, `466 steps`.
- Browser/acceptance coverage appears to include:
  - Staff invitation UI;
  - invitation email link;
  - profile completion page;
  - final redirect to the club.
- Domain/application coverage appears to include:
  - pending invitation creation;
  - active-member duplicate block;
  - duplicate pending invitation resend;
  - existing-person acceptance;
  - unknown-person profile completion;
  - abandoned profile completion;
  - accepted-link reuse.
- Migration/backfill coverage appears to include legacy email migration edge cases such as blank, duplicate, and already-primary email data.
- No code/config/test repair was needed after review; the remaining reported blocker is a Fabro/Gemini review visibility issue, not a product-code issue.