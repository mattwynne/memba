# Problem: Test command standard was not obvious during local implementation

Date: 2026-06-17

## Context

During local implementation of iteration 033 (`docs/iterations/033-homepage-staff-bar/plan.md`), the agent needed fast feedback before the required final project quality gate. Matt observed that the agent was confused about which commands to use for tests and did not clearly know the relationship between `dev check`, `dev acceptance`, and lower-level targeted commands.

Relevant local state when the note was captured:

- branch: `main`
- worktree: uncommitted iteration 033 implementation edits plus a committed plan-validation status update
- changed implementation paths included `web/lib/memba_web/controllers/page_html/home.html.heex`, `web/test/memba_web/controllers/page_controller_test.exs`, and `acceptance-tests/features/support/homepage.js`

## Expected standard

Project standard work says `dev check` is the required final gate after code, config, dependency, migration, acceptance-test, or app-behaviour changes. When an agent wants targeted feedback before that final gate, it should know the project's accepted command surface and use the right wrapper or working directory without guessing.

For this project, useful command boundaries include:

- final quality gate: `./bin/dev check`
- browser acceptance workflow: `./bin/dev acceptance` or a deliberate Cucumber command from `acceptance-tests/`
- targeted Elixir tests: run from `web/`, for example `cd web && mix test test/memba_web/controllers/page_controller_test.exs`

## What happened

The agent first tried to run the targeted controller test from the repository root with a `web/test/...` path:

```text
mix test web/test/memba_web/controllers/page_controller_test.exs
```

The command compiled the app, then failed before running the intended test file:

```text
Paths given to "mix test" did not match any directory/file: web/test/memba_web/controllers/page_controller_test.exs
```

The agent then recovered by running the command from `web/`:

```text
cd web && mix test test/memba_web/controllers/page_controller_test.exs
```

That targeted test passed. The browser homepage scenarios were then run directly with Cucumber from `acceptance-tests/`.

## Impact

Severity: minor friction in this session, with quality-risk potential if repeated.

The wrong command cost time and created an avoidable failure signal. More importantly, confusion about `dev check` versus targeted test commands can lead agents to validate the wrong boundary, miss the required final gate, or report partial acceptance evidence as if it were full project quality evidence.

## What allowed it to happen

The command contract is spread across project instructions, `bin/dev`, package scripts, and runner-specific directories. The local coding prompt reminds agents to run `dev check`, but it does not give a compact command map for common targeted feedback loops. The Elixir/Mix reference says to use `mix test test/my_test.exs`, but in this repository that advice only works from `web/`, not from the repository root.

The root `mix test web/test/...` failure is also slightly confusing: it compiles the app before reporting that the path did not match, so an agent can spend attention on the wrong layer before noticing the working-directory issue.

## Observations

- The abnormality appeared during the implementation/test step, before final `dev check`.
- The product code was not blocked; the agent recovered with the correct `cd web && mix test ...` command.
- The browser acceptance command used in this slice was `cd acceptance-tests && npm test -- features/homepage.feature --name "Pat is Memba staff|Pat is staff and a club member"`.
- The project already has `bin/dev` commands intended to encode standard workflows, but the agent did not first inspect or use them for command selection.
- This is workflow/tooling friction, not a product bug.

## Why this matters

Agents frequently need a fast inner loop before the full `dev check`. If the command map is not obvious, each agent may rediscover working directories and wrappers by trial and error. That creates waste and increases the chance of false confidence from running a narrower command than the project standard requires.

## Open questions

- Where should the canonical quick command map live: `AGENTS.md`, `docs/reference/elixir-mix-tests.md`, `bin/dev help`, or a dedicated testing reference?
- Should agents be instructed to inspect `./bin/dev help` before running tests in this repository?
- Should `bin/dev` expose targeted wrappers for common cases so agents do not need to know runner working directories?

## Possible prevention ideas

- Add a concise project-specific testing command map to the agent instructions or reference docs.
- Include examples for final gate, quick gate, targeted ExUnit, targeted browser acceptance, and acceptance support tests.
- Make the root-level test failure more actionable, or provide a root wrapper that routes `web/test/...` paths to `cd web && mix test ...`.
- Update iteration implementation prompts to distinguish targeted feedback commands from the required final `dev check` evidence.

## Additional observation: 2026-06-21

### Context

After `./bin/dev check` failed in browser acceptance at `features/member_message_deliverability.feature:25`, the operator tried to rerun that one scenario through the project wrapper:

```sh
./bin/dev acceptance features/member_message_deliverability.feature:25
```

The workflow step was targeted acceptance rerun after a full quality-gate failure.

### Expected standard

When a Cucumber failure reports a file and line number, a contributor should be able to pass that same file-and-line selector to the project acceptance wrapper and rerun only the failed scenario, or receive a clear error telling them the supported targeted command.

### What happened

The command did not run only the requested scenario. Cucumber printed:

```text
You have specified paths in both your configuration file and as CLI arguments.
In a future major version, the CLI argument will override the configuration file instead of being merged.
Current result:     features/**/*.feature, features/member_message_deliverability.feature:25
Future result:      features/member_message_deliverability.feature:25
```

Because `acceptance-tests/cucumber.js` sets `default.paths` to `features/**/*.feature`, the CLI path was merged with the configured default path. The run began executing the broader acceptance suite instead of the single failed scenario.

### Impact

Severity: minor friction with quality-gate risk.

The failed focused rerun wasted time and made the validation state more confusing. It also encouraged stopping or interrupting a long unintended acceptance run, which can obscure whether the original failure reproduced. In future, the same trap could cause an agent to claim targeted rerun evidence that actually came from a broader or different command shape.

### What allowed it to happen

`bin/dev acceptance` passes extra arguments through to `npm test -- "$@"`, and `npm test` runs `cucumber-js` with the default Cucumber profile. That profile already supplies a path glob. Cucumber currently merges CLI paths with configured paths, but this non-obvious behavior is only reported after the long-running acceptance lifecycle has already started.

The project does not document a supported one-scenario browser acceptance command, and the wrapper does not detect file/line arguments and adjust the Cucumber profile/path behavior.

### Observations

- `acceptance-tests/package.json` defines `test` as plain `cucumber-js`.
- `acceptance-tests/cucumber.js` defines `default.paths: ["features/**/*.feature"]`.
- `bin/dev acceptance` changes into `acceptance-tests/` and runs `local_test_email_env npm test -- "$@"`.
- The file-line selector looked like ordinary Cucumber syntax, but the configured default path made it behave unexpectedly.
- This is command-surface friction, not a product bug.

### Open questions

- What should be the canonical targeted browser acceptance command for one scenario by file and line?
- Should `bin/dev acceptance <file:line>` support that directly?
- Should the Cucumber config move the feature glob out of `default.paths` or add a separate profile for targeted runs?

### Possible prevention ideas

- Teach `bin/dev acceptance` to detect feature file/path arguments and invoke Cucumber in a way that avoids merging with `default.paths`.
- Add an explicit `bin/dev acceptance-scenario <feature:line>` or documented npm script for focused reruns.
- Add a command-map note showing full acceptance, tagged/name-filtered acceptance, and exact scenario rerun commands.
