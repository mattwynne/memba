---
name: bdd-formulation
description: Write or review Gherkin scenarios after discovery, using Memba's agreed problem-domain vocabulary and concrete examples of business rules.
---

# BDD Formulation

Formulation is the craft of writing Gherkin that serves as
living documentation. Good scenarios are concrete examples
of business rules, not test scripts.

When formulation follows `bdd-discovery`, continue its existing Three Amigos collaboration through `agent-collaboration`. Do not replace the live collaborators with a post-hoc review panel.

## Core Habit

When examples reveal a rule, make the rule visible in the
feature file: group related scenarios under a rule heading that
states the rule they illustrate.

In Memba, use the native Gherkin `Rule:` keyword for rule headings.
Both the browser Cucumber runner and the Elixir/domain Cucumber parser
support it now, so commented rule headings are no longer needed.

## Naming Checkpoint

Names are part of formulation, not cosmetic cleanup after modelling. Read `docs/problem-domain-terms.md`, extract the important nouns and verbs from the example map, and invoke `domain-vocabulary` with those terms and their concrete examples. Use its output to apply canonical problem-domain terms consistently in `Feature`, `Rule`, `Example`, and step wording. Keep solution mechanisms out of scenarios unless the mechanism itself is agreed observable behaviour.

Do not treat a proposed addition, replacement, or changed meaning as accepted until Matt agrees through `domain-vocabulary`. Apply accepted lexicon changes to the scenarios; keep unresolved naming questions explicit. Return the formulated scenarios with the vocabulary record produced by that skill.

```gherkin
Rule: Manual blockers replace the existing manual blocker

  Scenario: Adding another manual blocker updates the reason
    Given I add the yak "deploy"
    And I add manual blocker to "deploy" with reason "waiting on vendor"
    When I add manual blocker to "deploy" with reason "waiting on review"
    Then the JSON yak "deploy" should have exactly one manual blocker with reason "waiting on review"
```

## Temporal Formulation

Use concrete `Given`/`When`/`Then` sequences to make **when** a rule applies visible. Formulation should expose temporal policy, not merely restate outcomes.

For any behaviour whose outcome may depend on sequence or time—such as changing eligibility, preferences, permissions, lifecycle state, scheduled work, or asynchronous effects—ask:

- What relevant state existed before the action?
- At what action or event is the decision made?
- Does a later state change alter an already-made decision or only future decisions?
- What happens while someone or something is temporarily absent, inactive, pending, or in transition?
- What resumes, persists, expires, queues, or is deliberately not backfilled?
- Which ordering of otherwise valid actions changes the outcome?
- What boundary examples just before, during, and after the transition distinguish the rule?

Write the smallest scenarios that reveal these distinctions. Keep business-significant ordering explicit, but avoid clocks, queues, jobs, database state, and other implementation timing unless stakeholders actually observe them. If concrete sequencing reveals a missing or unnecessarily expensive rule, return it to discovery and Matt rather than encoding an accidental policy in Gherkin.

## Collaborate While Formulating

Wake the existing Product/business, Development, and Testing collaborators at natural pauses when a scenario makes a rule, name, decision point, ordering, or boundary concrete. Let them inspect the actual facilitator conversation in BB; in standalone Pi, send the new turns verbatim. Ask for only significant evidence-backed questions or counterexamples that could change shared understanding.

Use their roles continuously:

- **Product/business** challenges whether the scenario preserves the smallest valuable rule rather than smuggling deferred policy back in.
- **Development** flags domain distinctions, timing assumptions, or responsibility consequences that need clarification before modelling.
- **Testing** proposes concrete counterexamples and boundary sequences that reveal what the rule actually means.

The facilitator deduplicates and filters observations, brings Matt only questions requiring domain knowledge or a consequential decision, and records his answers in the scenarios, vocabulary record, map, or deferrals. Collaborators advise; they do not edit the feature, decide wording or policy, or require unanimity.

Before formulation is treated as agreed, give each available collaborator one final catch-up through the latest conversation event, process outstanding significant observations, and disclose any degraded participation. Then end the collaboration unless the caller explicitly needs the same team for another conversational activity. This boundary catch-up is not a separate ensemble review.

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
- Do its nouns and verbs match `docs/problem-domain-terms.md`?
- Is any solution-domain mechanism masquerading as stakeholder language?
- Does any proposed vocabulary change still need Matt's agreement?
- Is the rule's decision point clear: what was true before, what action happens, and when the outcome becomes fixed?
- Could a later state change affect past/queued work, only future work, or neither—and do examples make that policy explicit?
- Are important orderings, temporary states, persistence, expiry, resumption, and no-backfill cases concrete without leaking implementation mechanics?

If later domain modelling finds that a command, event, or invariant has a more natural problem-domain noun or verb, reopen formulation through `domain-vocabulary`; update the agreed scenarios and lexicon before treating the model term as settled. A later bounded correction may use fresh collaborators if useful, but does not require recreating the original live team or running a post-hoc ensemble.
