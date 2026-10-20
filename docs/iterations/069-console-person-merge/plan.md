# Merge uncomplicated duplicate people from the console

Date: 2026-10-13
Status: merged

Delivered in `5645fb62d50892b763f419f4b08e5d22b9a0e4bd` and deployed on
2026-10-13. Originally numbered 070; renumbered to 069 after delivery so the
pending profile-photo iteration is 070.

## Goal

Memba staff can merge an uncomplicated duplicate Person into a surviving Person from a Phoenix or
release console, without rewriting historical messages or event data.

## Related problems

- [Staff need to be able to merge people](../../problems/2026-06-06-staff-merge-people.md) is
  partially addressed by this deliberately narrow first slice.
- [People cannot ask Memba to erase personal data](../../problems/2026-10-13-personal-data-erasure-missing.md)
  remains unresolved. Merge is identity consolidation, not regulatory erasure.

## Scope

In scope:

- A dry-run preview and idempotent application workflow callable from a console.
- Moving every verified source email address to the target while retaining the target primary.
- Ending source memberships only where the target is already active in the same club.
- Marking the source as merged, hiding it from ordinary staff people listings, and preventing its
  email-address commands.
- Preserving source IDs in historical messages, invitations, onboarding, and membership events.
- Replay-safe source and target Person projections.

Out of scope:

- A web UI.
- A privacy-erasure workflow.
- Transferring a membership into a club the target has not joined.
- Transferring roles or custom-group participation. A merge requiring either is rejected before
  any change.
- Rewriting historical sender, invitation, onboarding, delivery, or event identities.

## BDD examples

Focused domain examples live in
[`acceptance-tests/features/person_merge.feature`](../../../acceptance-tests/features/person_merge.feature):

- verified addresses identify the surviving Person after merge;
- an overlapping ordinary club membership collapses to the target membership;
- a unique source membership is rejected without changing either Person.

There is no browser journey because the capability is console-only.

## Technical model

`Memba.Membership.PersonMerge.preview/2` builds a complete plan from the strongly consistent
Membership projections. Version one accepts only existing, distinct, unmerged people; verified
source addresses; overlapping active club memberships; and no active source role or custom-group
assignments.

`merge/2` executes the previewed removal commands with strong consistency, then dispatches one
`MergePerson` command to the target Person aggregate. `PersonMerged` contains the source and target
identities plus the complete resulting verified email-address set. Keeping that state in the target
stream means later email changes and projection replay cannot forget transferred addresses.

The Person projector handles `PersonMerged` atomically: mark the source as merged, remove its email
rows, replace the target email rows, and preserve the target's primary address. The source Person row
remains for historical attribution but has no sign-in address or active membership. Repeating the
same merge is successful without new events; attempting to merge the source elsewhere is rejected.

## Console contract

```elixir
source_person_id = "per_..."
target_person_id = "per_..."

Memba.Membership.PersonMerge.preview(source_person_id, target_person_id)
Memba.Membership.PersonMerge.merge(source_person_id, target_person_id)
```

Both calls return a receipt containing the affected memberships and resulting email addresses.
Production use must preview exact IDs immediately before applying and verify both IDs and all email
lookups afterwards.

## Validation

- Focused Cucumber domain examples.
- Aggregate and command dispatch tests for validation, exact verification state, and idempotency.
- Workflow tests for the happy path and rejected unique membership/role/custom-group cases.
- Projection and replay tests for the merged marker, email ownership, staff listing, and historical
  source row.
- Full `dev check` on the final worktree.
