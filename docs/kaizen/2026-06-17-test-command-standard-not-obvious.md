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
