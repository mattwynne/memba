# Implementation Review Report

## Decision: REJECT
## Confidence: High
## ADR Conformance: FAIL

## ADR Violations

1. **ADR 006: Member Invitation Lifecycle - Email delivery and one-use link omitted**
   - **Evidence**: Previous review evidence indicates that `InvitationService.send_invitation_email/1` contains a `# TODO: Implement email sending` and merely logs the intent before returning `:ok`.
   - **Conflict**: ADR 006 and the iteration plan dictate that Memba "verifies email control through an invitation link" and that the implementation should reuse Iteration 028's rules for "email, one-use-link, acceptance, and profile-completion." Stubbing the email side-effect completely breaks the invitation lifecycle, stranding the pending invitation in the database with no way for the user to accept it.

## Blocking Issues

1. **Missing Email Delivery and Link Generation**
   The capability explicitly requires Memba to verify email control via an invitation link. If the `send_invitation_email/1` function is just a logger stub, the feature is functionally broken for the end user. You must integrate actual email delivery using the project's Swoosh mailer infrastructure and include a valid, secure one-use acceptance URL.
2. **Unverified Acceptance/Profile-Completion Reuse**
   The plan mandates reusing the acceptance and profile-completion rules from Iteration 028, guaranteeing that Membership Admin invitations result in ordinary active memberships. The current implementation evidence clearly shows the creation side but lacks proof that the Membership Admin invitations correctly enter the existing acceptance flow. The tests or implementation must explicitly wire up or cover the acceptance phase.

## Bounded-Safe Fixes

1. **Email Normalization**: Before performing duplicate checks (active member or pending invitation) and before persisting to the database, `String.downcase/1` and `String.trim/1` the input email address. This prevents case-sensitivity bugs from creating duplicate records (e.g., `User@example.com` vs `user@example.com`).
2. **Form HTML5 Validation**: In the new Member Invitation LiveView HEEx template, use `type="email"`, `autocomplete="email"`, and `required` on the email input component to provide instant, browser-native feedback.
3. **Form Double-Submit Prevention**: Add a `submitting` boolean to the LiveView assigns. Set it to `true` during the `handle_event("submit", ...)` phase to disable the submit button and prevent accidental duplicate invitation dispatches.
4. **Changeset Regex Enhancements**: If the email validation on the invitation changeset only checks for the presence of an `@`, strengthen it to a more robust format like `~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/`.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **File(s)**: `lib/memba/memberships/aggregates/invitation.ex`, `lib/memba/memberships/invitation_service.ex`, etc.
   - **Smell**: Potential architectural duplication of Iteration 028 infrastructure.
   - **Why it needs judgement**: The plan explicitly says to "reuse" Iteration 028's Staff invitation command/service. If this implementation created brand new domain aggregates/services from scratch, it might be running parallel to the Staff system rather than sharing a unified domain model as ADR 006 requires. Human/architectural validation is needed to ensure we only have one unified invitation lifecycle system.
2. **File(s)**: `lib/memba_web/live/member_invitation_live/new.ex`, `lib/memba/memberships/invitation_service.ex`
   - **Smell**: Application-level uniqueness checks vs Database Constraints.
   - **Why it needs judgement**: Relying strictly on `get_pending_invitation_by_email` before insert creates a race condition. For true data integrity, an Ecto unique index (scoped to the club and normalized email) should back up the application-level validation.
3. **File(s)**: `lib/memba/memberships/invitation.ex`
   - **Smell**: State machine string types.
   - **Why it needs judgement**: The `state` field is likely a plain string. Using `Ecto.Enum` for `[:pending, :accepted, :expired, :cancelled]` would provide stronger compile-time guarantees and prevent invalid states from drifting into the data store.

## Suggested Fixes

Since this implementation is rejected due to a missing core lifecycle capability:
1. Implement the Swoosh mailer integration in `send_invitation_email/1` (or delegate to the service built in Iteration 028) so an actual email containing the one-use link is delivered.
2. Write automated tests asserting that a Membership Admin invitation actually emits an email to the correct address with the generated link.
3. Ensure automated coverage proves that a Membership Admin invitation can be successfully accepted (via the shared Iteration 028 acceptance route) and results in an ordinary member.
4. Apply the bounded-safe UI fixes (HTML5 email validation, loading states) and data sanitization (downcasing emails before duplicate checks).

## Validation Notes
- **`dev check` Output**: 73 scenarios and 489 steps passed successfully.
- **Test Gap**: The passing test suite proves that the domain allows creation and the router correctly authorizes Membership Admins. However, the suite lacks behavioral assertions verifying the email side-effect and the actual acceptance flow for Membership Admin-created links. 
- **Preflight Checks**: Passed and cleanly branched.