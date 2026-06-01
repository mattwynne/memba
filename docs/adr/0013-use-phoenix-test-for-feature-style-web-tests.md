# 13. Use PhoenixTest for feature-style web tests

Date: 2026-05-27

## Status

accepted

## Context

Memba is a Phoenix 1.8 application. We expect to test user-facing web behaviour across both regular controller-rendered pages and LiveView pages.

ADR 0015 makes LiveView the default for member application pages. Those pages should be test-driven from the user's point of view rather than implemented first and covered afterwards.

Phoenix's built-in `Phoenix.ConnTest` and `Phoenix.LiveViewTest` APIs are powerful, but they use different styles. That makes higher-level feature tests harder to read and harder to keep close to the language used in acceptance criteria.

The project also uses Cucumber-style acceptance tests. Those tests benefit from concise web interaction helpers that can be shared by step definitions without exposing each step to LiveView-vs-controller implementation details.

## Decision

Use `phoenix_test` for feature-style Phoenix web tests.

Add it as a test-only dependency:

```elixir
{:phoenix_test, "~> 0.11.1", only: :test}
```

Import `PhoenixTest` from `MembaWeb.ConnCase` so web tests and future Cucumber step definitions can use the same fluent helpers.

Test-drive LiveView member application work with PhoenixTest feature-style tests for user-visible behaviour. Write the failing PhoenixTest coverage before or alongside the LiveView implementation, especially for routing, authorization, forms, state transitions, and interactive behaviours.

Continue to use lower-level Phoenix test helpers when a test needs specific controller, connection, or LiveView internals. Use `Phoenix.LiveViewTest` directly for LiveView-specific mechanics that PhoenixTest cannot express clearly, but do not use lower-level tests as a substitute for user-facing PhoenixTest coverage.

## Consequences

Feature-style web tests can read as user interactions rather than implementation details.

The same test vocabulary can cover static pages and LiveViews, reducing churn if a page later moves between controller rendering and LiveView.

LiveView member application work starts from user-visible behaviour and is less likely to drift into untested implementation detail.

The test dependency set grows slightly. Contributors need to understand when to choose PhoenixTest versus lower-level Phoenix helpers.
