Result: **IMPLEMENTED_AND_PUBLISHED**

Plan path: `docs/iterations/028-staff-member-invitations/plan.md`

## Summary of delivered capability

Implemented staff-driven club member invitations with verified invitee-controlled profile completion:

- Staff can invite an ordinary club member by email from a club-scoped admin route.
- Invitations use separate invitation-token storage from ordinary sign-in tokens.
- Existing complete people can accept an invitation directly and become club members.
- Unknown/incomplete invitees complete their own required name before membership activation.
- Duplicate handling uses normalized email:
  - active member blocks invitation;
  - pending invitation resends;
  - existing person outside the club can be invited and reused on acceptance.
- Direct staff creation of club members from unverified name/email was decommissioned in favour of invitations.
- Acceptance tests for `club_member_invitations.feature` were implemented and todo tags narrowed/removed as planned.

## Plan conformance summary

The implementation completed all todo items in:

- `docs/iterations/028-staff-member-invitations/todo.md`

Plan conformance gate result:

- `plan_conformant: true`
- `plan_rework_available: false`

The implementation follows the resolved technical decisions in the plan:

- invitation tokens are separate from normal sign-in tokens;
- no incomplete person is created before unknown invitee profile submission;
- pending unknown invitee token is not consumed on first open;
- token is consumed only after successful profile completion or existing-person acceptance;
- existing staff onboarding remains preserved.

## Final artifact gate evidence

The final artifact gate reported:

- working tree was clean;
- comparison with `HEAD@{1}` found no differences;
- recent Fabro checkpoint commits were present;
- no acceptance `.feature` changes were detected by that gate;
- the gate itself ended with:

> `ERROR: Implementation workflow reached finalization with no artifact evidence.`

Because that gate did **not** identify a usable changed-file list, the definitive implementation artifact evidence comes from the subsequent `publish_to_main` output, which created and published the implementation commit.

## Key files changed

Source of changed-file evidence: `publish_to_main` output for commit `a8bb1b3`, summarized as:

> `50 files changed, 5045 insertions(+), 98 deletions(-)`

The publish output explicitly listed the following created files.

### Acceptance tests

- `acceptance-tests/features/step_definitions/club_member_invitation_steps.js`
- `acceptance-tests/features/support/club_member_invitations.js`

### Iteration documentation

- `docs/iterations/028-staff-member-invitations/auth-token-onboarding-inspection.md`
- `docs/iterations/028-staff-member-invitations/staff-club-person-route-inspection.md`
- `docs/iterations/028-staff-member-invitations/todo.md`

### Membership domain / application

- `web/lib/memba/membership/club_invitation.ex`
- `web/lib/memba/membership/club_member_invitation_email.ex`
- `web/lib/memba/membership/commands/accept_club_member_invitation.ex`
- `web/lib/memba/membership/commands/invite_club_member.ex`
- `web/lib/memba/membership/commands/resend_club_member_invitation.ex`
- `web/lib/memba/membership/events/club_member_invitation_accepted.ex`
- `web/lib/memba/membership/events/club_member_invitation_resent.ex`
- `web/lib/memba/membership/events/club_member_invited.ex`
- `web/lib/memba/membership/invitation_token.ex`
- `web/lib/memba/membership/projections/club_invitation.ex`
- `web/lib/memba/membership/projectors/club_invitation.ex`

### Web routes/controllers/LiveView/templates

- `web/lib/memba_web/controllers/club_member_invitation_controller.ex`
- `web/lib/memba_web/controllers/club_member_invitation_html.ex`
- `web/lib/memba_web/controllers/club_member_invitation_html/profile.html.heex`
- `web/lib/memba_web/live/admin/club_member_invitations_live/new.ex`

### Database migration

- `web/priv/repo/migrations/20260608032753_create_membership_club_invitations_projection.exs`

### Cucumber / feature step definitions

- `web/test/features/step_definitions/club_member_invitation_steps.exs`

### Domain/application tests

- `web/test/memba/membership/club_invitation_dispatch_test.exs`
- `web/test/memba/membership/club_invitation_projection_test.exs`
- `web/test/memba/membership/club_invitation_test.exs`
- `web/test/memba/membership/club_member_invitation_email_test.exs`
- `web/test/memba/membership/club_member_invitation_lifecycle_test.exs`
- `web/test/memba/membership/invitation_token_test.exs`

### Web tests

- `web/test/memba_web/controllers/club_member_invitation_controller_test.exs`
- `web/test/memba_web/live/admin/club_member_invitations_live/new_test.exs`

Note: the publish output states `50 files changed`, but only the above file paths were explicitly shown in the provided publish evidence.

## Published commit on main

Published to `main`:

- `cefa3eeeb28daf9f7383ddafce0d6cf0ab90b1cc`

Publish evidence:

> `Published implementation to main: cefa3eeeb28daf9f7383ddafce0d6cf0ab90b1cc`

The publish output also showed:

- local implementation commit before rebase/publish: `a8bb1b3`
- commit subject: `iteration 028: Staff member invitations with profile completion`
- successful rebase onto fetched `main`
- push result: `82f1eee..cefa3ee  HEAD -> main`

## Commit trailer metadata present

The provided publish output shows the published implementation commit subject and SHA, but it does **not** display commit trailers. No trailer metadata can be confirmed from the supplied evidence.

## Tests and validation run

Validation evidence includes:

### Full dev/CI check

The workflow ran:

- `PATH="$PWD/bin:$PATH" dev ci`

The `dev_check` stage succeeded.

Acceptance output from `dev ci`:

- `69 scenarios (69 passed)`
- `466 steps (466 passed)`

### Earlier implementation/validation evidence

The implementation and validation stages also reported successful runs of:

- `PATH="$PWD/bin:$PATH" dev check --quick`
  - `721 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" npm test --prefix acceptance-tests -- --dry-run`
  - `69 scenarios (69 skipped)`
  - `466 steps (466 skipped)`
- `PATH="$PWD/bin:$PATH" node --test acceptance-tests/test/cucumber_config.test.js`
  - `4 tests, 0 failures`
- `PATH="$PWD/bin:$PATH" dev acceptance features/club_member_invitations.feature`
  - `69 scenarios passed`
  - `466 steps passed`
- `PATH="$PWD/bin:$PATH" dev check`
  - `721 tests, 0 failures`
  - `69 scenarios passed`
  - `466 steps passed`

## Manual demo/checks still recommended

Recommended but non-blocking:

- Matt reviews `acceptance-tests/features/club_member_invitations.feature` for domain language, as called out in the plan validation section.
- Manually demo the happy paths:
  - Staff invite page under `/admin/clubs/:club_id/...`;
  - invitation email content and one-use link;
  - existing-person acceptance;
  - unknown invitee profile completion;
  - accepted-link reuse handling.
- Manually verify the old direct staff “create club member from name/email” path is no longer presented as a bypass.

## Non-blocking follow-ups

From the plan risks/follow-ups, still applicable:

- Membership Admins still cannot invite members; club self-service remains a future slice.
- Broader global person/email-address verification policy is outside this slice.
- Invitation links currently have no expiry by decision; revisit expiry before broader production use if risk changes.
- Pending invitation management is deferred:
  - no list;
  - no cancel;
  - no manual resend management screen.
- Future profile fields such as date of birth, emergency contact, or club-specific details need separate modelling and UX work.