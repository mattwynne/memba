# Domain Cucumber convergence

Date: 2026-06-07
Status: ready

## Goal

Bring the shared acceptance suite back in line with ADR 0003/0010: every scenario that can meaningfully run at the domain/application layer should do so automatically, while scenarios that are intentionally UI-only or still parked are explicitly tagged.

This iteration is about test architecture, scenario classification, and domain step coverage. It should make future drift mechanically hard: removing a `@todo-domain` tag should immediately pull that scenario into the generated domain Cucumber ExUnit suite.

## Background / Context

The shared feature files in `acceptance-tests/features/` are intended to be the behavioural contract across two runners:

1. Elixir/domain Cucumber for fast application/domain feedback.
2. cucumber-js/Playwright for browser-visible confidence.

The domain path previously relied on hard-coded scenario lists in `web/test/features/cucumber_configuration_test.exs`. That meant the feature files and domain coverage could drift. We also discovered that the current Elixir Cucumber parser cannot parse `Rule:`, so rules are temporarily kept as comments (`# Rule:`).

A project-local domain runner now exists in `web/test/support/domain_cucumber_runner.ex`. It discovers shared feature files, applies the domain tag filter, and generates ExUnit tests for every domain-eligible scenario. The remaining work is to work down the explicit `@todo-domain` debt carefully, with Matt reviewing wording and step intent feature by feature.

Current todo-tagged scenario debt at the start of this plan:

- `@todo-domain`: 11 scenarios
- `@todo`: 10 scenarios
- `@todo-ui`: 2 scenarios

## Related Problems

No product problem note in `docs/problems/` is directly resolved by this technical iteration.

Related kaizen note:

- [`docs/kaizen/2026-06-04-domain-cucumber-coverage-is-manual-and-incomplete.md`](../../kaizen/2026-06-04-domain-cucumber-coverage-is-manual-and-incomplete.md): expected to be resolved for the mechanical-prevention part. Remaining scenario-level `@todo-*` work should become explicit, tracked convergence debt rather than hidden runner drift.

## Scope

### In scope

- Keep the generated domain Cucumber runner as the source of truth for domain-eligible scenarios.
- Remove the old `dev acceptance-tests-count` inspection command; it is no longer the right prevention mechanism.
- Maintain the tag taxonomy in `acceptance-tests/README.md` and runner filters:
  - `@not-domain`
  - `@not-ui`
  - `@todo-domain`
  - `@todo-ui`
  - `@todo`
  - `@wip` only during active planning-to-implementation gaps
- Work through `@todo-domain` scenarios in small batches, starting with scenarios whose domain rules are already implemented.
- For each batch, review the Gherkin wording/preconditions with Matt before or during step-definition work.
- Add or refine Elixir/domain step definitions so they assert the domain rule rather than mimic browser mechanics.
- Remove `@todo-domain` only when the generated domain runner executes the scenario green.
- Keep browser Cucumber green throughout.
- Preserve `@not-domain` for deliberately UI/browser-specific scenarios.

### Out of scope

- Adding new product behaviour.
- Replacing the Elixir Cucumber dependency.
- Teaching the current Elixir Cucumber parser to support real `Rule:` syntax.
- Converging all `@todo` and `@todo-ui` scenarios unless they are trivial follow-ons from `@todo-domain` work.
- Rewriting all existing Gherkin at once.

## Iteration Type

Technical/engineering.

This iteration does not introduce a new user-observable product rule. It improves the acceptance-test factory so existing stakeholder-readable scenarios are selected and executed consistently across the intended runners.

## Acceptance Scenarios / Feature Files

BDD decision: Not applicable for new product behaviour.

The work is acceptance infrastructure and coverage convergence. Existing feature files are the subject of the work; new Gherkin should not be added unless Matt and the implementer discover that an existing scenario needs to be split or clarified to express the rule correctly.

## Allowed acceptance feature changes

Implementation may edit existing files under `acceptance-tests/features/` only for these purposes:

- remove `@todo-domain` from a scenario once domain coverage is implemented;
- add, remove, or adjust `@not-domain`, `@not-ui`, `@todo-domain`, `@todo-ui`, or `@todo` when Matt agrees the classification is wrong;
- replace remaining real `Rule:` lines with `# Rule:` while the Elixir parser cannot handle `Rule:`;
- clarify scenario preconditions or wording when the current Gherkin hides an important domain fact, as with making Bob's membership explicit before Bob sends a club message.

No acceptance feature change should alter product scope without Matt's review.

## Acceptance Criteria

- `web/test/features/domain_cucumber_acceptance_test.exs` generates and runs one ExUnit test for every scenario selected by the domain tag filter.
- `web/test/features/cucumber_configuration_test.exs` no longer contains hard-coded scenario step lists.
- `dev acceptance-tests-count` is removed.
- The kaizen note records the mechanical-prevention fix rather than recommending the removed inspection command.
- At least one `@todo-domain` feature batch is completed, proving the ratchet works.
- Remaining `@todo-domain` scenarios are explicit and understandable.
- `dev check` passes.

## Open Business Decisions

None known. Matt should remain involved when Gherkin wording reveals a domain-language or policy question.

## Implementation Plan

1. Remove the obsolete `dev acceptance-tests-count` command and update the kaizen note to explain why generated execution is the better prevention.
2. Ensure the generated domain runner remains covered by focused tests for tag selection and excluded tags.
3. Work through `@todo-domain` scenarios feature by feature. Suggested order:
   1. `person_email_addresses.feature` — already mostly implemented and a good proof of the pattern.
   2. `request_account.feature` — onboarding rules are core domain/application behaviour.
   3. `member_message_deliverability.feature` remaining `@todo-domain` scenarios — email subject/addressing and blank body validation.
   4. `memba_staff_operations.feature` scenario `Alice belongs to two clubs` — decide whether it is truly domain core or should be reclassified.
4. For each feature batch:
   - inspect current browser steps and domain APIs;
   - ask Matt about ambiguous scenario wording/classification;
   - update Gherkin only when it makes the rule clearer;
   - add domain step definitions;
   - remove `@todo-domain` from passing scenarios;
   - run targeted domain tests and browser dry-run/full acceptance as appropriate.
5. Leave `@todo` and `@todo-ui` scenarios parked unless this iteration naturally resolves them.

## Open Technical Decisions

- Whether the project-local domain runner should later be upstreamed into `huddlz-hq/cucumber` or replaced by a patched dependency with tag filtering and `Rule:` support.
- Whether `@todo` remains distinct from `@wip` after the suite converges.

## New Capability

The team can safely remove a `@todo-domain` tag and rely on ExUnit to run that scenario through the domain/application Cucumber path automatically. Domain coverage no longer depends on manually duplicating scenario names and step lists.

## Validation Plan

- `cd web && mix test test/features --trace`
- `cd acceptance-tests && node --test test/cucumber_config.test.js`
- `cd acceptance-tests && npm test -- --dry-run --format summary`
- `dev check`

## Risks / Follow-ups

- Some scenarios currently tagged `@todo-domain` may actually be UI-only or may need rewording before they make good domain examples.
- The current Elixir parser still cannot parse real `Rule:`. Keeping rules as comments is a workaround, not the final standard.
- The generated domain runner has project-local logic that overlaps with the Cucumber dependency; future dependency changes may require revisiting it.
