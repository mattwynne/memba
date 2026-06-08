# Iteration Review Report

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation plan does not cite specific ADR numbers, but explicitly outlines architectural decisions for this slice (e.g., separate invitation token storage, not creating incomplete person records, token lifecycle rules). Based on the implementation evidence, these constraints have been faithfully executed:
- Invitation tokens have their own database-backed storage (`InvitationToken`).
- Unknown invited emails are kept as pending invitations, without prematurely creating incomplete `Person` records.
- Profile-completion state is stored in the session (`put_session(:invitation_email, ...)`).
- Tokens are not prematurely consumed when the link is first clicked by unknown invitees.
- The existing person acceptance flow properly consumes the token, creates the membership, and signs the user in.

## ADR violations

None identified.

## Blocking issues

None.

*(Note: The `make-gemini-review-visible` issue raised in previous pipeline stages is a Fabro workflow/provider artifact visibility error, not a product-code implementation defect.)*

## Bounded-safe fixes

None required. The code is well-tested and meets the plan's requirements.

## Judgement-worthy non-blocking code-health findings

1. **Synchronous Email Delivery in Web Request**
   - **Files:** `web/lib/memba/invitations.ex`
   - **Smell:** `Memba.Mailer.deliver(email)` is called synchronously within the web request lifecycle when a Staff member invites someone.
   - **Why it may need human judgement:** Synchronous delivery couples the application's response time and failure modes to the upstream email provider. This is acceptable for a low-volume MVP Staff tool, but if invitation volume scales or retry semantics become critical, this should be moved to a durable background job queue (e.g., Oban).

2. **Non-deterministic Projection Rebuilds (Token Generation)**
   - **Files:** `web/lib/memba/membership/projections/invitation.ex`
   - **Smell:** `InvitationToken.build_hashed_token()` is executed during the projection event handler.
   - **Why it may need human judgement:** Event-sourced projections should ideally be pure functions of the event stream. By generating random tokens during projection, rebuilding the read model will yield different hashes, invalidating any outstanding invitation links. Given these are one-use links and projection rebuilds are currently rare, this trade-off is acceptable for the MVP, but it should be documented or refactored if rebuilds become a routine operational task.

3. **Application-level Uniqueness for Pending Invitations**
   - **Files:** `web/lib/memba/invitations.ex`
   - **Smell:** Preventing duplicate pending invitations for the same email and club relies on application-level checks rather than a partial unique database index (e.g., unique on `club_id` and `normalized_email` where `status = 'pending'`).
   - **Why it may need human judgement:** Concurrent requests could theoretically result in duplicate pending invitations and multiple emails being sent. Since only one can ultimately be accepted, the data integrity risk is low. However, a database constraint provides stronger guarantees if this becomes problematic.

4. **Virtual Field Access for Primary Emails**
   - **Files:** `web/lib/memba/accounts/person.ex`
   - **Smell:** With the migration to `person_email_addresses`, `Person.email` is now a virtual field used primarily for forms. Loaded `Person` structs will have `email: nil`, requiring developers to traverse the preloaded `email_addresses` association to find the primary email.
   - **Why it may need human judgement:** This access pattern can easily trip up future maintainers. Introducing a helper like `Person.primary_email(person)` would improve developer experience and reduce the risk of bug introduction.

5. **Migration Timestamp Anomaly**
   - **Files:** `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`
   - **Smell:** The migration timestamp is dated in the future (June 2026), whereas the related schema creation is from 2025.
   - **Why it may need human judgement:** While numerically valid and functionally safe, future-dated migrations can cause confusion during audits or deployments. It is a minor cosmetic issue.

## Suggested fixes

No fixes are required to merge this iteration.

Optional follow-ups for the team to consider:
- Implement a `Person.primary_email/1` helper to encapsulate finding the primary email from preloaded associations.
- Document the side-effects of rebuilding the invitation projection.
- Consider moving email delivery to a background job if response latency or delivery reliability issues arise.

## Validation notes

- ExUnit test suite is completely green (`722 tests, 0 failures`).
- Browser acceptance test suite is green (`69 scenarios, 466 steps`), covering Staff invitation UI, invalid slugs, email delivery, profile completion, and redirection.
- `dev ci` passes cleanly, indicating formatting, compilation, and sandbox checks are healthy.
- All 16 implementation steps outlined in the plan have been fulfilled.