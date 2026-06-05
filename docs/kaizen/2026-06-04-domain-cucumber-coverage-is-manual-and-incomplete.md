# Problem: Domain Cucumber coverage is manual and incomplete

Date: 2026-06-04

## Context

We were answering whether the main `mix test` run includes the Cucumber scenarios. The project has shared feature files under `acceptance-tests/features/` and ADRs that describe running the same scenarios at both the domain/application layer and the browser acceptance layer.

Relevant current standard work:

- `docs/adr/0003-use-cucumber-at-domain-and-application-layers.md`
- `docs/adr/0010-use-shared-feature-files-with-elixir-cucumber.md`
- `web/config/test.exs`
- `web/test/features/cucumber_configuration_test.exs`

## Expected standard

The shared feature files are the behavioural contract. ADR 0003 says the same Cucumber feature files/scenarios should run at two execution layers:

1. domain-level acceptance tests through the Elixir Cucumber implementation; and
2. whole-application acceptance tests through cucumber-js/Playwright.

ADR 0010 says Elixir Cucumber is configured to read `acceptance-tests/features/**/*.feature` and run scenarios as part of `mix test`.

## What happened

The `mix test` run does include some Elixir Cucumber execution, but the coverage is not automatically derived from all shared feature files. The scenarios currently run through the domain/application model are manually enumerated in `web/test/features/cucumber_configuration_test.exs`.

Observed coverage from the current test file:

- `member_message_deliverability.feature` has selected non-`@wip` scenarios exercised through `Cucumber.Runtime`.
- `memba_staff_email_deliverability.feature` has its scenarios exercised through `Cucumber.Runtime`.
- `authentication.feature` has its scenarios exercised through `Cucumber.Runtime`.

Other shared feature files under `acceptance-tests/features/` are not run through the domain/application Cucumber path:

- `homepage.feature`
- `member_club_subdomains.feature`
- `person_email_addresses.feature`
- `staff_club_slugs.feature`

Some of these may be intentionally browser-only or still `@wip`, but the current workflow does not make that distinction explicit.

## Impact

The feedback from `mix test` can be misunderstood as complete shared-scenario coverage when it is only partial domain/application coverage. That creates a quality risk: a scenario can exist in the shared specification and pass in, or only be checked by, the browser suite while missing fast domain/application feedback.

It also creates review and planning ambiguity. Contributors have to inspect `web/test/features/cucumber_configuration_test.exs` manually to know which shared scenarios are covered at the domain layer.

## What allowed it to happen

The domain Cucumber runner is wired through a manual ExUnit test that enumerates expected scenarios and step sequences. There is no guardrail that compares the shared feature files against the scenarios actually exercised at the domain/application layer.

The ADRs describe the desired standard, but the test suite does not enforce either:

- every eligible shared scenario is run at the domain/application layer; or
- scenarios excluded from domain/application execution are explicitly marked or documented as browser-only or not-yet-domain-covered.

## Observations

- `web/config/test.exs` points Elixir Cucumber at `../acceptance-tests/features/**/*.feature`.
- `web/test/features/cucumber_configuration_test.exs` discovers feature files and step definitions, but runtime execution is based on hard-coded scenario lists.
- The test names say “all ... scenarios” for particular feature areas, not all shared features.
- The difference between domain-suitable scenarios, browser-only scenarios, and not-yet-wired scenarios is implicit.

## Why this matters

Shared scenarios are meant to prevent drift between the domain model and the web application. If domain coverage is manual and partial without an explicit exclusion mechanism, new feature files or scenarios can silently skip fast domain/application feedback.

## Open questions

- Which shared scenarios should be required to run at the domain/application layer?
- Which scenarios are legitimately browser-only because they specify presentation, routing, or responsive UI behaviour?
- Should `@wip`, a new tag, or a generated coverage check define domain-layer eligibility?

## Possible prevention ideas

- Add a coverage check that reports shared scenarios not exercised by the Elixir/domain Cucumber path.
- Require an explicit tag or manifest entry for browser-only scenarios.
- Generate domain Cucumber execution from parsed feature files instead of maintaining duplicate hard-coded scenario lists.
- Update the Cucumber test names or docs so `mix test` clearly reports partial versus complete shared-scenario coverage.
