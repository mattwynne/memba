# Acceptance tests

The shared Cucumber feature files in `features/` are used by two runners:

- the browser runner in this directory (`npm test`), which drives the Phoenix app through Playwright;
- the Elixir/domain runner used by `dev check`, which executes shared feature steps against domain/application code.

## Tags

Use tags to make temporary deferrals explicit:

- `@wip` means the scenario is future-facing planning language and is not expected to pass yet. Both runners exclude `@wip` by default. Remove the tag in the implementation iteration that makes the scenario pass.
- `@todo-web` means the scenario has domain/application coverage but is not yet backed by browser automation. The browser runner excludes it; the Elixir/domain runner does not.

Do not use `@wip` to hide broken current behaviour. Only use it for scenarios deliberately written ahead of implementation as part of an approved iteration plan.
