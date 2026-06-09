Implemented task 013.

1. **Selected todo line**
   - `- [ ] 013 Remove or narrow @todo-* tags from the planned acceptance scenarios once their runners can execute them meaningfully.`

2. **Changes made**
   - Removed `@todo-ui` from:
     - `acceptance-tests/features/homepage.feature`
     - `acceptance-tests/features/member_club_subdomains.feature`
   - Narrowed `email_branding.feature` from `@todo-domain @todo-ui` to `@todo-domain`:
     - Browser/email runner now executes these scenarios.
     - Domain runner remains excluded because email rendering/provider assertions are not currently meaningful domain-runner coverage.
   - Added executable browser acceptance plumbing:
     - New `acceptance-tests/features/step_definitions/email_branding_steps.js`
     - Added public club-page Memba-home link assertion in `member_club_subdomain_steps.js`
     - Extended auth acceptance support to capture/assert sign-in email sprig icon and standard footer.
     - Extended member-message acceptance support to assert rejection email sender name and standard footer.
   - Updated `acceptance-tests/test/cucumber_config.test.js` so `email_branding.feature` is expected in the browser-selected suite and iteration 031 scenarios are no longer blocked by `@todo-ui`.
   - Added the KMC slug setup step to the rejection email scenario so it can run independently.

3. **Focused validation run**
   - `node --check` on touched JS acceptance support/step files: passed.
   - `node --test acceptance-tests/test/cucumber_config.test.js`: passed, `5/5`.
   - `PATH="$PWD/bin:$PATH" dev acceptance --tags "@iteration-031"`: passed, `4 scenarios, 13 steps`.
   - `git diff --check`: passed.
   - Full required quality gate:
     - `PATH="$PWD/bin:$PATH" dev check`: passed, including `77 scenarios (77 passed)` in acceptance.

   Notes:
   - An initial over-broad `npm --prefix acceptance-tests run test:config` ran all JS unit tests and failed on unrelated/stale helper-test assumptions; the focused config test above passed.
   - A focused `bin/mix test web/test/features/cucumber_configuration_test.exs` hit the known Postgres socket readiness mismatch, but the full `dev check` subsequently passed.

4. **Exact todo check-off**
   - Changed only:
     - `- [ ] 013 Remove or narrow @todo-* tags from the planned acceptance scenarios once their runners can execute them meaningfully.`
   - To:
     - `- [x] 013 Remove or narrow @todo-* tags from the planned acceptance scenarios once their runners can execute them meaningfully.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read and followed:
     - `docs/adr/0003-use-cucumber-at-domain-and-application-layers.md`
     - `docs/adr/0010-use-shared-feature-files-with-elixir-cucumber.md`
   - Kept shared feature files under `acceptance-tests/features/`.
   - Added browser-runner step support without duplicating feature specs.
   - Left `@todo-domain` on email-branding scenarios because the domain runner does not yet provide meaningful email-rendering/provider coverage for those assertions.