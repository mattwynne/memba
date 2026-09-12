# Populated clubs always have an Admin

Date: 2026-09-08
Status: merged

## Goal

Make “a populated club always has an Admin” an aggregate-protected invariant across every ordinary membership activation and removal path.

The first person whose membership becomes active receives the club’s existing Admin role in the same atomic Commanded decision as their membership. Later members remain ordinary by default. Removing an Admin role or a whole membership cannot leave active members without an Admin, and ordinary member removal cannot return an established club to empty.

## Background / Context

Production investigation found two populated clubs with no Admin, including Nelson Community Land Trust. Their immutable event histories showed that the clubs and default Admin roles were created correctly, but the first people joined through Staff invitation acceptance rather than onboarding-request conversion. Invitation acceptance emitted the active membership without assigning the first member the Admin role. There was no later Admin removal to explain the state.

The affected production clubs were repaired separately before planning by dispatching the then-existing auditable `AssignMemberRole` command with strong consistency. No populated production club remained without an Admin after that repair. This iteration prevents recurrence; it does not perform or conceal another production mutation.

Before this iteration, only onboarding conversion protected one creation path: it dispatched `AddMember`, then separately dispatched `AssignMemberRole`. Invitation acceptance dispatched `AddMember` without that follow-up. Membership activation was owned by a membership-ID aggregate stream, while role assignment was owned by the Club stream, so the two facts could not be appended atomically. Two different membership streams also could not arbitrate which concurrent activation was first.

Whole-membership removal had the same boundary problem. `RemoveMember` was decided by the membership-ID aggregate, while Admin assignments lived in the Club aggregate. Direct Admin-role removal used a projection-backed preflight count in `Memba.Membership`; whole-member removal had no equivalent last-Admin or final-member guard. Those read-model checks could race and could not protect a write invariant.

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
- Have one `AddClubMember` command emit the new `ClubMemberAdded` fact and, only when the club has no active members, the new `ClubRoleAssignedToMember` fact for the deterministic Admin role in one event-store append.
- Let Commanded’s club aggregate serialization and optimistic concurrency determine the first committed activation when two distinct invitees accept concurrently; both memberships succeed and exactly one automatic Admin assignment is recorded.
- Keep later membership activation ordinary by default unless a separate explicit role-assignment command grants Admin.
- Enforce the Admin floor inside the Club aggregate for both direct Admin-role removal and whole-membership removal.
- Block whole-membership removal when it would return an established club to zero active members.
- Allow removal of one Admin’s membership when another active Admin remains.
- Use existing club-stream Everyone group-membership facts as the historic compatibility source for active-club-membership hydration, while native Club-stream `ClubMemberAdded` / `ClubMemberRemoved` facts become authoritative for each membership ID as soon as either appears. A delayed Everyone event must never reactivate or remove a membership that already has a native lifecycle fact.
- Derive active Admins as the intersection of active club membership IDs and active assignments of the deterministic Admin role. Historic Club role-assignment facts supply the assignment side; inactive memberships never count even when an old role assignment remains in history.
- Reject assigning any role to an inactive membership inside the Club aggregate, preserving the existing application-level behaviour at the write boundary.
- Prove historical and mixed-stream hydration from event streams. Document and run a one-time read-only production cutover check immediately before the first iteration-059 deployment and verify again afterward; missing compatibility facts or a populated zero-Admin club block that deployment for human judgement.
- Preserve current membership, role, permission, group-membership, and member-list projections by teaching their consumers to handle both the historic and explicit new domain-event vocabulary.
- Update onboarding conversion and both invitation-acceptance paths to use the same aggregate-owned membership activation decision.
- Give Staff clear feedback on the existing club-detail surface when removal is blocked.
- Update event-sourced fixtures, development seeds, and smoke fixtures whose member-creation order or projection-only setup conflicts with the new invariant.

### Out of scope

- Repeating the completed production Admin repair, directly editing production projections, introducing an automatic production-data repair, or adding a permanent invariant check to every release.
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
- The first person whose membership becomes active receives the deterministic Admin role in the same Club-aggregate decision and atomic event append as `ClubMemberAdded`.
- The first-member rule applies to onboarding-request conversion, invitation acceptance for an existing person, and invitation profile completion for a new person.
- A later active member receives no Admin role unless an authorised person grants it explicitly.
- If two distinct invitations for an empty club are accepted concurrently, both calls succeed, both memberships become active, and exactly one automatic Admin assignment exists: the one associated with the activation committed first in the Club stream.
- No public or registered command path can activate or remove a membership through the old membership-ID write boundary and bypass the Club invariant.
- Re-dispatching the same active `club_id` / `membership_id` / `person_id` activation is an idempotent success. A different membership ID for a person who is already active is rejected.
- A membership ID recorded in the Club aggregate’s native or compatibility history is not reused after removal, and a returning person receives a newly generated membership ID. No all-history guarantee or tombstone backfill is required for pre-cutover inactive IDs absent from Club streams; production entry points generate deterministic or fresh opaque typed IDs rather than accepting operator-chosen identities.
- Assigning any role to an inactive membership is rejected by the Club aggregate.
- Direct removal of the sole Admin role remains blocked by the Club aggregate.
- Whole-membership removal is blocked when the target is the sole active Admin, even if ordinary active members remain.
- Whole-membership removal is allowed when another active Admin remains.
- Whole-membership removal is blocked when the target is the club’s final active member.
- When both protections could apply, final-member feedback takes precedence: Staff are told that an established club must retain an active member. When other members remain but the target is the sole Admin, Staff are told to make another member an Admin first.
- Rejected removal emits no membership, role, permission, or group-membership change and the member remains visible with the same authority.
- Successful removal continues to deactivate the membership, role assignments, effective permissions, Everyone/Admin group memberships, and member-list presence through existing event consumers.
- Aggregate decisions use rehydrated event-stream state, not membership or role-assignment projections, to decide first member, duplicate active membership, sole Admin, or final member.
- Historic Club streams containing iteration-056 Everyone group-membership facts and existing role facts rehydrate accurate active club membership and Admin state without rewriting history.
- In mixed streams, native Club `ClubMemberAdded` / `ClubMemberRemoved` lifecycle facts take permanent precedence for that membership ID over later Everyone compatibility events. In particular, `ClubMemberAdded(A)`, `ClubMemberAdded(B)`, `ClubMemberRemoved(A)`, then a delayed Everyone `GroupMemberAdded(A)` leaves A inactive.
- Active Admin state is exactly active club membership IDs intersected with active assignments of the deterministic Admin role; an inactive member’s retained historic role assignment never counts toward the Admin floor.
- `docs/iterations/059-populated-clubs-always-have-an-admin/cutover-check.md` gives exact read-only commands and expected zero-violation results for two checks: every projected active membership has a native Club lifecycle or historical Everyone fact, and every populated club has an active deterministic Admin assignment backed by a Club role fact. Run it immediately before the first production deployment and again afterward. Any violation blocks or rolls back that cutover for human judgement; it is not wired into every future release.
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

1. Implement the existing iteration-059 Gherkin steps and confirm unfinished steps remain excluded until executable. Keep the later-invitee ordinary example as regression coverage.
2. Add Club replay tests for historic Everyone membership and role facts, active-Admin reconstruction, and delayed compatibility events after native membership events.
3. Write `cutover-check.md` with exact one-time read-only production checks for source-fact compatibility and populated clubs without an active Admin, including pre/post-deploy expectations and stop instructions.
4. Extend Club aggregate state with active club memberships, permanent native-lifecycle markers, and active Admins derived by intersecting active club membership IDs with active Admin-role assignments.
5. Apply historic Everyone events only where no native marker exists. Make native `ClubMemberAdded` or `ClubMemberRemoved` permanently authoritative for that membership while preserving ordinary group state.
6. Add club/person identity to member commands, validate it against Club state, route add/remove by `club_id`, and de-register the membership-ID write route.
7. Remove the legacy Membership aggregate if unused; otherwise mark it unregistered legacy replay code and create a named deletion follow-up. Never expose a second write path.
8. Make activation idempotent for an exact active identity and reject another active membership for the same person. Reject removed IDs known to Club without importing absent pre-cutover tombstones.
9. Emit `ClubMemberAdded` plus the Admin `ClubRoleAssignedToMember` event for the first activation in one decision. Emit only `ClubMemberAdded` for later members.
10. Reject role assignment to an inactive membership inside Club and enforce the active-Admin floor when handling direct `RemoveClubRoleFromMember`.
11. Enforce final-member precedence and sole-Admin protection in Club’s `RemoveClubMember`; apply success to both active club memberships and active-Admin decision state.
12. Thin `Memba.Membership` write APIs around Club decisions. Projection lookups may enrich routing identity but must not decide duplicate, first-member, Admin-floor, or member-floor rules.
13. Route onboarding conversion through Club activation and remove its separate Admin assignment. Route both invitation-acceptance paths through the same activation command.
14. Derive new invitation person/membership candidates from the invitation ID with namespaced `Memba.ID.deterministic/2`; require explicit caller IDs to be reused.
15. Recover zero-or-one person by invited email and zero-or-one active membership by club/person. Reuse matches and fail closed on ambiguous or mismatched identities.
16. Treat exact same-ID person/member creation as successful retry continuation and use strong projections or a barrier before recovery queries after uncertain dispatch results.
17. Accept the invitation with recovered identities and preserve its result contract. Add failure-injection retry tests after person creation and membership activation for both paths.
18. Retain existing member/role events, projectors, and `SystemGroupMembership`; prove one activation yields queryable membership, permission, Everyone, and Admin-group state.
19. Present the two confirmed removal errors on the existing Staff club page. Test blocked members remain visible and permitted removal retains its success path.
20. Repair affected tests, development seeds, and smoke fixtures to use event-sourced clubs and deterministic first-member ordering, without projection-only write fixtures.
21. Add pure Club tests for first/later activation, idempotency, duplicate and Club-known removed IDs, inactive-member role assignment, both removal floors, and replacement Admin removal.
22. Add one same-stream append contract test and one concurrent two-invitation test proving both memberships succeed with exactly one automatic Admin.
23. Run replay, projection, system-group, onboarding, invitation, Staff UI, member-list, messaging, seed, smoke, and Cucumber regressions. Remove runner-debt tags and run `dev check`.

## Technical Decisions

- **Consistency boundary:** the existing Club aggregate owns active club membership decisions because it already owns Admin roles and assignments. Aggregate boundaries follow the immediate invariant, not the old membership-ID stream partition.
- **Atomicity:** one Club-routed activation command may return both `ClubMemberAdded` and `ClubRoleAssignedToMember`; Commanded appends that event list atomically to one club stream. The claim deliberately excludes person creation, onboarding-request state, invitation state, email, and projections.
- **Concurrency:** all membership additions for one club use the same aggregate identity. Commanded aggregate serialization and optimistic concurrency order competing decisions; after the first append, the second decision rehydrates/sees a populated club and emits no automatic Admin assignment. No custom lock or retry coordinator is introduced.
- **Historical compatibility and precedence:** iteration 056 appended deterministic Everyone group-membership facts to Club streams for existing data. Those facts drive active club membership state only for membership IDs with no native Club membership lifecycle. The first native `ClubMemberAdded` or `ClubMemberRemoved` permanently marks that membership ID native; every later Everyone compatibility event still updates group state but cannot change active club membership state. Active Admins are active club membership IDs intersected with active deterministic-Admin role assignments from Club role events.
- **Invitation retry identity:** invitation IDs are the stable recovery key. Namespaced deterministic person/membership IDs are used when records do not yet exist; matching person-by-invited-email and active-membership-by-club/person queries recover committed partial progress. Exact matching command no-ops are success, while mismatched or ambiguous identities fail closed. This is idempotent application-service continuation, not a transaction coordinator.
- **Proportionate cutover check:** this iteration adds no permanent release gate. A documented one-time read-only check runs immediately before the first iteration-059 production deployment and again afterward. It verifies both current zero-Admin state and compatibility facts; any violation pauses that cutover for human-approved repair.
- **Membership identity scope:** Club rejects IDs present in its rehydrated lifecycle and production paths generate deterministic or fresh opaque IDs. Pre-cutover inactive IDs absent from Club streams are not imported solely to defend against a speculative opaque-ID collision.
- **Inactive role assignments:** Club rejects assigning any role to an inactive membership. This existing application rule belongs beside the Admin-floor decision in the aggregate.
- **Events and projections:** retain existing membership and role event types so current projectors and policies continue to build read models regardless of the stream that owns new events. Historic membership streams remain immutable.
- **Error precedence:** reject final-member removal before sole-Admin removal. This keeps the two agreed rules visible and gives Staff the most specific recovery guidance.
- **Infrastructure coverage:** aggregate tests carry the business proof. Add at most one thin EventStore contract test for same-stream append and one concurrency integration example; do not repeat transactional failure cases in stakeholder Gherkin.

## New Capability

Every ordinary path into or out of a club preserves a viable membership administration structure. The first active person can administer the club immediately, concurrent first joins cannot create zero or two automatic Admins, and Staff cannot remove the authority or final member needed to keep an established club alive.

## Validation Plan

- Validate the new Gherkin with the repository’s feature parser and tag-configuration checks before implementing step support.
- Run pure aggregate tests without a database to prove the event lists and rejection decisions for all first/later/add/remove examples.
- Replay representative historical and mixed Club streams and compare aggregate decision state with current active membership and Admin projections. Include `ClubMemberAdded(A)`, `ClubMemberAdded(B)`, `ClubMemberRemoved(A)`, then delayed Everyone `GroupMemberAdded(A)` and prove A remains inactive and cannot count as an Admin.
- Review `cutover-check.md` against complete and deliberately incomplete examples. Immediately before the first production deployment, run its read-only current-invariant and compatibility checks; pause for human judgement on any violation, then repeat the checks after deployment.
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
- Historical active club membership hydration depends on iteration-056 Everyone facts being complete wherever no native Club membership lifecycle exists. The one-time cutover check must fail visibly and must not trigger an automatic production mutation; a permanent deployment gate would add disproportionate release coupling after the aggregate owns the invariant.
- Leaving onboarding’s explicit role assignment in place would turn a successful atomic activation into a misleading duplicate-assignment failure. Remove that follow-up and protect its retry paths.
- Club streams will receive more membership lifecycle events and become a stronger serialization point. That contention is intentional for this immediate invariant and appropriate for current club sizes; monitor before optimizing.
- The system-group handler remains downstream of the atomic domain decision. Admin authority comes from the role event in the append, not from eventual Admin-group projection timing.
- Invitation/person bookkeeping can still fail before or after the Club append. This iteration preserves and tests idempotent recovery but does not claim cross-aggregate transactionality.
- Follow-up: design the explicit archive/close behaviour that may end an established club and define what happens to its remaining member, roles, groups, conversations, and email routes.
- Follow-up: define first-Admin behaviour if a future bulk-import capability can create several memberships as one operation.
