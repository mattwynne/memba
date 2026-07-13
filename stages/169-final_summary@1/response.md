Result: IMPLEMENTED_AND_PUBLISHED

Plan path: `docs/iterations/053-my-settings-email-addresses/plan.md`

## Summary of delivered capability

Iteration 053 delivered member-facing self-service email address management from the global personal settings surface:

- Members can access `/my/settings` with URL-addressable Profile, Clubs, and Emails tabs.
- Members can add a new email address, which starts pending/unverified.
- Pending email addresses receive dedicated verification links backed by a scoped, hashed, one-use verification-token store.
- Verified non-primary email addresses can be made primary.
- Primary email addresses cannot be removed; non-primary addresses can be removed.
- Existing email-address rows are backfilled as verified.
- Staff email-address replacement compatibility is preserved while enforcing the new pending/verified rules for newly introduced addresses.
- Successful sign-in via a pending known Person email address verifies that address without changing primary-address/session semantics.
- Inbound member identity resolution rejects known but pending/unverified sender addresses.
- Settings LiveView refreshes via read-model/PubSub notifications after verification.

## Plan conformance summary

Plan conformance was validated successfully.

Evidence cited:

- The plan conformance gate reported:
  - `plan_conformant: true`
  - `plan_rework_available: false`
- The final artifact gate reported implementation evidence and passed:
  - `Final artifact evidence confirmed.`
  - `Final artifact gate passed.`
- The final artifact gate showed the base/head implementation diff included:
  - `56 files changed, 5612 insertions(+), 105 deletions(-)`
- Publish-to-main marked the iteration as merged and published:
  - `Marked docs/iterations/053-my-settings-email-addresses/plan.md as merged in plan and iteration index.`
  - `Published implementation to main: d866420a5282c5fb5fb23537623ffda775b60c40`

All todo items in `docs/iterations/053-my-settings-email-addresses/todo.md` were checked off, including the final `dev check` task.

## Key files changed

Grouped from the final artifact gate and publish-to-main evidence.

### Membership domain commands

- `web/lib/memba/membership/commands/add_person_email_address.ex`
- `web/lib/memba/membership/commands/make_person_email_address_primary.ex`
- `web/lib/memba/membership/commands/remove_person_email_address.ex`
- `web/lib/memba/membership/commands/verify_person_email_address.ex`

### Membership domain events

- `web/lib/memba/membership/events/person_email_address_added.ex`
- `web/lib/memba/membership/events/person_email_address_removed.ex`
- `web/lib/memba/membership/events/person_email_address_verified.ex`
- `web/lib/memba/membership/events/person_primary_email_address_changed.ex`

### Membership application/domain support

- `web/lib/memba/membership/email_address_verification_token.ex`
- `web/lib/memba/membership/person_email_address_verification_email.ex`
- `web/lib/memba/membership/projections/person_email_address.ex`
- `web/lib/memba/membership/projectors/person.ex`
- `web/lib/memba/membership/router.ex`
- `web/lib/memba/release.ex`

### Messaging / inbound identity

- `web/lib/memba/messaging/inbound_club_sender.ex`

### Web UI, routes, and controllers

- `web/lib/memba_web/components/layouts.ex`
- `web/lib/memba_web/controllers/auth_controller.ex`
- `web/lib/memba_web/controllers/person_email_address_verification_controller.ex`
- `web/lib/memba_web/controllers/person_email_address_verification_html.ex`
- `web/lib/memba_web/controllers/person_email_address_verification_html/callback.html.heex`
- `web/lib/memba_web/live/my_settings_live.ex`
- `web/lib/memba_web/router.ex`

### Database migrations

- `web/priv/repo/migrations/20260713161015_add_verified_at_to_membership_person_email_addresses.exs`
- `web/priv/repo/migrations/20260713181757_create_membership_person_email_address_verification_tokens.exs`

### Acceptance tests / step definitions

- `acceptance-tests/features/step_definitions/authentication_steps.exs`
- `acceptance-tests/features/step_definitions/messaging_steps.exs`
- `acceptance-tests/features/step_definitions/person_email_address_steps.exs`
- `acceptance-tests/features/person_email_addresses.feature`

### Domain and application tests

- `web/test/memba/membership/app_test.exs`
- `web/test/memba/membership/create_person_dispatch_test.exs`
- `web/test/memba/membership/email_address_verification_token_test.exs`
- `web/test/memba/membership/email_addresses_test.exs`
- `web/test/memba/membership/no_crud_spike_test.exs`
- `web/test/memba/membership/person_email_address_projection_test.exs`
- `web/test/memba/membership/person_email_address_verification_email_test.exs`
- `web/test/memba/membership/person_projection_test.exs`
- `web/test/memba/membership/person_test.exs`
- `web/test/memba/membership/public_api_test.exs`
- `web/test/memba/membership/query_test.exs`
- `web/test/memba/messaging/inbound_club_message_acceptance_test.exs`
- `web/test/memba/messaging/inbound_club_sender_test.exs`

### Web tests

- `web/test/memba_web/app_shell_css_test.exs`
- `web/test/memba_web/components/layouts_test.exs`
- `web/test/memba_web/controllers/auth_controller_test.exs`
- `web/test/memba_web/controllers/person_email_address_verification_controller_test.exs`
- `web/test/memba_web/live/admin_people_live_test.exs`
- `web/test/memba_web/live/my_settings_live_test.exs`
- `web/test/memba_web/router_test.exs`

### Iteration documentation / tracking

- `docs/iterations/053-my-settings-email-addresses/plan.md`
- `docs/iterations/053-my-settings-email-addresses/todo.md`

## Published commit on main

Published to `main` at:

`d866420a5282c5fb5fb23537623ffda775b60c40`

Publish evidence:

- Commit created:
  - `[fabro/run/01KXE3F0WV0J6NJX60AXBK8NZM d866420] iteration 053: My settings email-address management`
- Push result:
  - `2e15e56..d866420 HEAD -> main`
- Final publish line:
  - `Published implementation to main: d866420a5282c5fb5fb23537623ffda775b60c40`

## Commit trailer metadata present

The publish output confirms the final implementation commit exists on `main`:

- `d866420 iteration 053: My settings email-address management`

No explicit commit trailer lines were shown in the provided publish output excerpt. The run/branch metadata is present in the commit context:

- Branch/run context: `fabro/run/01KXE3F0WV0J6NJX60AXBK8NZM`
- Run ID: `01KXE3F0WV0J6NJX60AXBK8NZM`

## Tests and validation run

Validation passed.

Commands/evidence:

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed during implementation validation.
  - Acceptance suite result:
    - `118 scenarios (118 passed), 833 steps (833 passed)`
- Final pipeline validation ran:
  - `PATH="$PWD/bin:$PATH" dev ci`
  - Passed.
  - Acceptance suite result:
    - `118 scenarios (118 passed)`
    - `833 steps (833 passed)`
    - Runtime shown: `5m22.969s`

## Manual demo/checks still recommended

The plan’s manual demo remains useful as a product smoke test in a real browser/environment:

1. Sign in as an existing club member.
2. Open avatar menu and choose Account settings.
3. Add a new email address and observe pending state.
4. Confirm pending address cannot be made primary.
5. Use the verification link in a separate browser/tab.
6. Confirm the verification page says: `Email verified, you can close this browser.`
7. Confirm the original settings page updates to verified.
8. Make the verified address primary.
9. Remove the old non-primary address.
10. Confirm club-message delivery uses the new primary address.

## Non-blocking follow-ups

From the iteration plan’s risks/follow-ups:

- Staff edit behaviour for replacing full email-address sets may still deserve careful review with real staff workflows.
- Reusing sign-in links as verification should continue to be monitored for account-existence leakage or session-semantic surprises.
- The invalid/expired verification page is intentionally calm; a fuller recovery/resend path may be useful later.
- Inbound rejection from an unverified known address may confuse members; the plan notes this follow-up is captured in:
  - `docs/problems/2026-07-11-unverified-email-inbound-rejection-confusion.md`
- Shared household email addresses remain out of scope and may require revisiting the global uniqueness invariant.