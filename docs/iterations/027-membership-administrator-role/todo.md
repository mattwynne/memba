# Implementation TODO

- [x] 001 Inspect current Membership event-sourced aggregate boundaries for club creation, membership creation/removal, onboarding conversion, and test-support creation paths.
- [x] 002 Design a minimal role/permission model that supports future custom roles:
- [x] 003 Add commands/events for creating the default Membership Administrator role, granting `club.manage_members`, and assigning/removing the role from active members. Prefer events that preserve future role customisation rather than baking all logic into one opaque flag.
- [x] 004 Ensure club creation initializes the default Membership Administrator role and permission bundle. If the creator/first member is not known at `CreateClub` time, assign the role when the first member is added through onboarding conversion or an explicit assignment command.
- [x] 005 Update onboarding conversion so the requester/first member receives the Membership Administrator assignment after membership creation.
- [x] 006 Add projection tables/read models for roles, role permissions, role assignments, and/or flattened member permissions. Keep projections queryable by club and person/member.
- [ ] 007 Add a public Membership query/API for permission checks, for example “does this person have `club.manage_members` in this club?”. Exact function names are implementation details.
- [ ] 008 Add authorization handling to membership-management operations. For paths where Memba staff currently act through staff-only screens, keep staff authorization separate, but make club-member role assignment/removal commands rely on the permission model.
- [ ] 009 Add command/API support for a member with `club.manage_members` to make another active member a Membership Administrator.
- [ ] 010 Add command/API support for revoking Membership Administrator while enforcing that at least one remains.
- [ ] 011 Prevent ordinary members without `club.manage_members` from granting or revoking Membership Administrator.
- [ ] 012 Preserve or migrate existing test data/seeds so current acceptance tests still have valid clubs and memberships. Existing clubs in test/dev may need default role setup in seeds or migration/backfill.
- [ ] 013 Implement step definitions only as needed during delivery to exercise the new Cucumber scenarios through domain/application behaviour. Do not create a polished member-facing admin UI in this iteration.
- [ ] 014 Add ExUnit tests for events, projections, permission checks, authorization failures, and the last-administrator invariant.
- [ ] 015 Remove `@todo-domain`/`@todo-ui` from `club_membership_administration.feature` once implementation passes the scenarios.
- [ ] 016 Run `dev check`.
