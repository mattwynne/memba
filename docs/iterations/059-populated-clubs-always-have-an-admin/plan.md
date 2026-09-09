# Populated clubs always have an Admin

Date: 2026-09-08
Status: implementing

## Goal

Make “a populated club always has an Admin” an aggregate-protected invariant across every ordinary membership activation and removal path.

The first person whose membership becomes active receives the club’s existing Admin role in the same atomic Commanded decision as their membership. Later members remain ordinary by default. Removing an Admin role or a whole membership cannot leave active members without an Admin, and ordinary member removal cannot return an established club to empty.

## Background / Context

Production investigation found two populated clubs with no Admin, including Nelson Community Land Trust. Their immutable event histories showed that the clubs and default Admin roles were created correctly, but the first people joined through Staff invitation acceptance rather than onboarding-request conversion. Invitation acceptance emitted the active membership without assigning the first member the Admin role. There was no later Admin removal to explain the state.

The affected production clubs were repaired separately before planning by dispatching the existing auditable `AssignMemberRole` command with strong consistency. No populated production club remained without an Admin after that repair. This iteration prevents recurrence; it does not perform or conceal another production mutation.

The implementation currently protects only one creation path: onboarding conversion dispatches `AddMember`, then separately dispatches `AssignMemberRole`. Invitation acceptance dispatches `AddMember` without that follow-up. Membership activation is owned by a membership-ID aggregate stream, while role assignment is owned by the club stream, so the two facts cannot currently be appended atomically. Two different membership streams also cannot arbitrate which concurrent activation was first.

Whole-membership removal has the same boundary problem. `RemoveMember` is decided by the membership-ID aggregate, while Admin assignments live in the Club aggregate. Direct Admin-role removal uses a projection-backed preflight count in `Memba.Membership`; whole-member removal has no equivalent last-Admin or final-member guard. Those read-model checks can race and cannot protect a write invariant.

The agreed rules from Example Mapping are:

- the first person to become an active member is Admin, regardless of invitation order or activation path;
- later members are ordinary by default;
- if two distinct invitations are accepted concurrently, both people may join but only the activation committed first receives automatic Admin authority;
- first membership and first Admin authority are indivisible;
- removing a whole membership cannot remove the sole Admin;
- an established club cannot return to empty through ordinary member removal; and
- archiving or closing a club is a separate future capability.

## Related Problems

- [`docs/problems/2026-06-17-cqrs-event-sourcing-design-drift.md`](../../problems/2026-06-17-cqrs-event-sourcing-design-drift.md): **partially addresses.** This iteration moves membership/Admin decisions from projection-backed application-service orchestration into one aggregate boundary. It does not resolve the broader application-service, invitation lifecycle, or external-side-effect concerns in that note.
- [`docs/problems/2026-06-05-approved-club-owner-cannot-add-members.md`](../../problems/2026-06-05-approved-club-owner-cannot-add-members.md): remains resolved. This iteration preserves the approved requester’s Admin authority while generalising the first-member rule to every activation path.
- [`docs/problems/2026-06-01-memba-staff-identity-and-club-access.md`](../../problems/2026-06-01-memba-staff-identity-and-club-access.md): remains unresolved and out of scope. Memba Staff do not become implicit club members or Admins.
- No captured problem note directly describes the production zero-Admin invariant failure; the incident evidence and completed repair are recorded here as planning context.

## Scope

### In scope

- Make the existing `Memba.Membership.Club` aggregate the consistency boundary for active club membership, Admin assignments, and their shared invariants.
- Route ordinary membership activation and removal commands by `club_id` to the Club aggregate instead of deciding them in independent membership-ID aggregate streams.
- Have one activation command emit the existing `MemberAdded` fact and, only when the club has no active members, the existing `MemberRoleAssigned` fact for the deterministic Admin role in one event-store append.
- Let Commanded’s club aggregate serialization and optimistic concurrency determine the first committed activation when two distinct invitees accept concurrently; both memberships succeed and exactly one automatic Admin assignment is recorded.
- Keep later membership activation ordinary by default unless a separate explicit role-assignment command grants Admin.
- Enforce the Admin floor inside the Club aggregate for both direct Admin-role removal and whole-membership removal.
- Block whole-membership removal when it would return an established club to zero active members.
- Allow removal of one Admin’s membership when another active Admin remains.
- Use existing club-stream Everyone group-membership facts as the historic compatibility source for active-roster hydration, while native Club-stream `MemberAdded` / `MemberRemoved` facts become authoritative for each membership ID as soon as either appears. A delayed Everyone event must never reactivate or remove a membership that already has a native lifecycle fact.
- Derive active Admins as the intersection of active roster memberships and active assignments of the deterministic Admin role. Historic Club role-assignment facts supply the assignment side; inactive memberships never count even when an old role assignment remains in history.
- Prove historical and mixed-stream hydration from event streams. Add a read-only release audit immediately before the existing system-group backfill; missing source facts stop the release before any compatibility command or smoke-fixture mutation and require human judgement.
- Preserve current membership, role, permission, group-membership, and member-list projections by retaining the existing domain event vocabulary.
- Update onboarding conversion and both invitation-acceptance paths to use the same aggregate-owned membership activation decision.
- Give Staff clear feedback on the existing club-detail surface when removal is blocked.
- Update event-sourced fixtures, development seeds, and smoke fixtures whose member-creation order or projection-only setup conflicts with the new invariant.

### Out of scope

- Repeating the completed production Admin repair, directly editing production projections, or introducing an automatic production-data repair.
- Bulk member import, bulk invitation ordering, or deciding which imported person becomes the initial Admin. Club imports do not exist yet.
- Club archive, closure, deletion, or any supported path for deliberately returning an established club to empty.
- Making person creation, invitation acceptance bookkeeping, onboarding request state, and club membership one cross-stream transaction. Deterministic identity recovery and idempotent continuation are in scope; transactional coordination is not.
- Invitation expiry, cancellation, resend, pending-invitation management, profile redesign, or duplicate-email concurrency beyond existing behaviour.
- A coordinator, Process Manager, saga, outbox, custom transaction layer, or multi-stream transaction machinery for this immediate invariant.
- New roles, permission primitives, custom-role management, or a broader role/permission redesign.
- Broader Staff or member authorisation changes for who may remove members.
- General cleanup of `Memba.Membership` or all CQRS/event-sourcing design drift.
- New member-management screens or a redesign of the Staff club-detail page.

## Iteration Type

Behaviour-facing invariant repair.

The stakeholder-visible rules change when the first invited member joins an empty club and when Staff attempt to remove a sole Admin or final member. The implementation is primarily a write-model boundary correction, with the existing invitation and Staff removal surfaces presenting the outcomes.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.** The change defines who receives club authority and which membership-removal actions are allowed. Those are business rules, not infrastructure details.

Update [`acceptance-tests/features/club_membership_administration.feature`](../../../acceptance-tests/features/club_membership_administration.feature):

- Rename the first rule to state that the first active member becomes Admin while retaining the converted-requester example.
- Add a first-invited-member example for an otherwise empty club.
- Add a domain-only concurrent-acceptance example in which both invitees join and exactly one becomes Admin.
- Retain the existing role-grant, unauthorised role-grant, and direct last-Admin-role-removal examples.
- Add a whole-membership-removal example where the sole Admin cannot be removed while an ordinary member remains.
- Add an example allowing one of two Admin memberships to be removed.
- Add a final-member example that keeps an established club populated.

The existing “Robin invites Dana” example in [`acceptance-tests/features/club_member_invitations.feature`](../../../acceptance-tests/features/club_member_invitations.feature) already proves that a later invitee is ordinary by default and remains an explicit regression for this iteration. It needs no semantic change.

The concurrent scenario is stakeholder-readable but tagged `@not-ui`: browser timing is not the business contract. Its real concurrency semantics belong in a focused dispatch/EventStore integration test, while aggregate decision tests prove the first-versus-later event lists without a database.

New scenarios carry `@iteration-059` plus `@todo-domain` and, where the existing UI can demonstrate the rule, `@todo-ui`. Delivery removes or narrows those runner-debt tags only as the corresponding support becomes executable.

## Allowed acceptance feature changes

- `acceptance-tests/features/club_membership_administration.feature`: add the approved first-member, concurrent-acceptance, sole-Admin-membership, replacement-Admin, and final-member examples; remove or narrow iteration-059 runner-debt tags as they become executable.

Existing invitation, request-account, member-list, and membership-administration scenarios remain regression coverage. Do not rewrite their business meaning unless implementation exposes a direct contradiction with this plan.

## Designs

No design needed. This iteration adds no page, component, layout, or new action. It reuses the existing invitation journeys and Staff club-member removal surface. Only concise blocked-removal feedback changes.

## Acceptance Criteria

- A club may exist initially with zero active members while invitations or onboarding are pending.
- The first person whose membership becomes active receives the deterministic Admin role in the same Club-aggregate decision and atomic event append as `MemberAdded`.
- The first-member rule applies to onboarding-request conversion, invitation acceptance for an existing person, and invitation profile completion for a new person.
- A later active member receives no Admin role unless an authorised person grants it explicitly.
- If two distinct invitations for an empty club are accepted concurrently, both calls succeed, both memberships become active, and exactly one automatic Admin assignment exists: the one associated with the activation committed first in the Club stream.
- No public or registered command path can activate or remove a membership through the old membership-ID write boundary and bypass the Club invariant.
- Re-dispatching the same active `club_id` / `membership_id` / `person_id` activation is an idempotent success. A different membership ID for a person who is already active is rejected. A removed membership ID is never reused; a returning person receives a new membership ID.
- Direct removal of the sole Admin role remains blocked by the Club aggregate.
- Whole-membership removal is blocked when the target is the sole active Admin, even if ordinary active members remain.
- Whole-membership removal is allowed when another active Admin remains.
- Whole-membership removal is blocked when the target is the club’s final active member.
- When both protections could apply, final-member feedback takes precedence: Staff are told that an established club must retain an active member. When other members remain but the target is the sole Admin, Staff are told to make another member an Admin first.
- Rejected removal emits no membership, role, permission, or group-membership change and the member remains visible with the same authority.
- Successful removal continues to deactivate the membership, role assignments, effective permissions, Everyone/Admin group memberships, and member-list presence through existing event consumers.
- Aggregate decisions use rehydrated event-stream state, not membership or role-assignment projections, to decide first member, duplicate active membership, sole Admin, or final member.
- Historic Club streams containing iteration-056 Everyone group-membership facts and existing role facts rehydrate an accurate active roster and Admin set without rewriting history.
- In mixed streams, native Club `MemberAdded` / `MemberRemoved` lifecycle facts take permanent precedence for that membership ID over later Everyone compatibility events. In particular, `MemberAdded(A)`, `MemberAdded(B)`, `MemberRemoved(A)`, then a delayed Everyone `GroupMemberAdded(A)` leaves A inactive.
- Active Admin state is exactly active roster membership IDs intersected with active assignments of the deterministic Admin role; an inactive member’s retained historic role assignment never counts toward the Admin floor.
- `Memba.Membership.AdminInvariant.Audit.run!/0` read-only checks every projected active membership has either a native Club membership lifecycle or the required historical Everyone fact, and every projected active Admin assignment has its Club role fact. `Memba.Release.migrate/0` runs it after source-projector barriers but before `run_system_groups_backfill` and production smoke fixtures. Missing facts fail the release before those event-store mutations.
- Existing onboarding conversion still creates a club, person when necessary, active membership, Admin authority, converted request state, and welcome email.
- Existing accepted-invitation idempotency, sign-in, profile completion, duplicate-membership protection, and later-member ordinary status continue to work.
- Invitation acceptance recovers partial progress deterministically: it reuses the one person found by the normalized invited email and the one matching active club membership when present; otherwise candidate person/membership IDs are deterministically derived from the invitation ID. Retrying after person creation or membership activation yields one person, one active membership, one accepted invitation, and no duplicate Admin assignment.
- Existing Admin permissions and system Admin-group membership continue to derive from the Admin role assignment.
- The new Cucumber examples pass after their runner-debt tags are removed or narrowed.
- `dev check` passes on the delivered implementation.

## Open Business Decisions

None known.

Confirmed decisions:

- “First” means the activation committed while the Club aggregate has zero active members; invitation creation order does not decide authority.
- Concurrent acceptance concerns two distinct people and invitations. Same-person duplicate acceptance remains existing idempotency behaviour.
- Membership activation and initial Admin authority are indivisible; invitation and person records are not included in that atomicity claim.
- A populated club always retains an Admin.
- An established club cannot return to empty through ordinary member removal.
- Final-member feedback takes precedence when the target is both the final active member and the sole Admin.
- Archiving or closing a club is the future path for ending an established club.

## Implementation Plan

1. Add the approved iteration-059 examples to `club_membership_administration.feature`. Confirm the planning tags exclude unfinished steps from the default runners, and keep the existing later-invitee ordinary example as regression coverage.
2. Characterise the current write boundaries and legacy event shape with focused tests before moving commands:
   - replay representative pre-iteration Club streams containing Everyone `GroupMemberAdded` / `GroupMemberRemoved` and role-assignment facts;
   - prove the reconstructed active membership and active-Admin state needed for decisions;
   - replay mixed streams where native member lifecycle facts are followed by delayed Everyone events and prove the native lifecycle remains authoritative;
   - implement `Memba.Membership.AdminInvariant.Audit.run!/0` as a read-only comparison of current Membership/RoleAssignment projections with the required Club-stream native-or-compatibility facts;
   - add `:audit_admin_invariant_compatibility` to `Memba.Release.migrate/0` after source-projector barriers and immediately before `:run_system_groups_backfill`, with a failing audit preventing the backfill and smoke-fixture steps;
   - stop and seek human judgement if the prerequisite is false.
3. Extend `Memba.Membership.Club` state and event application so it owns active membership identities alongside its existing role assignments. Track a permanent native-lifecycle marker per membership ID. Everyone group add/remove events hydrate roster state only while that membership has no native marker; applying either native `MemberAdded` or `MemberRemoved` sets the marker and becomes authoritative for all later decisions. Derive active Admins by intersecting active roster IDs with active deterministic-Admin role assignments. Keep compatibility logic explicit and covered rather than querying projections during command execution.
4. Extend `AddMember` and `RemoveMember` command data as needed with `club_id`, `membership_id`, and `person_id`, validate those identities against Club state, and route both commands to the Club aggregate by `club_id`. De-register the old membership-ID write route so no caller can bypass the invariant. Historic membership streams remain immutable; remove the old aggregate module if it has no replay-only caller, otherwise mark it legacy/unregistered and create a named follow-up for deletion rather than leaving a second write model ambiguous.
5. Make Club’s `AddMember` decision treat an exact already-active `club_id` / `membership_id` / `person_id` match as an idempotent no-op, reject a different active membership for the same person, and reject reuse of a removed membership ID. For a new activation, emit `MemberAdded`; if the rehydrated club has no active members, return it followed by the deterministic Admin `MemberRoleAssigned` event from the same command execution so Commanded appends them atomically. Later additions emit only `MemberAdded` unless an explicit role command follows.
6. Move both removal rules into Club aggregate decisions:
   - `RemoveMemberRole` rejects removing the final active Admin assignment;
   - `RemoveMember` first rejects removal of the final active member, then rejects removal of the sole Admin while others remain;
   - removal succeeds when at least one active member and one active Admin remain afterward.
   Apply `MemberRemoved` by removing the membership from the aggregate’s active roster and active role-assignment set so subsequent commands see the new state.
7. Thin `Memba.Membership` public write APIs around those aggregate decisions. Projection lookups may resolve a membership ID into routing/identity data, but may not decide first-member, duplicate-member, Admin-count, or final-member rules. Remove the projection-backed last-Admin preflight and preserve public return shapes where practical.
8. Update onboarding conversion to stop dispatching a separate Admin assignment after membership activation. Update existing-person and new-person invitation acceptance to use the same Club-routed activation. Make invitation retries deterministic without a coordinator:
   - when no matching records exist, derive the unknown invitee’s candidate person ID and every invitation membership ID from the invitation ID using namespaced `Memba.ID.deterministic/2` values (preserve an explicitly supplied ID only when the caller reuses it);
   - before dispatch, resolve the normalized invited email to zero or one person, then resolve that person and club to zero or one active membership; reuse matching existing identities and reject ambiguous/mismatched identities;
   - normalize exact same-ID `CreatePerson` and `AddMember` no-ops as successful continuation, but never treat a different person/email or membership/person combination as idempotent;
   - use strong projection consistency/barriers before recovery queries when a prior dispatch may have committed but its caller did not receive the result;
   - accept the invitation with the recovered actual person and membership IDs.
   Add failure-injection tests after person creation and after membership activation but before invitation acceptance, for both existing-person and profile-completion paths. Each retry must finish with one person, one active membership, one accepted invitation, and one automatic Admin at most.
9. Preserve the existing membership/role projectors and `SystemGroupMembership` event handler by retaining `MemberAdded`, `MemberRemoved`, `MemberRoleAssigned`, and `MemberRoleRemoved`. Verify one atomic activation append still results, under strong consistency, in queryable membership, permission, Everyone membership, and Admin-group membership; do not move the invariant into that handler.
10. Update the existing Staff club-detail removal action to present the two confirmed rejection reasons clearly without redesigning the page. Add LiveView tests showing a blocked removal remains on the member list with no success message, and a permitted removal still follows the existing success path.
11. Repair affected tests, development seeds, and smoke fixtures so clubs used for command dispatch have real event-sourced Club streams and deterministic first-member ordering. Do not preserve projection-only write fixtures or explicit post-add first-Admin assignments that contradict the new write boundary.
12. Add focused validation:
    - pure Club aggregate tests in `web/test/memba/membership/club_test.exs` for first and later additions, exact activation idempotency, different-ID duplicate rejection, removed-ID non-reuse, direct sole-Admin role removal, sole-Admin whole-membership removal, final-member removal, and permitted removal with a replacement Admin;
    - one thin dispatch/EventStore contract test proving `MemberAdded` and first `MemberRoleAssigned` are recorded on the same Club stream by one command;
    - a concurrent application/invitation test dispatching two distinct acceptances and proving both succeed with two active memberships and one automatic Admin;
    - historical stream replay, projection parity, system-group policy, onboarding, both invitation paths, Staff LiveView, member-list, messaging-recipient, seeds, and smoke-fixture regressions;
    - both affected Cucumber runners after implementing the new step support.
13. Remove or narrow iteration-059 runner-debt tags only when their scenarios execute, then run `dev check` on the exact delivered state.

## Technical Decisions

- **Consistency boundary:** the existing Club aggregate owns active roster decisions because it already owns Admin roles and assignments. Aggregate boundaries follow the immediate invariant, not the old membership-ID stream partition.
- **Atomicity:** one Club-routed activation command may return both `MemberAdded` and `MemberRoleAssigned`; Commanded appends that event list atomically to one club stream. The claim deliberately excludes person creation, onboarding-request state, invitation state, email, and projections.
- **Concurrency:** all membership additions for one club use the same aggregate identity. Commanded aggregate serialization and optimistic concurrency order competing decisions; after the first append, the second decision rehydrates/sees a populated club and emits no automatic Admin assignment. No custom lock or retry coordinator is introduced.
- **Historical compatibility and precedence:** iteration 056 appended deterministic Everyone group-membership facts to Club streams for existing data. Those facts drive roster state only for membership IDs with no native Club membership lifecycle. The first native `MemberAdded` or `MemberRemoved` permanently marks that membership ID native; every later Everyone compatibility event still updates group state but cannot change roster state. Active Admins are active roster IDs intersected with active deterministic-Admin role assignments from Club role events.
- **Invitation retry identity:** invitation IDs are the stable recovery key. Namespaced deterministic person/membership IDs are used when records do not yet exist; matching person-by-invited-email and active-membership-by-club/person queries recover committed partial progress. Exact matching command no-ops are success, while mismatched or ambiguous identities fail closed. This is idempotent application-service continuation, not a transaction coordinator.
- **Release audit ordering:** `Memba.Membership.AdminInvariant.Audit.run!/0` is a read-only release step after projection barriers and before the existing mutating system-group backfill. Audit failure raises, preventing both that backfill and production smoke-fixture mutation until a human explicitly approves any repair.
- **Events and projections:** retain existing membership and role event types so current projectors and policies continue to build read models regardless of the stream that owns new events. Historic membership streams remain immutable.
- **Error precedence:** reject final-member removal before sole-Admin removal. This keeps the two agreed rules visible and gives Staff the most specific recovery guidance.
- **Infrastructure coverage:** aggregate tests carry the business proof. Add at most one thin EventStore contract test for same-stream append and one concurrency integration example; do not repeat transactional failure cases in stakeholder Gherkin.

## New Capability

Every ordinary path into or out of a club preserves a viable membership administration structure. The first active person can administer the club immediately, concurrent first joins cannot create zero or two automatic Admins, and Staff cannot remove the authority or final member needed to keep an established club alive.

## Validation Plan

- Validate the new Gherkin with the repository’s feature parser and tag-configuration checks before implementing step support.
- Run pure aggregate tests without a database to prove the event lists and rejection decisions for all first/later/add/remove examples.
- Replay representative historical and mixed Club streams and compare aggregate decision state with current active membership and Admin projections. Include `MemberAdded(A)`, `MemberAdded(B)`, `MemberRemoved(A)`, then delayed Everyone `GroupMemberAdded(A)` and prove A remains inactive and cannot count as an Admin.
- Test `Memba.Membership.AdminInvariant.Audit.run!/0` against complete and deliberately incomplete facts. Test release-step ordering and prove an audit failure prevents `run_system_groups_backfill` and production smoke fixtures. Treat a production audit failure as a blocker requiring explicit human judgement.
- Inspect the persisted Club stream in one focused integration test to confirm first membership and Admin assignment came from one dispatch and share one aggregate stream.
- Exercise two distinct invitation acceptances concurrently through the application boundary and await strong projections before asserting both memberships and exactly one Admin.
- Inject failures after person creation and after membership activation but before invitation acceptance; retry both invitation paths and prove stable identities, one person, one active membership, one accepted invitation, and no duplicate Admin.
- Run focused tests for Membership public APIs, Club aggregate dispatch, membership and role projections, system groups, onboarding conversion, existing/new-person invitation acceptance, accepted-link retry, Staff removal LiveView, member presentation, messaging recipients, seeds, and production smoke fixtures.
- Exercise the accepted non-concurrent examples through both domain and browser Cucumber runners; run the concurrency example through the domain runner only.
- Manually demo an empty Staff-created club: accept the first invitation, confirm Admin/member badge and invitation authority, add a later ordinary member, observe blocked sole-Admin removal, grant a replacement Admin, remove the original Admin, and observe blocked final-member removal on a one-member fixture.
- Run `dev check` on the committed delivery candidate.

## Risks / Follow-ups

- Moving add/remove commands to the Club stream will invalidate projection-only tests and fixtures that never created an event-sourced club. Fix the fixtures rather than adding a fallback write path.
- Existing tests and seeds may assume the first generic `add_member` call creates an ordinary member. Their setup order must make intended authority explicit.
- Historical roster hydration depends on iteration-056 Everyone facts being complete wherever no native Club membership lifecycle exists. The audit/replay gate runs before the existing backfill, must fail visibly, and must not trigger an automatic production mutation.
- Leaving onboarding’s explicit role assignment in place would turn a successful atomic activation into a misleading duplicate-assignment failure. Remove that follow-up and protect its retry paths.
- Club streams will receive more membership lifecycle events and become a stronger serialization point. That contention is intentional for this immediate invariant and appropriate for current club sizes; monitor before optimizing.
- The system-group handler remains downstream of the atomic domain decision. Admin authority comes from the role event in the append, not from eventual Admin-group projection timing.
- Invitation/person bookkeeping can still fail before or after the Club append. This iteration preserves and tests idempotent recovery but does not claim cross-aggregate transactionality.
- Follow-up: design the explicit archive/close behaviour that may end an established club and define what happens to its remaining member, roles, groups, conversations, and email routes.
- Follow-up: define first-Admin behaviour if a future bulk-import capability can create several memberships as one operation.
