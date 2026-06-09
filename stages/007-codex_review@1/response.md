# Implementation Review Report

## Decision: REJECT

## Confidence: Medium

The implementation appears close and dev check is green, but the provided evidence surfaces at least one likely behavioural/ADR gap: invitation email delivery appears to be a TODO logger rather than a real email/link dispatch path. Because invitation delivery and one-use link verification are central to the planned capability and ADR-shaped invitation lifecycle, this needs either implementation and tests or an explicit human decision that this slice intentionally defers email delivery.

## ADR conformance: FAIL

## ADR violations

1. **ADR 006 / Member Invitation Lifecycle — invitation email/link delivery is not implemented on the apparent send path**

   **Evidence:** The implementation evidence/prior review surfaced `InvitationService.send_invitation_email/1` as:

   ```elixir
   defp send_invitation_email(invitation) do
     # TODO: Implement email sending
     Logger.info("Sending invitation email to #{invitation.invitee_email}...")
     :ok
   end
   ```

   The plan’s central capability says Membership Admin invitations should preserve Memba’s email-control verification through an invitation link, and the implementation plan explicitly calls out reusing the Staff invitation command/application service for “email, one-use-link, acceptance, and profile-completion rules.”

   If this private function is the actual email dispatch path for Membership Admin invitations, the implementation omits a central lifecycle decision rather than merely deferring a future enhancement. A flash saying “invitation sent” plus a persisted pending invitation is not equivalent to sending an invitee a one-use acceptance link.

## Blocking issues

1. **Invitation delivery appears functionally incomplete**

   The invite action can create or resend an invitation, but the shown send path logs a message and returns `:ok`. That means the invitee may never receive a link and cannot complete the intended flow.

   This needs one of:

   - implement real email delivery using the project mailer/Swoosh infrastructure and include the one-use invitation URL, or
   - prove that another already-wired layer sends the email for this service, or
   - get an explicit human/product decision that email delivery is deferred despite the plan/ADR wording.

   Automated coverage should prove that an invitation email is emitted for a Membership Admin invitation, not just that the service returns success.

2. **Membership Admin invitation acceptance/profile-completion reuse is not sufficiently evidenced**

   The plan requires Staff and Membership Admin invitations to share one-use-link, acceptance, and profile-completion rules, and requires accepted Membership Admin invitations to create ordinary active memberships only.

   The provided changed-file evidence clearly shows creation-side route/service/tests, but does not prove that a Membership Admin-created invitation can travel through the existing acceptance/profile-completion path and result in an ordinary membership. This may exist in pre-existing iteration 028 code, but the review evidence does not establish it.

   This needs either:

   - tests demonstrating that a Membership Admin-created invitation is accepted through the shared invitation lifecycle and creates an ordinary active membership, or
   - a clear pointer to existing tests that already cover this exact source/type of invitation, or
   - a human decision that this iteration is creation-only despite the plan language.

## Bounded-safe fixes

1. **Normalize invitee email before duplicate checks and persistence**

   In `Memba.Memberships.InvitationService` / invitation changeset, trim and downcase `invitee_email` before:

   - duplicate active-member lookup,
   - duplicate pending-invitation lookup,
   - persistence,
   - email dispatch.

   This prevents case/whitespace variants such as `Robin@Example.com` and ` robin@example.com ` from bypassing duplicate checks.

2. **Tighten email validation**

   If the current validation only checks for `@`, replace it with a modest practical format validation such as:

   ```elixir
   ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/
   ```

   Keep this consistent with the project’s existing account/email validation rules if those already exist.

3. **Use `type="email"` and `required` in the invitation HEEx form**

   In the Membership Admin invitation form, prefer the project’s `<.input>` component with:

   ```heex
   type="email"
   required
   autocomplete="email"
   ```

   This improves browser-level UX without changing server-side behaviour.

4. **Add database-backed uniqueness for invitation invariants if not already present**

   The service-level duplicate pending-invitation check is useful but race-prone. Consider unique indexes for:

   - invitation token,
   - active pending invitation per club/email, ideally using normalized/lowercase email semantics.

   This is safest after email normalization is in place.

5. **Consider `Ecto.Enum` or a database check constraint for invitation state**

   If invitation state is currently a plain string, use either:

   - `Ecto.Enum` in the schema, or
   - a migration-level check constraint,

   to prevent invalid states from drifting into persisted invitation records.

## Judgement-worthy non-blocking code-health findings

1. **Files:** `lib/memba/memberships/aggregates/invitation.ex`, `lib/memba/memberships/invitation_service.ex`, invitation command/event files  
   **Smell:** Possible duplication or replacement of iteration 028 Staff invitation infrastructure.  
   **Why judgement may be needed:** The plan explicitly says to reuse iteration 028’s Staff invitation lifecycle rather than create a parallel Membership Admin-only system. The evidence describes new invitation infrastructure in this iteration. That may be fine if this implementation is the shared foundation, but if Staff invitations already have separate infrastructure, this would create architecture drift against ADR 006.

2. **Files:** `lib/memba/memberships/invitation_service.ex`  
   **Smell:** Invitation creation and email side effect appear coupled synchronously.  
   **Why judgement may be needed:** Once real email sending is implemented, a failed mail send could leave a pending invitation in the database with no delivered link, or a retry could resend unexpectedly. The project may want an explicit policy: synchronous send, transactional outbox, background job, or persisted resend state.

3. **Files:** `lib/memba_web/live/member_live/index.ex`, `lib/memba_web/live/member_invitation_live/new.ex`  
   **Smell:** The new member-facing members/invitation surface is intentionally minimal.  
   **Why judgement may be needed:** This matches the plan’s “do not prebuild” guidance, but it will likely become the anchor for pending invitations, resends, cancellation, role management, and member removal. Future work should avoid accreting those behaviours directly into a thin LiveView without a clear context/service boundary.

4. **Files:** invitation tests and Memberships context query helpers  
   **Smell:** Duplicate checks may depend on application queries rather than database constraints.  
   **Why judgement may be needed:** Green tests prove normal duplicate handling, but concurrent invite submissions can still create duplicate pending invitations unless the database enforces the invariant.

## Suggested fixes

Because this review rejects on likely lifecycle incompleteness:

1. Replace the `send_invitation_email/1` TODO with real mail delivery using the project’s mailer infrastructure.
2. Ensure the email includes the secure one-use invitation acceptance URL.
3. Add tests proving a Membership Admin invitation emits an email with the acceptance link.
4. Add or identify tests proving a Membership Admin-created invitation can be accepted through the shared lifecycle and results in an ordinary active membership, not a Membership Admin role.
5. Add email normalization before duplicate checks and persistence.
6. Re-run `dev check`.

If a human explicitly decides email delivery or acceptance/profile-completion is deferred, document that decision and narrow the implementation/tests to the creation-only behaviour intentionally supported by this slice.

## Validation notes

- `dev ci` / `dev check` passed successfully.
- Acceptance suite passed: 73 scenarios, 489 steps.
- Preflight sandbox check passed.
- The implementation appears to include meaningful tests for:
  - Membership Admin visibility/access,
  - ordinary member rejection,
  - non-member rejection,
  - invitation form submission,
  - duplicate active member rejection,
  - duplicate pending invitation handling,
  - route wiring.
- The remaining concern is not general test failure; it is that green tests do not appear to prove actual email delivery or full acceptance/profile-completion reuse for Membership Admin-created invitations.