Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `015 Build the staff forms as repeated email rows with one primary radio button. Default the first entered address as primary for the common one-email case, reject blank/malformed addresses, reject no-primary and multiple-primary submissions, and show duplicate-email errors from validation/constraints.`

2. **Changes made**
   - Added `MembaWeb.Admin.PersonEmailAddressForm` to normalize repeated email-row params, manage add/remove row state, validate:
     - name present;
     - at least one email;
     - malformed/blank emails;
     - exactly one primary;
     - duplicate emails within a submitted set;
     - duplicate emails already owned by another person.
   - Updated `MembaWeb.Admin.PeopleLive.New`:
     - repeated email rows;
     - primary radio selection;
     - first row primary by default;
     - add/remove email row buttons;
     - create submit using `Membership.create_person/2`;
     - validation and duplicate-error display.
   - Updated `MembaWeb.Admin.PeopleLive.Edit`:
     - repeated existing email rows;
     - primary radio selection;
     - add/remove email row buttons;
     - save submit using `Membership.replace_person_email_addresses/2`;
     - validation and duplicate-error display.
   - Expanded `web/test/memba_web/live/admin_people_live_test.exs` for create/edit rendering, creation with primary+alternate, malformed/no-primary/multiple-primary/duplicate validation, and replacing primary selection.

3. **Focused validation**
   - `cd web && mix format --check-formatted lib/memba_web/live/admin/person_email_address_form.ex lib/memba_web/live/admin/people_live/new.ex lib/memba_web/live/admin/people_live/edit.ex test/memba_web/live/admin_people_live_test.exs`
     - Passed.
   - Initial bare `mix test` could not connect to Postgres; repo-managed Postgres had a stale zombie lock/socket. Cleared the stale lock/socket and restarted Postgres.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/live/admin_people_live_test.exs`
     - Passed: `5 tests, 0 failures`.
   - `cd web && PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 mix test test/memba_web/live/admin/clubs_live/show_test.exs test/memba_web/live/admin_people_live_test.exs`
     - Passed: `10 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed: `343 tests, 0 failures`.
   - `git diff --check`
     - Passed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 015 Build the staff forms...`
   - To:
     - `- [x] 015 Build the staff forms...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001 / 0015: implemented the staff workflow in Phoenix LiveView.
   - ADR 0013: added user-facing Phoenix/PhoenixTest-style coverage plus LiveView-specific form assertions where needed.
   - ADR 0007: used Membership public APIs from web code; no Messaging coupling or cross-context persistence reach-through.
   - ADR 0009: continued using projection-backed reads and Commanded-backed writes through Membership.
   - ADR 0011: generated UUID person IDs before dispatch; did not use email as aggregate identity.