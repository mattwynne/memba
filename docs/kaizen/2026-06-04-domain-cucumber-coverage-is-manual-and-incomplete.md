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

- `member_message_deliverability.feature` has selected non-`@todo-domain`/`@todo-ui` scenarios exercised through `Cucumber.Runtime`.
- `memba_staff_email_deliverability.feature` has its scenarios exercised through `Cucumber.Runtime`.
- `authentication.feature` has its scenarios exercised through `Cucumber.Runtime`.

Other shared feature files under `acceptance-tests/features/` are not run through the domain/application Cucumber path:

- `homepage.feature`
- `member_club_subdomains.feature`
- `person_email_addresses.feature`
- `staff_club_slugs.feature`

Some of these may be intentionally browser-only or still `@todo-domain`/`@todo-ui`, but the current workflow does not make that distinction explicit.

### Additional observation: 2026-06-07

While reviewing how far the actual domain and browser acceptance suites had drifted from the ADR intent, we found the divergence had grown into a classification and tooling problem rather than a single missing step definition.

Observed current state before repair:

- There were 59 shared scenarios under `acceptance-tests/features/`.
- Browser Cucumber selected 47 scenarios that were not temporarily excluded from the browser runner.
- The domain/application path manually executed 19 scenarios from hard-coded lists in `web/test/features/cucumber_configuration_test.exs`.
- 28 browser-selected scenarios were not executed through the domain/application path.
- No scenarios were domain-only.
- Several future or unfinished scenarios were resting in the shared suite under a generic planning/parking tag, so the suite did not say which runner still needed coverage.

We also tried the ADR 0010-style path directly with `Cucumber.compile_features!()`. Commenting out `Rule:` lines was necessary before Elixir Cucumber could parse the feature files. Before that, compilation failed with a `Gherkin.ParseError` near `Rule: Known club members can sign in`. After the `Rule:` parse issue was removed, generated Elixir Cucumber execution attempted to run all configured feature files and immediately exposed missing setup/step coverage and app-startup assumptions rather than selecting only scenarios that were domain-eligible.

This showed three separate weaknesses accumulating:

1. Domain coverage was manual, so new browser-backed scenarios could be added without becoming domain-backed or explicitly excluded.
2. The Elixir Cucumber implementation could not parse the `Rule:` structure encouraged by the BDD formulation standard, so the desirable Gherkin shape itself blocked the intended generated runner.
3. The tag vocabulary did not distinguish permanent runner intent from temporary coverage debt, and generic parking tags blurred planning, implementation, and resting-suite states.

A first containment commit, `b05fae6c Classify acceptance scenarios by runner intent`, added explicit runner-intent tags and replaced resting generic parking tags with runner-specific debt classifications. This did not fix the underlying generated domain-runner gap; it made the remaining debt visible.

## Resolution

Date: 2026-06-07

Root cause: domain Cucumber coverage depended on hard-coded scenario lists and ambiguous exclusion tags, so shared feature-file changes could drift from the domain/application runner without an executable guardrail.

Fix applied:

- `web/test/support/domain_cucumber_runner.ex`: added a project-local runner that discovers shared feature files from the configured Cucumber paths, applies the domain tag filter, excludes `@not-domain` and `@todo-domain`, and generates ExUnit tests for every remaining domain-eligible scenario.
- `web/test/features/domain_cucumber_acceptance_test.exs`: uses the generated runner so removing `@todo-domain` from a scenario immediately pulls it into the domain acceptance suite.
- Acceptance scenario tags and runner filters were later tightened so temporary debt is expressed by runner-specific tags only.

Validation:

- Existing evidence: commit `fd08def8` (`Run all domain-eligible Cucumber scenarios`) introduced the generated domain runner; commit `de2cb458` (`Remove generic acceptance parking tags`) removed the ambiguous generic parking tags.
- No command rerun for this backfill; this change only records the already-applied resolution.

Remaining follow-up:

- Decide whether to patch/replace Elixir Cucumber to support `Rule:` syntax, or keep rules as comments until the runner changes.

## Impact

Before the repair, the feedback from `mix test` could be misunderstood as complete shared-scenario coverage when it was only partial domain/application coverage. That created a quality risk: a scenario could exist in the shared specification and pass in, or only be checked by, the browser suite while missing fast domain/application feedback.

After the repair, the domain feedback is mechanically tied to the shared feature files and tag taxonomy. Contributors no longer have to inspect or update a hard-coded scenario list to know which shared scenarios are covered at the domain layer.

## What allowed it to happen

The domain Cucumber runner was wired through a manual ExUnit test that enumerated expected scenarios and step sequences. There was no guardrail that compared the shared feature files against the scenarios actually exercised at the domain/application layer.

The ADRs described the desired standard, but the test suite did not enforce either:

- every eligible shared scenario is run at the domain/application layer; or
- scenarios excluded from domain/application execution are explicitly marked or documented as browser-only or not-yet-domain-covered.

The desired Gherkin formulation standard and the selected Elixir Cucumber parser are also out of alignment: project guidance encourages `Rule:` sections, but the current Elixir Cucumber dependency cannot parse them. That made the generated-runner path fail at parsing before it could expose coverage drift clearly.

The suite also lacked a stable tag taxonomy for runner intent and coverage debt. Without separate meanings for “not applicable to this runner” and “should run here but does not yet”, temporary tags could accumulate and become normal.

## Observations

- `web/config/test.exs` points Elixir Cucumber at `../acceptance-tests/features/**/*.feature`.
- `web/test/features/domain_cucumber_acceptance_test.exs` now generates one ExUnit test for every scenario selected by the domain tag filter.
- The difference between domain-suitable scenarios, browser-only scenarios, and not-yet-wired scenarios was implicit until the 2026-06-07 containment tagging pass.
- `Cucumber.compile_features!()` is still not called from `web/test/test_helper.exs`; the project-local runner is used instead so we can apply the tag filter before execution.
- The current Elixir Cucumber dependency cannot parse `Rule:` sections, forcing the team either to comment out rules or avoid the BDD structure the formulation skill recommends.

## Why this matters

Shared scenarios are meant to prevent drift between the domain model and the web application. The repaired domain runner now prevents eligible scenarios from silently skipping fast domain/application feedback: if a scenario should not run in the domain suite yet, it must carry an explicit exclusion tag.

### Decision note: 2026-06-07

After the suite converged, Matt decided to remove the generic parking tags entirely. Temporary acceptance debt should now be expressed only by runner:

- `@todo-domain` means “this should run in the domain/application runner but cannot yet”.
- `@todo-ui` means “this should run in the browser runner but cannot yet”.
- A future-facing scenario that cannot run in either runner should carry both tags.

The runner tag filters and documentation were updated to stop recognising generic parking tags. The browser runner excludes only `@not-ui` and `@todo-ui`; the domain runner excludes only `@not-domain` and `@todo-domain`. This keeps every exclusion tied to a specific runner and removes the ambiguous “parked somewhere” state.

## Remaining questions

- Should we patch/replace Elixir Cucumber to support `Rule:`, or keep rules as comments until the runner changes?

## Prevention now in place

- Domain Cucumber execution is generated from parsed feature files instead of maintained as duplicate hard-coded scenario lists.
- Scenarios excluded from the domain runner require explicit tags.
- `dev check --quick` runs the generated domain scenario tests through ExUnit.

## Follow-up ideas

- Add a parser compatibility check for feature-file syntax used by the project's BDD standard, especially `Rule:`.
- Consider moving the project-local runner behaviour upstream into the Elixir Cucumber dependency.
