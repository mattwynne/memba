# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The plan did not cite a specific ADR by number in the provided evidence. Against the architecture-relevant decisions stated in the plan and the implementation evidence, the implementation appears conformant:

- Invitation links use separate invitation-token storage rather than ordinary sign-in tokens.
- Unknown invitees remain pending invitations until profile completion; no incomplete `Person` record is created on first link open.
- Profile-completion state is kept in the invitation/session journey for this slice.
- Existing complete people can accept directly, creating membership, consuming the token, signing in, and landing in the club.
- Tokens are not consumed for unknown invitees on first open; they are consumed only on successful profile completion / acceptance.
- Staff invite routing is additive under the club admin area and does not replace the existing person edit route.
- Direct Staff club-member creation from arbitrary name/email appears decommissioned in favour of invitations.

## ADR violations

None identified.

## Blocking issues

None.

The earlier blocking concern about migrating legacy email data appears to have been addressed by the repair pass via a backfill migration for existing `membership_people.email` values into `membership_person_email_addresses`, with regression coverage for blank, duplicate, and already-primary cases.

The other synthesized blockers appear to have been false positives in the reviewed tree:

1. No empty `AcceptInvitationPlug` is present or wired.
2. Club redirects use `ClubSite.url(club, "/")` / verified routing patterns rather than a hardcoded `"/clubs/#{club_id}"` helper.
3. Invitation email HTML is produced through escaping-aware email template code.

## Bounded-safe fixes

None required before merge.

## Judgement-worthy non-blocking code-health findings

1. **Invitation token generation happens in projection/read-model handling**

   - **Files:** `web/lib/memba/membership/projections/invitation.ex`, related invitation token/read-model code
   - **Smell:** The raw invitation token / hash appears to be generated while handling the `InvitationCreated` projection rather than being included deterministically in the command/event flow.
   - **Why it may need human judgement:** In event-sourced systems, projection rebuilds are ideally deterministic. Regenerating invitation token hashes during rebuild could invalidate outstanding invitation links. This may be acceptable for this MVP slice, but it is worth documenting before projection rebuilds become operationally routine.

2. **Synchronous email delivery during Staff invite flow**

   - **Files:** `web/lib/memba/invitations.ex`, invitation email delivery path
   - **Smell:** Invitation email delivery appears to happen synchronously as part of the Staff invite request.
   - **Why it may need human judgement:** This is simple and reasonable for low-volume Staff usage, but it couples UI latency and failure behaviour to the mail provider. If invitation volume or reliability expectations grow, this should likely move behind a durable async job.

3. **Pending-invitation uniqueness is application-enforced**

   - **Files:** `web/lib/memba/invitations.ex`, invitation table migration/projection
   - **Smell:** Duplicate pending invitation handling appears to rely on application-level lookup/resend logic rather than a partial unique database constraint on `{club_id, normalized_email}` for pending invitations.
   - **Why it may need human judgement:** Concurrent Staff invites for the same club/email could theoretically create duplicate pending invitations or duplicate emails. The practical impact is probably low, but if “one pending invite per club/email” is a hard invariant, a database constraint would be stronger.

4. **`Person.email` as a virtual field can be misleading**

   - **Files:** `web/lib/memba/accounts/person.ex`, callers using person email data
   - **Smell:** Persisted email addresses now live in `person_email_addresses`, while `Person.email` remains virtual for changeset/form input. Loaded `Person` structs may therefore have `person.email == nil`.
   - **Why it may need human judgement:** Future maintainers may accidentally read `person.email` expecting persisted data. A helper such as `Person.primary_email/1` or `Accounts.primary_email_for_person/1` would make the intended access pattern clearer.

## Suggested fixes

No required fixes for this merge.

Optional follow-ups:

- Document or revisit projection-time invitation token generation before relying on projection rebuilds.
- Consider async/durable delivery for invitation emails if usage grows.
- Consider a partial unique index for pending invitations if duplicate pending invites become operationally meaningful.
- Add an explicit primary-email accessor to reduce confusion around the virtual `Person.email` field.

## Validation notes

- `dev ci` passed.
- ExUnit suite passed: `722 tests, 0 failures`.
- Acceptance suite passed: `69 scenarios`, `466 steps`.
- Browser/acceptance coverage includes Staff invitation UI, invitation email link, profile completion, and final redirects.
- Domain/application coverage appears to include:
  - pending invitation creation;
  - duplicate active-member block;
  - duplicate pending invitation resend;
  - existing-person acceptance;
  - unknown-person profile completion;
  - abandoned profile completion;
  - accepted-link reuse.
- Repair pass added/confirmed migration coverage for legacy email backfill edge cases.
- Acceptance feature files were not modified during the repair pass.