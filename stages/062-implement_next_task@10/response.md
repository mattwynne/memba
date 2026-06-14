Final whitespace check is clean. The task-specific acceptance/domain validations passed; a direct full `mix test` still has 8 unrelated pre-existing failures in member-message/page-controller/admin-layout tests.Implemented task 010:

- [x] 010 Implement or update acceptance step support for the `@iteration-032` scenarios, then remove/narrow `@todo-domain`/`@todo-ui` when they pass.

What changed:
- Enabled the two `@iteration-032` authentication scenarios by removing `@todo-domain @todo-ui`.
- Added domain Cucumber step support for auth-email progress, provider acceptance, neutral/privacy-preserving copy, and no inbox-placement overclaiming.
- Added browser Cucumber support to capture opaque auth request IDs, assert progress/privacy copy, and simulate provider acceptance via a server command.
- Added auth-email request reset support for browser acceptance isolation.
- Fixed domain Cucumber shared-feature discovery so scenarios nested under `Rule:` blocks are selected and executable.
- Normalized domain step registry keys for string and regex step definitions.
- Narrowed ambiguous club invitation domain steps to avoid step-definition ambiguity.
- Updated stale JS acceptance helper/unit expectations needed by `npm run test:config`.
- Updated membership-administration domain step tests to find scenarios nested under `Rule:` blocks.
- Checked off only task 010 in `docs/iterations/032-auth-email-delivery-progress/todo.md`.

Validation run:
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/features/cucumber_configuration_test.exs test/features/domain_cucumber_runner_test.exs'`
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/features/domain_cucumber_acceptance_test.exs --include domain_cucumber'`
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd acceptance-tests && npm test -- --tags @iteration-032'`
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd acceptance-tests && npm run test:config'`
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/features/membership_administration_steps_test.exs'`
- Passed: `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix format --check-formatted ...'`
- Passed: `git diff --check`
- Ran: `PATH="$PWD/bin:$PATH" dev check`
  - The wrapper exited `0` and browser acceptance passed, but its output included existing ExUnit failures.
- Confirmed with direct `mix test`: still 8 unrelated pre-existing failures remain in member-message/page-controller/admin-layout tests.

Notes:
- No task splits or reordering were made.
- No commit was created.
- ADR alignment preserved:
  - ADR 0003/0010: shared feature files continue to drive both domain and browser acceptance.
  - ADR 0021: auth-email progress updates rely on committed persistence before PubSub notification.
  - ADR 0022: no projection-barrier semantics were conflated with the auth progress update path.
- Privacy behaviour remains neutral for unknown addresses and does not expose account existence or claim inbox placement.