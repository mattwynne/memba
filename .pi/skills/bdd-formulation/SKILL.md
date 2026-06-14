---
name: bdd-formulation
description: Use when writing or reviewing Gherkin scenarios, especially after discovering examples or edge cases that reveal a business rule
---

# BDD Formulation

Formulation is the craft of writing Gherkin that serves as
living documentation. Good scenarios are concrete examples
of business rules, not test scripts.

## Core Habit

When examples reveal a rule, make the rule visible in the
feature file: group related scenarios under a rule heading that
states the rule they illustrate.

In Memba, use the native Gherkin `Rule:` keyword for rule headings.
Both the browser Cucumber runner and the Elixir/domain Cucumber parser
support it now, so commented rule headings are no longer needed.

```gherkin
Rule: Manual blockers replace the existing manual blocker

  Scenario: Adding another manual blocker updates the reason
    Given I add the yak "deploy"
    And I add manual blocker to "deploy" with reason "waiting on vendor"
    When I add manual blocker to "deploy" with reason "waiting on review"
    Then the JSON yak "deploy" should have exactly one manual blocker with reason "waiting on review"
```

## BRIEF Check

From Seb Rose, scenarios should be:

- **B**usiness language: terms stakeholders understand.
- **R**eal data: vivid, concrete examples.
- **I**ntention revealing: say what matters, not how the UI works.
- **E**ssential: every line serves the rule.
- **F**ocused: one rule per scenario, short enough to read.

## Guidelines

- Use native `Rule:` headings for business/domain rules, not implementation mechanisms.
- Keep scenario names as concrete examples of the rule, not restatements of it.
- If a scenario discovers a new rule, add or split out a new `Rule:` section.
- If a scenario appears to illustrate multiple rules, split it.
- Prefer several small `Rule:` groups over one long pile of loosely related scenarios.
- Carry one consistent narrative through a feature where possible.
- Put cross-cutting assertions, such as output or logging, on existing scenarios rather than in separate rules.

## Abstraction Heuristic

When a scenario feels long, do not shorten it mechanically. First ask what makes it long.

- If repeated steps describe an incidental journey, introduce a named business step.
  Example: replace request-link / receive-link / follow-link with `When Alice signs in with their email address` when sign-in mechanics are not the rule under test.
- If the intermediate states are the rule, keep them visible.
  Example: invitation profile completion should show that membership does not start before the invitee supplies required details.
- If one scenario proves a workflow and a domain outcome, consider splitting it into two scenarios under the appropriate rules.
- If a scenario has one action and several concrete expected outcomes, it may be fine; result-set examples can be longer when the table of outcomes is the point.

## Review Questions

- What rule does this scenario prove?
- Does the Example name add information beyond the Rule?
- Is every line essential?
- Is the data concrete and business-readable?
- Are repeated steps revealing a named domain concept that should become one higher-level step?
- Would a feature with no `Rule:` sections be clearer if its rules were extracted?
