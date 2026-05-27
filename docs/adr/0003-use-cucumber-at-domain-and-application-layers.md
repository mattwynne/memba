# 3. Use Cucumber at domain and application layers

Date: 2026-05-26

## Status

accepted

## Context

Memba needs executable acceptance tests that describe product behaviour in language close to the domain while still giving confidence that the full Phoenix application works for users.

We want one shared set of scenarios because writing feature files is domain modelling. The scenarios are not browser scripts or test-automation instructions; they are where we discover and name the behaviour of the product. Keeping them abstract from the test infrastructure helps us get the language right and preserve a clean ubiquitous language.

If domain tests and browser tests use separate feature files, they can drift: the fast domain tests may prove one behaviour while the browser tests prove a slightly different one. Running the same scenarios at both layers keeps the ubiquitous language and acceptance criteria aligned while still letting each layer test a different risk.

The domain layer answers: "Does the core model make the right decisions?" This is especially important for event-sourced workflows, where commands, events, aggregates, and projections should be validated without the noise and cost of browser automation.

The whole-application layer answers: "Can a real user do this through the Phoenix app?" It validates routing, LiveView/controllers, forms, rendering, and browser-visible outcomes.

Email and other integrations also need test seams. Acceptance tests should not call real providers such as Postmark, SendGrid, Stripe, or other external services unless they are explicitly manual smoke tests. Automated acceptance tests should use fake or test adapters at the integration boundary.

## Decision

Use the same Cucumber feature files/scenarios at two execution layers:

1. **Domain-level acceptance tests** use the Elixir Cucumber implementation from `https://github.com/huddlz-hq/cucumber`. Step definitions for this layer run the shared scenarios directly against the Elixir domain model, commands, aggregates, projectors/read models, and application services. They use fake or stub ports for external dependencies such as email providers.
2. **Whole-application acceptance tests** use the existing `cucumber-js` and Playwright setup. Step definitions for this layer run the same shared scenarios through the Phoenix application, driving the browser or HTTP interface and validating user-visible behaviour. They still use test adapters or fake providers for external integrations, such as email sending.

The scenarios are the shared specification of product behaviour. Each layer provides its own step definitions/adapters for executing those scenarios at the appropriate boundary. Domain-level execution should be fast, focused, and suitable for specifying event-sourced workflows. Whole-application execution can be slower and should prove that the same behaviours are correctly wired through the web app.

Manual demo scripts remain separate from automated acceptance tests. Manual demos may use real external services when the purpose is to validate production-like integration behaviour, such as live email deliverability.

## Consequences

A single shared scenario set becomes the behavioural contract for the feature. Running that contract at both layers reduces duplication in the specification and makes drift visible when one layer can no longer satisfy the same examples.

Domain behaviour can be specified and tested without brittle browser automation, making it easier to evolve the event-sourced model with confidence.

The full application still gets executable acceptance coverage where UI and Phoenix wiring matter.

The project will carry two Cucumber toolchains against the same feature files, so contributors must keep scenarios free of layer-specific implementation detail such as clicking buttons, CSS selectors, route names, database setup, or adapter configuration. Step definitions, test configuration, folder structure, and documentation should make the two execution modes clear.

External integrations must be designed behind ports/adapters so both acceptance layers can use fakes or test adapters. This adds a little structure up front but keeps tests reliable and fast.
