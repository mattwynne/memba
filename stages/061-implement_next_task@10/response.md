Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `010 Update acceptance step support only as needed for the new send-failure scenario and for existing normal-send steps to use the new compose flow without changing scenario wording.`

2. **Changes made**
   - Updated browser acceptance support to use the new member compose LiveView flow:
     - opens compose from the club-home CTA;
     - fills `Subject` / `Message`;
     - submits with `Send to all members`;
     - reads the success state’s `data-sent-message-id`;
     - returns to club home and waits for the message row.
   - Added browser step support for the new failure scenario:
     - `Given club message sending is unavailable`;
     - `When Alice tries to send...`;
     - failure copy assertions for “message was not sent” and “contact support”.
   - Added a dev/test-only support endpoint:
     - `POST /dev/test-support/messaging-delivery-provider`
     - switches the test delivery provider between `local`, `fake`, and `unavailable`.
   - Added cleanup so browser acceptance scenarios restore normal local sending after a failure simulation.
   - Added matching Elixir Cucumber step support so the shared feature file remains executable when `@wip` is removed later.
   - Added/updated support tests for:
     - compose-based member sending helper;
     - failed-send helper and support copy;
     - dev test support provider switching endpoint.

3. **Validation run**
   - `cd acceptance-tests && npm_config_cache=../.fabro/tmp/npm-cache npm ci`
     - passed after the initial missing-node-dependency run failed.
   - `cd acceptance-tests && npm run test:config`
     - `39 tests, 0 failures`
   - `devenv shell -- bash -lc 'cd web && mix format --check-formatted lib/memba_web/controllers/dev_test_support_controller.ex lib/memba_web/router.ex test/memba_web/controllers/dev_test_support_controller_test.exs test/features/step_definitions/messaging_steps.exs'`
     - passed
   - `devenv shell -- bash -lc 'MEMBA_DEVENV_SHELL=1 bin/dev postgres && cd web && MIX_ENV=test mix test test/memba_web/controllers/dev_test_support_controller_test.exs test/features/cucumber_configuration_test.exs test/memba_web/live/member_message_live/new_send_test.exs'`
     - `9 tests, 0 failures`
   - `PATH="$PWD/bin:$PATH" dev check`
     - `242 tests, 0 failures`
   - `cd acceptance-tests && npm test -- features/member_message_deliverability.feature`
     - `20 scenarios, 144 steps, all passed`

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 010 Update acceptance step support only as needed for the new send-failure scenario and for existing normal-send steps to use the new compose flow without changing scenario wording.`
   - To:
     - `- [x] 010 Update acceptance step support only as needed for the new send-failure scenario and for existing normal-send steps to use the new compose flow without changing scenario wording.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - Read ADR 0010, ADR 0013, and ADR 0015.
   - Kept the shared feature file unchanged and business-readable.
   - Added executable plumbing in browser and Elixir Cucumber support without exposing infrastructure details in Gherkin.
   - Kept member-facing browser support aligned with the LiveView compose flow.