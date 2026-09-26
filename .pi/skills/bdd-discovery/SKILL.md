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

1. Start the live Three Amigos collaboration below.
2. Start with the story and the rules people already know.
3. Ask for concrete examples for each rule.
4. Record each example under the rule it illustrates in the Gherkin skeleton.
5. Capture uncertainty as questions; do not solve everything in the room.
6. Challenge whether each rule describes a needed outcome or assumes a
   mechanism. Remove, weaken, or defer rules that are not needed now.
7. Probe boundaries, transitions, reversals, failure paths, and interactions
   for the behaviour that remains in scope.
8. Capture tangents or large discoveries as new stories.
9. Wake the collaborators at natural pauses as rules and examples become concrete.
10. Stop when the story is clear enough to formulate, or the time-box expires.

## Discovery Habits

- Prefer conversation over documents.
- Use domain language, not implementation details.
- Talk about behaviour as if it could be handled manually.
- Keep examples rough but concrete: real names, amounts, states, dates.
- Treat red cards as progress: unknown unknowns became known unknowns.
- Let rules and examples reveal better story slices.
- Seek both minimality and completeness: take away accidental scope without
  leaving retained behaviour underexplored.

## Live Three Amigos Collaboration

Invoke `agent-collaboration` at the start of mapping with three persistent, read-only roles:

1. **Product/business** — keep asking whether a rule has present value, whether it describes an outcome or assumes a mechanism, and what can be removed, weakened, or deferred to make this the smallest useful coherent slice.
2. **Development** — look for lifecycle, state, timing, integration, ownership, and cross-context consequences that expose ambiguity or disproportionate complexity.
3. **Testing** — offer concrete counterexamples around boundaries, reversals, failure paths, ordering, and interactions among retained rules.

The shared artifacts are the facilitator conversation, current map, red questions, sliced-out stories, source evidence, and agreed constraints. An observation is significant only when a concrete question, counterexample, contradiction, or simpler alternative could materially change shared understanding. Reviewers must not edit artifacts, decide policy, accept scope, or turn optional ideas into requirements.

In BB, let collaborators inspect the actual facilitator timeline incrementally. In standalone Pi, send them verbatim new turns at the same natural pauses. The facilitator filters and introduces significant observations while mapping is still in progress, then returns Matt's decisions and deferrals to collaborators. Do not make the agents debate until they agree.

Keep these collaborators alive when moving into `bdd-formulation`; formulation continues the same conversation rather than launching a post-hoc review panel. Before leaving discovery, request one catch-up through the latest conversation event and process any outstanding significant observations. This completes the discovery phase of the live collaboration; it is not a separate artifact review.

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
  decided by collaborators.
- The live collaborators have caught up through the latest discovery decision;
  their handles are available to continue into formulation.

## Source

- Cucumber: “Example Mapping” (cucumber.io/docs/bdd/example-mapping/)
