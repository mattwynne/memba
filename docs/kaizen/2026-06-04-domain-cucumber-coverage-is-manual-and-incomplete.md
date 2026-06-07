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

### Additional observation: 2026-06-07

While reviewing how far the actual domain and browser acceptance suites had drifted from the ADR intent, we found the divergence had grown into a classification and tooling problem rather than a single missing step definition.

Observed current state before repair:

- There were 59 shared scenarios under `acceptance-tests/features/`.
- Browser Cucumber selected 47 non-`@wip` scenarios.
- The domain/application path manually executed 19 scenarios from hard-coded lists in `web/test/features/cucumber_configuration_test.exs`.
- 28 browser-selected scenarios were not executed through the domain/application path.
- No scenarios were domain-only.
- Several future or unfinished scenarios were resting in the shared suite as `@wip`, even though Matt clarified that `@wip` should only be used between planning and implementation of an active iteration.

We also tried the ADR 0010-style path directly with `Cucumber.compile_features!()`. Commenting out `Rule:` lines was necessary before Elixir Cucumber could parse the feature files. Before that, compilation failed with a `Gherkin.ParseError` near `Rule: Known club members can sign in`. After the `Rule:` parse issue was removed, generated Elixir Cucumber execution attempted to run all configured feature files and immediately exposed missing setup/step coverage and app-startup assumptions rather than selecting only scenarios that were domain-eligible.

This showed three separate weaknesses accumulating:

1. Domain coverage was manual, so new browser-backed scenarios could be added without becoming domain-backed or explicitly excluded.
2. The Elixir Cucumber implementation could not parse the `Rule:` structure encouraged by the BDD formulation standard, so the desirable Gherkin shape itself blocked the intended generated runner.
3. The tag vocabulary did not distinguish permanent runner intent from temporary coverage debt, so `@wip` and old `@todo-web` usage blurred planning, implementation, and resting-suite states.

A first containment commit, `b05fae6c Classify acceptance scenarios by runner intent`, added explicit runner-intent tags and replaced resting `@wip` scenarios with `@todo`/`@todo-*` classifications. This did not fix the underlying generated domain-runner gap; it made the remaining debt visible.

### Progress note: 2026-06-07

Commit `02cd9dc4 Add acceptance scenario count command` added a standalone operator check:

```bash
./bin/dev acceptance-tests-count
```

The command asks each runner what it can see:

- `cucumber-js` selected scenarios using `acceptance-tests/cucumber.js`.
- `cucumber-js` visible scenarios using the same paths with no tag filter.
- `cucumber-elixir` configured feature-file count using `Cucumber.Discovery.discover()`.
- `cucumber-elixir` visible scenario count using its configured feature paths and parser.
- `cucumber-elixir` selected scenario count using the current `web/config/test.exs` tag filter.
- per-feature visible counts from the Elixir parser.

Current output after the containment tagging pass was:

```text
cucumber-js selected: 47 scenarios
cucumber-js visible with no tag filter: 59 scenarios
cucumber-elixir configured feature files: 9
cucumber-elixir visible with configured feature paths and parser: 59 scenarios
cucumber-elixir selected by config/test.exs tag filter: 22 scenarios
```

This is progress because it makes parser/glob/tag-filter drift visible without running the full browser suite or pretending the manual domain harness is complete. It is not yet prevention: the command is not wired into `dev check`, does not fail on unexpected count changes, and does not prove the selected domain scenarios are actually executed by generated Elixir Cucumber tests.

## Impact

The feedback from `mix test` can be misunderstood as complete shared-scenario coverage when it is only partial domain/application coverage. That creates a quality risk: a scenario can exist in the shared specification and pass in, or only be checked by, the browser suite while missing fast domain/application feedback.

It also creates review and planning ambiguity. Contributors have to inspect `web/test/features/cucumber_configuration_test.exs` manually to know which shared scenarios are covered at the domain layer.

## What allowed it to happen

The domain Cucumber runner is wired through a manual ExUnit test that enumerates expected scenarios and step sequences. There is no guardrail that compares the shared feature files against the scenarios actually exercised at the domain/application layer.

The ADRs describe the desired standard, but the test suite does not enforce either:

- every eligible shared scenario is run at the domain/application layer; or
- scenarios excluded from domain/application execution are explicitly marked or documented as browser-only or not-yet-domain-covered.

The desired Gherkin formulation standard and the selected Elixir Cucumber parser are also out of alignment: project guidance encourages `Rule:` sections, but the current Elixir Cucumber dependency cannot parse them. That made the generated-runner path fail at parsing before it could expose coverage drift clearly.

The suite also lacked a stable tag taxonomy for runner intent and coverage debt. Without separate meanings for “not applicable to this runner” and “should run here but does not yet”, temporary tags could accumulate and become normal.

## Observations

- `web/config/test.exs` points Elixir Cucumber at `../acceptance-tests/features/**/*.feature`.
- `web/test/features/cucumber_configuration_test.exs` discovers feature files and step definitions, but runtime execution is based on hard-coded scenario lists.
- The test names say “all ... scenarios” for particular feature areas, not all shared features.
- The difference between domain-suitable scenarios, browser-only scenarios, and not-yet-wired scenarios was implicit until the 2026-06-07 containment tagging pass.
- `Cucumber.compile_features!()` is not called from `web/test/test_helper.exs`, so the ADR-described generated runner is not part of the normal `mix test` path.
- The current Elixir Cucumber dependency cannot parse `Rule:` sections, forcing the team either to comment out rules or avoid the BDD structure the formulation skill recommends.
- `./bin/dev acceptance-tests-count` now gives a cheap scenario-count inventory from both Cucumber implementations, but it is an operator command rather than a quality gate.

## Why this matters

Shared scenarios are meant to prevent drift between the domain model and the web application. If domain coverage is manual and partial without an explicit exclusion mechanism, new feature files or scenarios can silently skip fast domain/application feedback.

## Open questions

- Which shared scenarios should be required to run at the domain/application layer?
- Which scenarios are legitimately browser-only because they specify presentation, routing, or responsive UI behaviour?
- Is the current `@not-domain` / `@not-ui` / `@todo-domain` / `@todo-ui` / `@todo` taxonomy sufficient, or should some tags collapse after the suite converges?
- Should we patch/replace Elixir Cucumber to support `Rule:`, or keep rules as comments until the runner changes?

## Possible prevention ideas

- Add a coverage check that reports shared scenarios not exercised by the Elixir/domain Cucumber path.
- Require an explicit tag or manifest entry for browser-only scenarios and domain-only scenarios.
- Generate domain Cucumber execution from parsed feature files instead of maintaining duplicate hard-coded scenario lists.
- Add a parser compatibility check for feature-file syntax used by the project's BDD standard, especially `Rule:`.
- Update the Cucumber test names or docs so `mix test` clearly reports partial versus complete shared-scenario coverage.
