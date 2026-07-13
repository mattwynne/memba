1. **Selected todo line**
   - `022 Implement or update the @iteration-053 acceptance scenarios, removing or narrowing @todo-domain @todo-ui as behaviour becomes executable.`

2. **Changes made**
   - Updated `acceptance-tests/features/person_email_addresses.feature`:
     - Removed `@todo-domain @todo-ui` from all 9 `@iteration-053` scenarios, leaving them executable as `@iteration-053`.
   - Updated browser acceptance steps in:
     - `acceptance-tests/features/step_definitions/person_email_address_steps.js`
     - Added executable steps for:
       - opening Account settings from the avatar menu;
       - adding pending email addresses;
       - receiving/resending verification emails;
       - following verification links;
       - asserting pending/verified/primary/remove UI state;
       - making a verified alternate primary;
       - removing non-primary addresses;
       - rejecting inbound email from pending addresses.
   - Updated domain Cucumber steps in:
     - `web/test/features/step_definitions/person_email_address_steps.exs`
     - `web/test/features/step_definitions/messaging_steps.exs`
     - `web/test/features/step_definitions/authentication_steps.exs`
     - Added domain/application acceptance plumbing for the same scenarios, including sign-in-as-verification and inbound rejection.

3. **Validation commands run and results**
   - `node --check acceptance-tests/features/step_definitions/person_email_address_steps.js`
     - Passed.
   - `cd web && mix format --check-formatted test/features/step_definitions/person_email_address_steps.exs test/features/step_definitions/messaging_steps.exs test/features/step_definitions/authentication_steps.exs`
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev test test/features/domain_cucumber_acceptance_test.exs --only domain_cucumber`
     - Passed: `100 tests, 0 failures`.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed on the final worktree state.
     - Acceptance result: `118 scenarios (118 passed), 833 steps (833 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 022 Implement or update the @iteration-053 acceptance scenarios, removing or narrowing @todo-domain @todo-ui as behaviour becomes executable.`
   - To:
     - `- [x] 022 Implement or update the @iteration-053 acceptance scenarios, removing or narrowing @todo-domain @todo-ui as behaviour becomes executable.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015: browser acceptance exercises `/my/settings` as a LiveView member application surface.
   - ADR 0023: acceptance coverage uses URL-addressable `/my/settings/emails` state for email-management interactions; no client-side-only tab state was introduced.
   - Acceptance feature edits stayed within the plan’s explicitly allowed file: `acceptance-tests/features/person_email_addresses.feature`.