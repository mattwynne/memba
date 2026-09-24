---
name: bdd-discovery
description: Use before formulating Gherkin scenarios when exploring a story's behaviour, rules, examples, questions, scope, or readiness with stakeholders
---

# BDD Discovery

Discovery is the conversation before formulation. Use it to build
shared understanding of a story: the rules, examples, questions, and
scope boundaries that matter.

Discovery may record a lightweight Gherkin skeleton of names. For formulating
or refining full scenarios and their steps, use `bdd-formulation`.

## Example Mapping

Map one story with the Three Amigos perspectives: product, development,
and testing. Keep it small, low-tech, and time-boxed.

The goal is the simplest set of rules that is good enough for now, while
being thorough about achieving shared understanding of everything that remains in scope:

> “Perfection is achieved, not when there is nothing more to add, but when
> there is nothing left to take away.”

Remove or defer rules that current needs do not justify. At the same time,
aggressively hunt for missed edge cases and unknown unknowns. Small means
consciously sliced, not superficially explored.

Cards:

- **Story**: the work under discussion.
- **Rules**: business rules, constraints, policies, or acceptance criteria.
- **Examples**: concrete cases that illustrate one rule.
- **Questions**: unknowns, assumptions, missing decisions, or research.
- **New stories**: behaviour discovered but sliced out of scope.

Traditional colours: yellow story, blue rules, green examples, red questions.

## Record the Map

Record the map as a lightweight Gherkin skeleton using keyword and name only:

```gherkin
Feature: Withdraw cash

  Rule: The account must have enough funds

    Example: Withdrawal is within the available balance

    Example: Withdrawal exceeds the available balance
```

Use `Feature:` for the story, `Rule:` for each rule, and `Example:` for each
concrete example. Keep questions and sliced-out new stories alongside the
skeleton as lists. Do not add `Given`/`When`/`Then` steps during discovery;
that belongs in `bdd-formulation`.

## How to Run It

1. Start with the story and the rules people already know.
2. Ask for concrete examples for each rule.
3. Record each example under the rule it illustrates in the Gherkin skeleton.
4. Capture uncertainty as questions; do not solve everything in the room.
5. Challenge whether each rule describes a needed outcome or assumes a
   mechanism. Remove, weaken, or defer rules that are not needed now.
6. Probe boundaries, transitions, reversals, failure paths, and interactions
   for the behaviour that remains in scope.
7. Capture tangents or large discoveries as new stories.
8. Before declaring the story ready, run the bounded adversarial review
   below using the Three Amigos lenses.
9. Stop when the story is clear enough to pull, or the time-box expires.

## Discovery Habits

- Prefer conversation over documents.
- Use domain language, not implementation details.
- Talk about behaviour as if it could be handled manually.
- Keep examples rough but concrete: real names, amounts, states, dates.
- Treat red cards as progress: unknown unknowns became known unknowns.
- Let rules and examples reveal better story slices.
- Seek both minimality and completeness: take away accidental scope without
  leaving retained behaviour underexplored.

## Bounded Adversarial Review

Near the end of discovery, run one adversarial review round using the Three
Amigos lenses. Give the current map and its source constraints to three
subagents in parallel, one for each lens:

- **Product/business**: challenge the present value of every rule, distinguish
  outcomes from mechanisms, and suggest rules to remove, weaken, or defer.
- **Development**: look for missed lifecycle, state, timing, integration,
  ownership, and cross-context consequences; flag disproportionate complexity.
- **Testing**: aggressively seek counterexamples, boundaries, reversals,
  failure paths, and rule interactions within the retained scope.

Ask each reviewer for only its highest-value questions, examples,
alternatives, assumptions, and evidence. They must not rewrite the map or make
product decisions. Synthesize their findings into:

- missed cases and assumptions;
- possible removals or simpler slices;
- agreements and disagreements; and
- trade-offs for the stakeholder and team to decide.

The synthesizer presents findings and alternatives without changing agreed
rules or scope. The stakeholder and team decide before the map is updated or
the story is declared ready.

This is one review round, not an automatic revision loop: do not respawn or
iterate reviewers automatically. The subagents apply the Three Amigos lenses;
they do not replace the collaborative Three Amigos conversation, stakeholder
judgment, or prove that every unknown unknown has been found.

## Reading the Map

- Many red cards: too much uncertainty; research or invite the right person.
- Many blue cards: story may be too broad or complex.
- Many green cards under one rule: the rule may hide smaller rules.
- New story cards: useful scope control, not failure.

## Ready for Formulation?

Move to `bdd-formulation` when:

- The team agrees what problem the story solves.
- Key rules are visible, and each is justified by a current outcome.
- The retained scope has been probed for edge cases and unknown unknowns.
- Risky or unclear rules have concrete examples.
- Open questions are captured and owned.
- Unneeded behaviour is removed or explicitly sliced out.
- Material trade-offs remain with the stakeholder rather than being silently
  decided by reviewers.

## Source

- Cucumber: “Example Mapping” (cucumber.io/docs/bdd/example-mapping/)
