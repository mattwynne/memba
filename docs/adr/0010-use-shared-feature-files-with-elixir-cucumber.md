# 10. Use shared feature files with Elixir Cucumber

Date: 2026-05-26

## Status

accepted

## Context

ADR 0003 says Memba uses the same Cucumber feature files at two layers:

1. Domain-level acceptance tests against the Elixir domain model.
2. Whole-application acceptance tests through cucumber-js/Playwright.

The first message deliverability iteration needs to run shared feature files against the Elixir domain model.

The feature files currently live outside the Phoenix app under `acceptance-tests/features/`, because they are shared behavioural specifications rather than implementation-specific test scripts.

## Decision

Use the Elixir Cucumber package from GitHub:

```elixir
{:cucumber, github: "huddlz-hq/cucumber"}
```

Configure Elixir Cucumber to read shared feature files from:

```text
acceptance-tests/features/**/*.feature
```

Put Elixir/domain step definitions under:

```text
web/test/features/step_definitions/**/*.exs
```

Run the Elixir Cucumber scenarios as part of `mix test`, using `Cucumber.compile_features!()` from the Phoenix app's test setup.

## Consequences

The shared feature files remain domain modelling artifacts and are not duplicated for each execution layer.

Elixir Cucumber can execute the same scenarios directly against the domain model, while cucumber-js/Playwright can later execute them through the full web app.

The Phoenix app's test configuration must point outside `web/` to the shared feature path. Contributors must keep feature files free of test-infrastructure details so both runners can use them.
