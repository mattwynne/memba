# Acceptance tests

The shared Cucumber feature files in `features/` are used by two runners:

- the browser runner in this directory (`npm test`), which drives the Phoenix app through Playwright;
- the Elixir/domain runner used by `dev check`, which executes shared feature steps against domain/application code.

## Tags

Use tags to make scenario intent and temporary coverage gaps explicit:

- `@not-domain` means the scenario is intentionally not meaningful at the domain/application layer. The domain runner excludes it; the browser runner still runs it unless another tag excludes it.
- `@not-ui` means the scenario is intentionally not meaningful through browser automation. The browser runner excludes it; the domain runner still runs it unless another tag excludes it.
- `@todo-domain` means the scenario should become domain/application acceptance coverage, but the domain runner cannot execute it yet. The domain runner excludes it temporarily; the browser runner still runs it unless another tag excludes it.
- `@todo-ui` means the scenario should become browser acceptance coverage, but the browser runner cannot execute it yet. The browser runner excludes it temporarily; the domain runner still runs it unless another tag excludes it.

If a scenario is future-facing for both runners, tag it with both `@todo-domain` and `@todo-ui`.

Do not use tags to hide broken current behaviour. Use `@todo-domain` and `@todo-ui` for explicit, temporary coverage gaps and remove them as the relevant runner becomes able to execute the scenario.
