# Problem: Feature-file creation and review are not reliably preserving exemplary Gherkin

Date: 2026-06-13

## Context

Matt observed questionable things in the project feature files and raised two concerns: the direct quality of those acceptance tests as living documentation, and the meta-level quality of the Pi skills / factory workflow that creates or reviews those feature files.

Relevant current standards include:

- `.pi/skills/bdd-formulation/SKILL.md`
- `.pi/skills/bdd-discovery/SKILL.md`
- `.pi/skills/iteration-planning/SKILL.md`

The acceptance feature files inspected for this observation are under `acceptance-tests/features/`, with production smoke examples under `smoke-tests/features/`.

## Expected standard

Feature files should be exemplary living documentation, not just executable browser tests. The `bdd-formulation` skill says scenarios should satisfy the BRIEF check: business language, real data, intention revealing, essential, and focused. It also says Memba should use commented rule headings (`# Rule: ...`) because the browser Cucumber runner accepts `Rule:`, but the Elixir/domain Cucumber parser has rejected files containing native `Rule:`.

The `iteration-planning` skill says behaviour-facing iterations should explicitly decide whether to draft/update Gherkin, should use `bdd-discovery` when rules/examples are unclear, should use `bdd-formulation` when writing or reviewing Gherkin, and should invite Matt to review acceptance feature language before treating the plan as final.

## What happened

Matt noticed feature-file quality concerns after generated or factory-assisted work had already produced feature files. A quick inspection found at least one concrete mismatch between the written standard and the current feature files:

- `.pi/skills/bdd-formulation/SKILL.md` instructs agents to use commented rule headings (`# Rule: ...`).
- Many current `acceptance-tests/features/*.feature` files use native `Rule:` headings instead.
- `docs/iterations/026-domain-cucumber-convergence/plan.md` records the reason for the standard: the Elixir Cucumber parser could not parse `Rule:` and rules were to be kept as comments.
- Later iteration plans such as `docs/iterations/029-membership-admin-invitations/plan.md` and `docs/iterations/030-verified-onboarding-requests/plan.md` still describe planned headings as `# Rule: ...`, while the committed feature files now contain `Rule:`.

The inspection also found feature files that are mostly well structured around rules and concrete examples, but with recurring review questions around scenario size, repeated sign-in choreography, UI/navigation assertions marked as `@not-domain`, and whether some examples prove one business rule or several.

## Impact

This is a quality risk rather than an immediate blocked build in this session. Weak or inconsistent feature-file review risks turning acceptance files into ordinary test scripts instead of trusted living documentation. It also risks drift between browser acceptance, domain Cucumber compatibility, iteration plans, and the BDD skills that are supposed to guide agents.

Because these files are often created during planning and then implemented by automated workflows, small formulation defects can be replicated across future iterations unless the factory catches them early.

## What allowed it to happen

The apparent system weakness is a weak review gate for Gherkin quality and standard conformance:

- The BDD formulation standard exists, but there is no obvious automated or checklist gate that catches violations such as native `Rule:` headings when the standard says to use comments.
- The iteration-planning workflow asks agents to use BDD skills, but it may not require a visible scenario-by-scenario review against BRIEF before publishing.
- Tacit judgement about what good Memba Gherkin looks like may not yet be fully captured in the skills, so agents can produce plausible-but-not-exemplary scenarios.
- The acceptance suite can pass while the feature files still fall short as living documentation or as cross-runner artifacts.

## Observations

- Matt explicitly connected the concern to both test quality and factory/skills quality.
- Current feature files use native `Rule:` headings broadly, despite the active `bdd-formulation` skill saying to use `# Rule:`.
- Existing plans show that the project has previously understood this compatibility issue, so the drift is probably a review/process failure rather than a missing idea.
- Some feature files carry `@not-domain`, `@todo-domain`, and `@todo-ui` tags, which suggests the project is already distinguishing domain examples from browser/UI/supporting examples. The standard for how those tags should affect review quality may need to be made more explicit.

## Why this matters

Feature files are part of the product's domain model and planning handoff. If they are mediocre, ambiguous, or inconsistent with the runner compatibility standard, they mislead future agents and humans. The cost compounds: implementation work optimizes against weaker examples, review becomes more subjective, and Matt has to repeatedly supply tacit BDD judgement manually.

## Open questions

- Is the `# Rule:` requirement still current, or has the Elixir/domain Cucumber parser been fixed since the skill and iteration 026 plan were written?
- Which of the questionable examples triggered Matt's concern, and what tacit review rule do they reveal?
- Should `@not-domain` scenarios be held to a different formulation standard, moved out of living-documentation feature files, or rewritten as lower-level tests?
- Should every generated/changed feature file require an explicit BRIEF review section in the plan or validation output before being accepted?

## Possible prevention ideas

- Add a feature-file review checklist or script that flags native `Rule:` headings while the standard requires `# Rule:`.
- Strengthen `bdd-formulation` with concrete Memba-specific examples of good and bad scenarios, especially around UI choreography, setup leakage, over-broad scenarios, and non-domain smoke/navigation checks.
- Add a planning/review step that asks the agent to state the rule each new/changed scenario proves and to justify that each step is essential.
- Add a lightweight audit command or validation report for `acceptance-tests/features/*.feature` that catches known smells before plans are published.
- Capture Matt's tacit examples from this review as “gold standard” and “needs rewrite” examples in the BDD skill or reference docs.
