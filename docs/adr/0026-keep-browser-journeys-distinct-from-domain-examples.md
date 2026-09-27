# 26. Keep browser journeys distinct from domain examples

Date: 2026-09-26

## Status

accepted; amended 2026-09-26 to clarify journey shape and location

## Context

The browser Cucumber suite takes about fifteen minutes. Repeating each business-rule example in Chromium costs much more than running it at the domain layer. Phoenix LiveView, controller, and domain tests already cover most routing, forms, authorization, and application behaviour. Browser tests should be reserved for risks those tests do not cover well, not treated as the default second execution of every rule.

[ADR 0003](0003-use-cucumber-at-domain-and-application-layers.md) and [ADR 0010](0010-use-shared-feature-files-with-elixir-cucumber.md) assumed the same scenarios would run at both layers. That assumption no longer justifies its cost. [Seb Rose](../reference/seb-rose-introduction-to-formulation.md) distinguishes journeys that cover complete user interactions from illustrative scenarios; [Gáspár Nagy](../reference/gaspar-nagy-clean-up-bad-bdd-scenarios.md) recommends keeping rule examples focused.

## Decision

Keep focused business-rule examples at the fast domain/application layer. Run **a few distinct browser journeys** only when a meaningful user outcome depends on a real-browser boundary—for example, crossing hosts during sign-in or interacting with a connected LiveView. Prove each browser risk once across the suite, not once per feature.

A journey may be longer and cross feature boundaries. Put each coherent journey in its own file under `acceptance-tests/features/journeys/`, tagged `@journey` for browser-only execution. Adapt existing browser scenarios rather than repeating domain-rule permutations. Keep the business language and shared feature tree; this partially supersedes ADRs 0003 and 0010's same-scenario expectation and ADR 0010's assumption that each scenario runs from the same file in both runners.

## Consequences

**Easier:**

- Business rules can grow without proportional browser-suite growth.
- A few journeys cover browser risks across multiple features.

**Harder:**

- Choosing representative journeys requires judgment; an unselected browser-specific problem could escape until another check or real use.
- Longer journeys can be slower to diagnose and more brittle; domain examples and journeys must stay aligned in meaning.
