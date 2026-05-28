# 13. Use PhoenixTest for feature-style web tests

Date: 2026-05-27

## Status

accepted

## Context

Memba is a Phoenix 1.8 application. We expect to test user-facing web behaviour across both regular controller-rendered pages and LiveView pages.

Phoenix's built-in `Phoenix.ConnTest` and `Phoenix.LiveViewTest` APIs are powerful, but they use different styles. That makes higher-level feature tests harder to read and harder to keep close to the language used in acceptance criteria.

The project also uses Cucumber-style acceptance tests. Those tests benefit from concise web interaction helpers that can be shared by step definitions without exposing each step to LiveView-vs-controller implementation details.

## Decision

Use `phoenix_test` for feature-style Phoenix web tests.

Add it as a test-only dependency:

```elixir
{:phoenix_test, "~> 0.11.1", only: :test}
```

Import `PhoenixTest` from `MembaWeb.ConnCase` so web tests and future Cucumber step definitions can use the same fluent helpers.

Continue to use lower-level Phoenix test helpers when a test needs specific controller, connection, or LiveView internals.

## Consequences

Feature-style web tests can read as user interactions rather than implementation details.

The same test vocabulary can cover static pages and LiveViews, reducing churn if a page later moves between controller rendering and LiveView.

The test dependency set grows slightly. Contributors need to understand when to choose PhoenixTest versus lower-level Phoenix helpers.
