Implemented task 017.

1. **Selected todo line**
   - `017 Update seeds, fixtures, browser acceptance support, and tests that create people to supply or derive the new email-address shape.`

2. **Changes made**
   - Updated `web/priv/repo/seeds.exs` to seed `membership_person_email_addresses` rows:
     - one primary row per seeded person;
     - Alice also has `alice@work.example` as an alternate;
     - seed output now mentions Alice’s alternate sign-in email.
   - Updated shared fixtures in `web/test/support/membership_fixtures.ex` so person fixtures either:
     - derive a one-primary `email_addresses` shape from `:email`, or
     - accept an explicit `:email_addresses` set.
   - Updated browser acceptance support:
     - `acceptance-tests/features/support/member_message.js` now creates people through `/admin/clubs/:club_id/people/new` and fills `Email address 0`.
     - Scenario person state now includes `primaryEmail`, `alternateEmails`, and `emailAddresses`, while preserving `email` as the primary alias.
     - `member_harness.js` and `authentication.js` now tolerate/derive the richer person email state.
   - Updated related JS unit tests to assert the new support behavior.
   - Updated Elixir test setup/helpers that create generic people to supply/derive `email_addresses`.
   - Preserved explicit legacy single-email tests, since backward-compatible replay remains a plan requirement.

3. **Validation run**
   - `cd web && mix format --check-formatted ...` — passed.
   - Focused Elixir tests:
     - `mix test test/memba_web/live/browser_acceptance_harness_test.exs ... test/memba/messaging/send_club_message_test.exs`
     - Result: `39 tests, 0 failures`.
   - Focused JS acceptance-support tests:
     - `node --test --test-name-pattern "withMemberHarness signs in|creating people and members" ...`
     - Result: `2 tests, 0 failures`.
   - Seed verification:
     - `MIX_ENV=test mix run priv/repo/seeds.exs` — passed.
   - Final required gate:
     - `dev check` — passed: `343 tests, 0 failures`.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 017 ...`
     - to `- [x] 017 ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR / plan conformance**
   - No explicit ADR was referenced by this plan.
   - Preserved binding plan decisions:
     - `membership_people.email` remains the denormalized primary email.
     - New setup paths use the email-address set shape with exactly one primary.
     - Legacy single-email tests remain intact for replay/backward compatibility.
     - Acceptance feature files were not edited in task 017; task 018 remains pending.