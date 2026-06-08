# Iteration Review Report

## Decision: REJECT

## Confidence: High

## ADR Conformance: PASS

## ADR Violations
None identified. The implementation adheres to the architectural decisions stated in the plan (e.g., using separate invitation token storage, preserving incomplete person creation for profile completion, etc.).

## Blocking Issues
1. **Missing Data Migration for `people.email` to `person_email_addresses`**
   The implementation introduces a new `person_email_addresses` table and modifies the `Person` schema to make `email` a virtual field. `Accounts.find_person_by_email/1` has been updated to query the new `person_email_addresses` table instead of the `people` table. However, there is no backfill migration to move existing `people.email` data into `person_email_addresses`.
   
   If any existing environment (such as production) contains persisted `people.email` data, those users will no longer be discoverable by email. This breaks duplicate active-member checks, existing-person invitation acceptance, and staff administration for those users. This requires either a data backfill migration or an explicit product decision that existing data can be safely discarded.

## Bounded-Safe Fixes
1. **Remove or document unused `AcceptInvitationPlug`**
   `MembaWeb.Authentication.AcceptInvitationPlug` is defined but empty. Either remove it from the `router.ex` pipeline and delete the file, or add a module doc explaining it is a placeholder for future middleware.
2. **Replace hardcoded club path construction with verified routes**
   In `accept_invitation_controller.ex`, the helper `defp club_path(club_id), do: "/clubs/#{club_id}"` should use Phoenix verified routes (e.g., `~p"/clubs/#{club_id}"`) or the project's established subdomain-aware routing pattern.
3. **Escape interpolated values in invitation email HTML**
   In `club_member_invitation_email.ex`, `club.name` is interpolated directly into an HTML string (`<h2>You're invited to join #{club.name}!</h2>`). Even if club names are Staff-controlled, it is a safer default to use `Phoenix.HTML.html_escape/1` for generated HTML.

## Judgement-Worthy Non-Blocking Code-Health Findings
1. **Synchronous Email Delivery (Performance)**
   **File(s)**: `web/lib/memba/invitations.ex`
   **Smell**: Invitation email delivery happens synchronously during the HTTP request.
   **Why it may need human judgement**: This ties the Staff UI latency and error behavior to the email provider's response time. It is perfectly acceptable for a low-volume MVP, but may need to be moved behind a durable async job (e.g., Oban) as the application scales.
2. **Virtual `Person.email` field may cause confusion (Maintainability)**
   **File(s)**: `web/lib/memba/accounts/person.ex`
   **Smell**: `Person.email` is retained as a virtual field strictly for changeset inputs. After loading a `Person` from the database, `person.email` will be `nil`.
   **Why it may need human judgement**: Future maintainers may accidentally use the virtual field expecting a value. Adding an explicit accessor like `Person.primary_email/1` or `Accounts.primary_email_for_person/1` would reduce ambiguity.
3. **Duplicate pending-invitation race not enforced by database constraint (Data Integrity)**
   **File(s)**: `web/lib/memba/invitations.ex`, invitations table migration
   **Smell**: Duplicate detection is performed in the context layer by checking for an existing pending invitation before creating or resending. There is no partial unique database constraint for pending invitations on `{club_id, normalized_email}`.
   **Why it may need human judgement**: Concurrent invites could theoretically create duplicate pending invitations and send duplicate emails. Adding a unique constraint would provide stronger structural guarantees.
4. **Invitation token generation in projection/read-model layer (Architecture)**
   **File(s)**: `web/lib/memba/club_members/projections/invitation.ex`
   **Smell**: The invitation URL token appears to be generated while handling the invitation projection, rather than being produced as part of the command/event workflow.
   **Why it may need human judgement**: In an event-sourced system, projection rebuilds should usually be deterministic. If rebuilding the projection regenerates different invitation token hashes, outstanding invitation links could be invalidated. This architectural trade-off is worth noting for the future.

## Suggested Fixes
1. **Add a backfill migration**: Create an Ecto migration that copies existing `people.email` rows into `person_email_addresses` with normalized email values, skipping nulls and preserving timestamps.
2. **Clean up Plug**: Delete `web/lib/memba_web/authentication/accept_invitation_plug.ex` and remove it from `router.ex`.
3. **Use verified routes**: Update `club_path/1` in `accept_invitation_controller.ex` to use `~p"/clubs/#{club_id}"`.
4. **Escape HTML**: Wrap `club.name` in `Phoenix.HTML.html_escape/1` in `club_member_invitation_email.ex`.

## Validation Notes
- **Dev Check**: Passed successfully.
- **Automated Coverage**: 69 scenarios and 466 steps passed. Domain, controller, LiveView, and email delivery tests cover the planned invitation lifecycle correctly.
- **Migration Safety**: The blocking issue regarding data migration safety was not exposed by the green test suite because test fixtures create fresh data using the new association flow, but it poses a strict risk to deployed environments holding existing records.