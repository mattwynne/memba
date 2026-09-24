---
name: bdd-discovery
description: Use before writing Gherkin when exploring a story's behaviour, rules, examples, questions, scope, or readiness with stakeholders
---

# BDD Discovery

Discovery is the conversation before formulation. Use it to build
shared understanding of a story: the rules, examples, questions, and
scope boundaries that matter.

For writing or refining Gherkin, use `bdd-formulation`.

## Example Mapping

Map one story with the Three Amigos perspectives: product, development,
and testing. Keep it small, low-tech, and time-boxed.

The goal is the simplest set of rules that is good enough for now, while
being thorough about achieving shared understanding everything that remains in scope:

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

## How to Run It

1. Start with the story and the rules people already know.
2. Ask for concrete examples for each rule.
3. Put each example under the rule it illustrates.
4. Capture uncertainty as questions; do not solve everything in the room.
5. Challenge whether each rule describes a needed outcome or assumes a
   mechanism. Remove, weaken, or defer rules that are not needed now.
6. Probe boundaries, transitions, reversals, failure paths, and interactions
   for the behaviour that remains in scope.
7. Capture tangents or large discoveries as new stories.
8. Before declaring the story ready, run the bounded Three Amigos review
   below.
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

## Bounded Three Amigos Review

Near the end of discovery, run one adversarial review round. Give the current
map and its source constraints to three subagents in parallel, one for each
lens:

- **Product/business**: challenge the present value of every rule, distinguish
  outcomes from mechanisms, and suggest rules to remove, weaken, or defer.
- **Development**: look for missed lifecycle, state, timing, integration,
  ownership, and cross-context consequences; flag disproportionate complexity.
- **Testing**: aggressively seek counterexamples, boundaries, reversals,
  failure paths, and rule interactions within the retained scope.

Ask each reviewer for concise questions, examples, alternatives, assumptions,
and evidence. They must not rewrite the map or make product decisions.
Synthesize their findings into:

- missed cases and assumptions;
- possible removals or simpler slices;
- agreements and disagreements; and
- material trade-offs for the stakeholder to decide.

This is one review round, not an automatic revision loop. Subagents supply the
Three Amigos perspectives; they do not replace stakeholder judgment or prove
that every unknown unknown has been found.

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
