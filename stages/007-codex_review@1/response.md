# Iteration Review Report

## Decision: REJECT

## Confidence: Medium

The implementation appears broadly plan-conforming and `dev ci` passed, but there is one deployment-safety gap around the `PersonEmailAddress` storage change that needs either a small implementation pass or an explicit human decision before merge/deploy.

## ADR conformance: PASS

No clear ADR violation is evident from the provided implementation evidence.

The implementation appears to respect the plan’s architecture-relevant decisions:

- Invitation tokens use separate storage from ordinary sign-in tokens.
- Unknown invited emails remain pending invitations; incomplete `Person` records are not created before profile completion.
- Invitation acceptance consumes tokens only after successful acceptance/profile completion.
- Existing complete people can accept and become club members directly.
- The Staff invite route is additive and does not replace the existing person edit route.

## ADR violations

None identified from the available evidence.

## Blocking issues

1. **Potentially unsafe migration from `people.email` to `person_email_addresses` without backfill or explicit no-data decision**

   **Files:**

   - `web/priv/repo/migrations/20250607031033_add_person_email_addresses_table.exs`
   - `web/lib/memba/accounts/person.ex`
   - `web/lib/memba/accounts.ex`

   **Issue:**

   The implementation appears to move email lookup behavior from `people.email` to the new `person_email_addresses` association. `Person.email` is now virtual, and `Accounts.find_person_by_email/1` appears to query `person_email_addresses.normalized_email`.

   The evidence does not show a migration that backfills existing `people.email` values into `person_email_addresses`.

   **Why this blocks:**

   If any existing environment contains persisted `people.email` data, those people may no longer be discoverable by email after deployment. That can affect:

   - duplicate active-member checks;
   - existing-person invitation acceptance;
   - sign-in/onboarding flows that rely on finding a person by email;
   - adjacent Staff/person administration behavior.

   This is not merely polish if real data exists. It needs one of:

   - a data backfill migration;
   - an explicit human/product decision that no deployed database contains relevant `people.email` data and backfill is unnecessary;
   - or a compatibility path that reads both old and new storage until migration is complete.

## Bounded-safe fixes

1. **Remove or document the empty invitation plug**

   **Files:**

   - `web/lib/memba_web/authentication/accept_invitation_plug.ex`
   - `web/lib/memba_web/router.ex`

   `MembaWeb.Authentication.AcceptInvitationPlug` appears to be an empty/pass-through plug. If it has no behavior today, it adds routing/authentication indirection without value.

2. **Replace hardcoded club path construction with verified routes**

   **File:**

   - `web/lib/memba_web/controllers/accept_invitation_controller.ex`

   The helper:

   ```elixir
   defp club_path(club_id) do
     "/clubs/#{club_id}"
   end
   ```

   should use Phoenix verified routes, e.g. `~p"/clubs/#{club_id}"`, or the project’s established club-routing helper if club access is subdomain-aware.

3. **Escape interpolated values in invitation email HTML**

   **File:**

   - `web/lib/memba_web/email/club_member_invitation_email.ex`

   The email HTML appears to interpolate `club.name` directly into an HTML string. Even if club names are Staff-controlled, escaping is the safer default for generated HTML.

## Judgement-worthy non-blocking code-health findings

1. **Invitation token generation in projection/read-model layer**

   **Files:**

   - `web/lib/memba/club_members/projections/invitation.ex`
   - `web/lib/memba/invitations.ex`

   **Smell:**

   The invitation URL token appears to be generated while handling the invitation projection rather than being produced as part of the command/event workflow.

   **Why this may need human judgement:**

   In an event-sourced system, projection rebuilds should usually be deterministic. If rebuilding projections regenerates different invitation token hashes, outstanding invitation links may become invalid. That may be acceptable for this slice, but it is an architectural trade-off worth making explicit.

2. **Synchronous email delivery during Staff invite request**

   **File:**

   - `web/lib/memba/invitations.ex`

   **Smell:**

   Invitation email delivery appears to happen synchronously during the invite workflow.

   **Why this may need human judgement:**

   This is simple and acceptable for low-volume MVP usage, but it couples Staff UI latency and error behavior to the mail provider. If invitation volume or deliverability reliability becomes important, this should move behind a durable async job.

3. **Duplicate pending-invitation race not enforced by database constraint**

   **Files:**

   - `web/lib/memba/invitations.ex`
   - invitation projection/table migration

   **Smell:**

   Duplicate detection appears to be performed in application code by looking for a pending invitation before creating/resending. There does not appear to be a partial unique database constraint for pending invitations by `{club_id, normalized_email}`.

   **Why this may need human judgement:**

   Concurrent invites for the same email and club could create duplicate pending invitations and send duplicate emails. The behavioral impact is probably low, but database constraints are usually better for enforcing uniqueness when the invariant matters.

4. **Virtual `Person.email` field may confuse future maintainers**

   **Files:**

   - `web/lib/memba/accounts/person.ex`
   - callers that need a person’s email address

   **Smell:**

   `Person.email` appears to be retained as a virtual changeset input while persisted email addresses live in `person_email_addresses`.

   **Why this may need human judgement:**

   After loading a `Person`, `person.email` will be `nil` unless manually populated. Future code may accidentally use the virtual field and miss the associated email addresses. A clear accessor such as `Person.primary_email/1` or `Accounts.primary_email_for_person/1` would reduce ambiguity.

5. **Invitation email template is intentionally minimal**

   **File:**

   - `web/lib/memba_web/email/club_member_invitation_email.ex`

   **Smell:**

   The email appears functional but basic: minimal branding, no reusable template, and no styling system.

   **Why this may need human judgement:**

   This is acceptable for an implementation slice, but before broader production use, invitation emails may need product/design review.

## Suggested fixes

Because the decision is `REJECT`, address the blocking migration/data compatibility issue first.

Recommended implementation options:

1. **Preferred: add a backfill migration**

   Add a migration that copies existing `people.email` rows into `person_email_addresses` with normalized email values, preserving existing people for duplicate checks and invitation acceptance.

   The migration should:

   - skip blank/null emails;
   - normalize using the same semantics as the application where practical;
   - avoid duplicate rows;
   - preserve timestamps;
   - be safe to run once in deployed environments.

2. **Alternative: explicit human decision**

   If Matt confirms there is no deployed/persistent data requiring migration, record that decision in the iteration notes or an appropriate technical note, then the blocker can be waived.

3. **Then apply bounded-safe cleanup**

   - Remove the empty `AcceptInvitationPlug` or give it a real documented responsibility.
   - Replace hardcoded `"/clubs/#{club_id}"` with verified routes.
   - Escape interpolated email HTML values.

## Validation notes

- `dev ci` succeeded.
- Acceptance suite succeeded: `69 scenarios`, `466 steps`.
- Sandbox runtime check passed.
- The implementation appears to cover the main planned flows:
  - Staff invite form;
  - invitation email link;
  - existing-person acceptance;
  - unknown-person profile completion;
  - duplicate active-member block;
  - duplicate pending invitation resend;
  - accepted-link reuse behavior.
- The remaining blocker is not exposed by the green test suite because it concerns migration behavior for pre-existing persisted `people.email` data.