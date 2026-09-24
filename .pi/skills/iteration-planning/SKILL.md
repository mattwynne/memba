---
name: iteration-planning
description: Interview Matt about the next product/dev iteration, turn the discussion into a focused iteration plan, publish planning artifacts, validate the plan, and ask whether this LLM session should launch the Fabro implementation-and-review delivery workflow. Use when planning the next iteration, shaping work before implementation, or preparing a plan for delivery.
---

# Iteration Planning Interview

## Overview

Help Matt turn an early idea for the next iteration into an implementation-ready iteration plan. Move from a quick interview through adversarial example mapping, collaborative domain modelling, any required ADR decisions, plan writing and validation, then ask Matt whether he wants the current LLM session to launch the Fabro delivery workflow.

<HARD-GATE>
Do NOT implement the iteration directly in the local checkout. Do NOT edit application code, migrations, step definitions, or UI. Planning may edit only iteration-planning artifacts in that iteration's `docs/iterations/` folder, acceptance feature files/scenarios that are part of planning, and ADRs plus `docs/adr/README.md` that record architecture decisions Matt explicitly made during the modelling session. Feature files and the agreed ADRs are seeds for implementation; step definitions and executable test plumbing are implementation. Never create or accept a consequential ADR autonomously. This skill's terminal state is either committed, pushed, and plan-validated planning artifacts followed by Matt's explicit choice about launching `bin/dev fabro deliver <plan_path>`; a revised plan after review feedback; or a clear explanation of why planning, publication, validation, or delivery launch was blocked.
</HARD-GATE>

## Runtime Compatibility

This skill is intended to work in both Pi and Claude Code. Claude Code is advised when the iteration needs new or changed design-system work.

- **Pi is fine** for technical/internal iterations and behaviour-facing iterations that can reference sufficient existing checked-in design sources.
- **Claude Code is advised** when the iteration adds or changes a screen, page, component, email, or visible state, because the design system lives at `claude.ai/design` and can be inspected with Claude Code's `DesignSync` tool.
- If you are not running in Claude Code and discover that new or changed design work is needed and no sufficient existing checked-in design source is available, stop before drafting, writing, committing, or validating the plan. Tell Matt the iteration should continue in Claude Code, summarize the context gathered so far, and give him a concise restart prompt. Do not skip or fake the design check.
- Only call `DesignSync` when running in Claude Code and the tool is available. In Pi or any other environment, treat `DesignSync` as unavailable and cite only checked-in design sources you actually inspected.

## Checklist

Create a task for each item and complete them in order:

1. **Explore context** — inspect relevant behaviour, code, plans, accepted ADRs, problem notes and designs only far enough to support discovery.
2. **Quick interview** — ask Matt one question at a time to establish the intended outcome, beneficiary and rough boundary. Do not prematurely turn the first description into fixed scope.
3. **Map and slice** — for behaviour-facing work, use `bdd-discovery` to map rules, examples, questions and deferred stories. For purely technical work, map the intended engineering capability, observable proof, questions, risks and deferrals instead. Aggressively look for holes and unnecessary scope before choosing architecture.
4. **Run the map ensemble** — delegate a read-only `example-map` review to the local `ensemble-review` skill, supplying the behaviour map or technical capability map as appropriate. Present its agreements, disagreements, simpler alternatives and questions to Matt. Reviewers advise; Matt decides. Revise until the intended outcome and deferrals are agreed.
5. **Formulate examples and check design** — for behaviour-facing work, use `bdd-formulation` for shared feature scenarios and apply the Design Check for visible surfaces. For purely technical work, record why Gherkin and UI design are not applicable.
6. **Run the Gherkin ensemble and agree features** — for behaviour-facing work, delegate a read-only `gherkin` review to `ensemble-review`. Return policy gaps to example mapping and formulation defects to `bdd-formulation`; do not patch either silently. Present the reviewed scenarios and design coverage to Matt and obtain his agreement before modelling. For purely technical work, confirm the capability map and proof instead.
7. **Model the domain with Matt** — use the local `domain-modelling` skill in the current planning conversation. It collaborates with Matt on concepts, lifecycle, invariants, commands, events, actors, ownership and responsibility boundaries, and drafts the plan's Domain Model section. If modelling exposes an unnecessary or unclear rule, return to example mapping rather than designing around it.
8. **Run the model ensemble and agree the model** — delegate a read-only `domain-model` review to `ensemble-review`. Bring conflicts, accidental complexity, missing invariants and ADR candidates back through `domain-modelling`; then obtain Matt's agreement on the model.
9. **Write, review and accept required ADRs** — ADRs emerge from the agreed domain model. Draft only ADRs needed for consequential decisions, including alternatives and consequences, then delegate a read-only `adr` review to `ensemble-review`. Revise findings with Matt, update `docs/adr/README.md`, and obtain Matt's explicit acceptance before implementation. Existing conflicting ADRs must be resolved with Matt, not worked around.
10. **Assemble the plan** — systematically compose the already-agreed features, design, domain model, accepted ADRs, scope/deferrals and validation. Do not add another plan-approval ceremony or introduce new decisions while assembling it.
11. **Run final ensemble review** — delegate a read-only `final-plan` review to `ensemble-review`. It checks consistency and traceability only; any substantive issue returns to the specialist skill that owns the ingredient. After correction, repeat that ingredient's ensemble review and Matt-agreement/acceptance checkpoint before assembling and reviewing the plan again.
12. **Write and publish planning artifacts** — save the plan under `docs/iterations/<iteration-number>-<topic>/plan.md`, maintain the iteration and ADR indexes, and include agreed acceptance scenarios, supporting artifacts and ADRs. Verify planning-only acceptance changes remain safely excluded or pass their targeted checks, then commit and push only the planning artifacts.
13. **Validate the published plan** — run `bin/dev fabro validate-plan <plan_path>`. Validation may check readiness and consistency but must not invent product or architecture decisions. Route any substantive issue back to its owning specialist skill, repeat that ingredient's ensemble and Matt-agreement/acceptance checkpoint, then reassemble, publish and re-run validation until ready or explicitly blocked.
14. **Ask whether to launch delivery** — do not launch automatically. After validation passes, show `bin/dev fabro deliver <plan_path>` and ask whether Matt wants this session to run it. Without explicit approval, stop.

## Process Flow

```text
Context → quick interview → example map → ensemble review → Matt agrees behaviour
  → feature formulation/design → ensemble review → Matt agrees features
  → domain-modelling skill → ensemble review → Matt agrees model
  → draft ADRs → ensemble review → Matt accepts ADRs
  → assemble plan → final consistency review → publish → validate → optional delivery launch
```

A finding moves planning back to the specialist skill that owns it. Domain modelling returns to example mapping when it exposes an unnecessary rule; Gherkin findings return to discovery or formulation; ADR findings return to ADR collaboration; final review never patches an upstream ingredient silently. A changed ingredient must pass its ensemble and Matt-agreement/acceptance checkpoint again.

## BDD Scenario Heuristics

Do not treat BDD as optional polish for behaviour-facing work. Make an explicit BDD decision during planning and write it into `## Acceptance Scenarios / Feature Files`.

Default to drafting or updating Gherkin when any of these are true:

- The iteration changes who can do what, when, or under which policy.
- The behaviour is visible to a customer, member, club operator, staff user, or support/operator persona.
- The plan contains business rules, permissions, lifecycle states, eligibility, routing, notification, pricing, privacy, or safety/trust implications.
- The examples would help Matt spot a misunderstanding before implementation.
- The behaviour needs edge-case examples to explain it clearly, such as unknown/expired/duplicate/unauthorised/error cases.
- Future agents or collaborators would benefit from stakeholder-readable executable documentation.

Use `bdd-discovery` before writing Gherkin when the rules, examples, vocabulary, questions, or slice boundaries are not yet obvious. Signals include multiple actors, several rules in one idea, policy exceptions, uncertainty about expected outcomes, or examples that reveal the iteration may need slicing.

Use `bdd-formulation` when drafting or reviewing Gherkin scenarios so feature files remain domain modelling artifacts rather than test scripts.

It is usually reasonable not to add Gherkin when the iteration is purely technical or operational and has no new user-observable rule: refactoring, dependency updates, internal performance work, logging/observability, CI/tooling, bug fixes where an existing scenario already states the intended behaviour, or implementation plumbing for a previously formulated scenario.

When deciding not to add or change feature files for a behaviour-facing iteration, write a short rationale in the plan. A good rationale names the existing scenario that already covers the rule, or explains why the behaviour is too internal/obvious for a useful stakeholder example. `Covered by ExUnit/controller tests` is not sufficient by itself for business-facing behaviour.

## Design Check

The design system (claude.ai/design) is the source of truth for design and is meant to mirror the running app (see `CLAUDE.md`). For any iteration with a user-facing surface, make an explicit design decision during planning — the way you make a BDD decision — and write it into `## Designs`.

Environment gate:

- If the iteration is purely internal or technical with no visible surface, no design-system access is needed; this skill may continue in Pi or Claude Code.
- If the iteration adds or changes a screen, page, component, email, or visible state, prefer running the planning session in Claude Code with `DesignSync` available. If it is not, use existing checked-in design sources when they are sufficient, record that `DesignSync` was not available in this session, and stop only when new or changed design work is needed and no sufficient existing checked-in design source is available.
- Do not call, mention output from, or pretend to have checked `DesignSync` outside Claude Code.

Decide three things:

1. **Does this iteration need a design?** Yes if it adds or changes a screen, page, component, email, or a visible state (empty / first-run / loading / error / success). No for purely internal or technical work (refactors, data/model changes, background jobs, infra, observability) with no visible surface — record `No design needed` and why.
2. **Do we already have it?** In Claude Code, check the design system with `DesignSync` (`list_files`, then `get_file`). In any environment, check existing checked-in design sources such as `design-system/` and `docs/specs/*` sketches for each affected surface. Reference what exists by path (e.g. a DS card `wireframes/*.html`, `ui_kits/*/index.html`, `emails/*.html`, or a sketch section). A design that is close but missing the new elements still counts as the base to extend — say so.
3. **If it's needed and missing, remind to create it.** Do not leave a user-facing surface with no referenced design and no reminder. The reminder is: mock the surface as a self-contained design-system preview, render-verify it (headless render), and push it to the DS via `DesignSync` in Claude Code — done before implementation where possible. If the iteration is already building, record it as a **fast-follow** design to align the in-flight build/review to.

Write the outcome in `## Designs`: for each affected surface, the design that covers it (with path) or the reminder to create one. When a feature spans several iterations, design the **final** version once and note which elements earlier slices omit, rather than a separate design per slice. Default to "needs a design" whenever the iteration changes anything a user sees; `No design needed` is for genuinely invisible technical work.

## Interview Guidance

Ask only one question per message. Prefer multiple choice when it lowers effort, but use open questions when needed. When asking a multiple-choice question, use the `question` tool rather than writing A/B/C/D options in prose. Use normal chat only for open-ended questions or when the tool cannot express the choice clearly.

Before or during early brainstorming, inspect `docs/problems/README.md` and relevant `docs/problems/*.md` files. Use them to ask whether the iteration should resolve, partially address, or deliberately defer any captured problems. If Matt's idea resembles an unresolved or partially addressed problem, name that problem explicitly and ask how tightly the iteration should target it.

Cover these topics:

- **Goal** — what should be true after the iteration that is not true now?
- **Related problems** — which `docs/problems` notes does this iteration address, partially address, depend on, or leave unresolved?
- **Beneficiary** — who benefits: club admin, member, developer/operator, or another actor?
- **Smallest useful slice** — is this one rule or one piece of engineering, or several? (see Sizing and Slicing)
- **Scope boundaries** — what is explicitly out of scope?
- **Acceptance criteria** — concrete behaviours, examples, edge cases, permissions, and error states.
- **Business decisions** — domain, policy, copy, workflow, pricing, privacy, or support questions.
- **Technical shape** — likely modules, data, events/commands, integrations, UI, background work, and migration concerns.
- **Design** — does this iteration touch a screen, page, component, email, or visible state? If so, prefer Claude Code and `DesignSync`; when this session is not Claude Code, check existing checked-in design sources and stop only if new or changed design work is needed without a sufficient existing design source. Also check whether there is an existing sketch. (see Design Check)
- **Validation** — automated tests, acceptance tests, shared Cucumber scenarios, manual demo, stakeholder review, or operational checks.

The quick interview stops when there is enough shared context to begin example mapping, not when the plan is already specified. Discovery and modelling continue until the plan can be written without an implementor inventing material product, domain-model or architecture decisions.

## Sizing and Slicing

An iteration should be **one shippable slice**: either one behaviour rule, or
one piece of engineering. Before drafting the plan, check the size and split
if needed.

- **Classify the work.** Is it behaviour-facing (changes what a user can
  observe) or technical/engineering (enables or restructures, with no new
  user-observable behaviour)?
- **Find the seams.** For behaviour-facing work, each Rule from example
  mapping is normally its own shippable slice, with that rule's examples as
  the slice's acceptance scenarios. For technical work, slice by capability.
- **Foundation first.** When behaviour needs architecture that does not exist
  yet (e.g. an event store before the first message can be sent), make that
  enabling architecture its own earlier technical iteration.
- **Split when it is more than one slice.** If the work spans several rules or
  bundles new architecture with behaviour, write it as several iteration
  plans, each independently shippable, rather than one big plan. A good slice
  leaves the build green with strictly more scenarios passing — or, for a
  technical slice, the same scenarios but a proven capability.

If you split a plan, replace it with the child plans (no parent/epic doc) and
number them sequentially before any of them is implemented.

Worked example: the original "member message deliverability" plan bundled the
whole event-sourced stack, two contexts, and all delivery statuses into 18
tasks, and repeatedly failed to implement. It was split into four shippable
iterations — `001` event-sourced foundation (technical), then `002`
membership, `003` messaging, `004` statuses and views (one rule each). See
`docs/iterations/`.

## Plan Format

Write the plan as Markdown with these sections:

```markdown
# <Iteration title>

Date: YYYY-MM-DD
Status: draft | ready | needs-revision

## Goal

## Background / Context

## Related Problems

List relevant `docs/problems` notes. For each one, state whether this iteration is expected to resolve it, partially address it, depend on it, or leave it unresolved. If none are relevant, write `None known.`

## Scope

### In scope

### Out of scope

## Iteration Type

Behaviour-facing or technical/engineering. For behaviour-facing iterations, identify the user-observable rule or policy changed. For technical iterations, state why there is no new user-observable behaviour.

## Acceptance Scenarios / Feature Files

State the BDD decision: `Required`, `Useful but not required`, or `Not useful for this slice`. For behaviour-facing iterations, name the shared Cucumber feature file(s) and scenarios that will express the business rules, or state why Gherkin would not add useful stakeholder-readable examples for this slice. For technical iterations, write `Not applicable` and the reason. If implementation is allowed to edit `.feature` files, also include a separate `## Allowed acceptance feature changes` section naming each exact file, the allowed kind of change, the reason, and how coverage is preserved or intentionally changed.

## Designs

Apply the Design Check. For each user-facing surface the iteration adds or changes, name the design that covers it (a design-system card or a `docs/specs` sketch, by path), or note that no design exists yet and must be created in Claude Code (a reminder to mock + render-verify + push to the DS there; mark it a fast-follow if the iteration is already building). Write `No design needed` with a reason for purely internal/technical iterations.

## Acceptance Criteria

## Open Business Decisions

## Domain Model

Document the agreed concepts and vocabulary, lifecycle/state changes, invariants, commands, events, actors, aggregate/context ownership, responsibility boundaries, important temporal examples, changes from the current model, and deliberately deferred modelling questions.

## Architecture Decisions

Link the accepted ADRs produced or confirmed during planning. State `None required` when the agreed model introduces no consequential architecture decision. Never use this section to defer an ADR decision to implementation.

## Implementation Plan

## Open Technical Decisions

## New Capability

What we expect to be able to do once this is done that we could not do before.

## Validation Plan

How we will validate that we have been successful.

## Risks / Follow-ups
```

Keep plans focused. If a section has no open decisions, write `None known.` rather than omitting it.

## Writing the Plan

- Create `docs/iterations/` if it does not exist.
- Maintain `docs/iterations/README.md` as the iteration index.
- Read `docs/problems/README.md` if it exists, plus any relevant `docs/problems/*.md` notes. If the directory exists but no README exists, inspect the problem files directly.
- Include a `## Related Problems` section in the plan. Link each relevant problem note and say whether the iteration should resolve it, partially address it, depend on it, or intentionally leave it unresolved. If there are no relevant captured problems, write `None known.`
- Include `## Domain Model` and `## Architecture Decisions`. The domain model records the decisions agreed with Matt during modelling; it is not a placeholder for the implementor to design later. Link every required accepted ADR, and do not mark a consequential architecture decision resolved unless Matt participated in and accepted it.
- Create one folder per iteration using the next sequential zero-padded iteration number and a lowercase hyphenated topic slug.
- Determine the next number by inspecting existing `docs/iterations/NNN-*` folders; start at `001` if none exist.
- Save the plan as `plan.md` inside that folder.
- Put supporting planning artifacts for the same iteration in the same folder, such as `manual-demo-script.md` or `validation-notes.md`.
- Classify the iteration in the plan as behaviour-facing or technical/engineering. For behaviour-facing iterations, fill in `## Acceptance Scenarios / Feature Files` with a BDD decision of `Required`, `Useful but not required`, or `Not useful for this slice`, plus either the feature file(s)/scenario summaries that express the business rules or an explicit rationale for why Gherkin would not add useful stakeholder-readable examples. Do not rely on low-level ExUnit/controller tests as a substitute for this BDD decision.
- Apply the BDD scenario heuristics above before deciding. If two or more “default to Gherkin” signals apply, draft scenarios unless Matt explicitly decides otherwise.
- Draft or update shared Cucumber feature files/scenarios when they clarify the iteration's domain behaviour. Use `bdd-discovery` first if the rules/examples are unclear, and `bdd-formulation` when writing or reviewing the Gherkin. Keep scenarios abstract from test infrastructure: no CSS selectors, route names, button-click choreography, database setup, or adapter configuration.
- Include a `## Designs` section and apply the Design Check: for each user-facing surface, reference an existing design (a design-system card or a sketch, by path — check the DS with `DesignSync` only in Claude Code, otherwise cite checked-in design sources you inspected) or record a reminder to create one (mock + render-verify + push to the DS in Claude Code, or a fast-follow if already building). If new or changed design work is needed and no sufficient existing checked-in design source is available, stop and hand off instead of continuing. Write `No design needed` with a reason for internal/technical iterations. Design the final version once for multi-iteration features and note what earlier slices omit. Do not author the design during ordinary planning unless Matt asks — the planning deliverable is the decision and the reminder, not the mock.
- Tag every scenario created or changed during planning with the iteration tag `@iteration-NNN`, where `NNN` is the zero-padded iteration number. If every scenario in a new or changed feature belongs to that iteration, a feature-level `@iteration-NNN` tag is acceptable. Do not remove older iteration tags from existing scenarios; multiple iteration tags are allowed and useful when a scenario evolves across iterations.
- Preserve a green mainline while planning. Existing executable scenarios should keep passing. If planning deliberately rewrites or adds scenarios that describe future behaviour and would fail before implementation catches up, tag each affected scenario with the project’s runner-debt tags: `@todo-domain` when domain support is pending, and `@todo-ui` when browser support is pending. If every scenario in a changed feature has the same pending runner support, feature-level tags are acceptable. Prefer scenario-level tags when only part of a feature is unfinished. Do not leave untagged future-facing scenarios that make `dev check` fail.
- When feature files/scenarios are created or changed, show Matt the feature file path, which scenarios are tagged with `@iteration-NNN`, which have `@todo-domain` and/or `@todo-ui`, and a concise summary of the scenarios. Explicitly ask him to review the language/examples before treating the plan as final.
- Before publishing, run `dev check` when practical. If it is too slow, run the targeted checks that discover/execute the changed acceptance feature files. If the check fails because a future-facing scenario is unimplemented, add or narrow the relevant `@todo-domain` and/or `@todo-ui` tags rather than editing step definitions or app code. If the project does not configure those tags to exclude the pending scenario from the relevant runner, stop and report that the planning change would make the build red instead of committing it.
- Do not implement step definitions, fixtures, app code, migrations, UI, or test adapters during planning.
- Add or update the index entry in `docs/iterations/README.md` with the iteration number, title/topic, plan link, date, status, and any acceptance feature files changed.
- Do not update Fabro workflow code or problem-note status files during ordinary iteration planning. The relevant problems belong in the plan's `## Related Problems` section. Only edit `docs/problems/*.md` or `docs/problems/README.md` if Matt explicitly asks for problem-note maintenance as part of the planning task.
- Example: `docs/iterations/001-member-import/plan.md`.
- Commit and push the plan, iteration index, supporting planning artifacts, acceptance feature files, ADRs explicitly accepted by Matt, and `docs/adr/README.md` before running Fabro validation so the clone-based remote sandbox can see them. Do this only after the acceptance files are either still executable and green, or carry the relevant `@todo-domain` and/or `@todo-ui` tags and are excluded from the planning-time checks. Then run `bin/dev fabro validate-plan <plan_path>` and use the feedback to revise the plan before asking Matt about delivery.
- Include workflow/skill changes in that commit only when they are needed for planning or validation.
- Do not commit or push unrelated changes or implementation work.

## Validating and Optionally Launching Fabro Delivery

After committing and pushing the planning artifacts, run plan validation before asking about delivery:

```bash
bin/dev fabro validate-plan docs/iterations/NNN-topic/plan.md
```

The workflow runs in clone-based remote sandboxes; pushed artifacts are required so Fabro can read newly-created plans and acceptance feature files. Do not ask Matt whether to launch delivery until validation has passed. If validation is unavailable, report the blocker and the retry command instead of asking to launch delivery.

If validation reports NOT READY:

1. Summarize the blocking gaps.
2. Ask Matt one question at a time to resolve them.
3. Return each substantive issue to its owning specialist skill, repeat that ingredient's ensemble and Matt-agreement/acceptance checkpoint, then edit, commit, and push the affected planning artifacts. Acceptance scenarios or ADRs may change only through the same Matt-reviewed discovery/modelling decisions required above.
4. Re-run `bin/dev fabro validate-plan <plan_path>`.
5. Repeat until validation reports ready or validation is blocked by an unavailable local Fabro service or another explicit external blocker.

After validation passes, do not wrap delivery in another skill or workflow. Ask Matt whether he wants this LLM session to run the user-controlled delivery command now. Use the `question` tool when available with choices equivalent to:

- Yes — run implementation and review now.
- No — stop after handing off the command.

Always show the exact command:

```bash
bin/dev fabro deliver docs/iterations/NNN-topic/plan.md
```

This command reserves the implementation WIP slot, runs implementation, and runs review from the CLI with `--auto-approve` at the user-approved boundary. If Matt says yes, run the command and report the initial result. If Matt says no or does not explicitly approve, do not run it.

If the local Fabro server is unavailable or the command fails before creating a run:

1. Report the exact error.
2. Do not treat the plan as validated.
3. Tell Matt the plan file path and the exact command to retry.

When planning is complete, report:

1. Plan path.
2. Commit SHA pushed.
3. Plan validation command and result.
4. Related problems named in the plan, including any that remain unresolved or partially addressed.
5. Any acceptance feature files changed, their `@iteration-NNN` tags, and their `@todo-domain` / `@todo-ui` runner-debt tags.
6. Matt's delivery-launch choice.
7. Exact delivery command: `bin/dev fabro deliver <plan_path>`.

## Key Principles

- One question at a time.
- Example-map and defer before modelling; agree formulated features before modelling; model before writing ADRs; accept ADRs before implementation.
- Compose planning from the `bdd-discovery`, `bdd-formulation`, `domain-modelling`, and `ensemble-review` skills rather than duplicating their specialist procedures.
- Ensemble reviewers challenge and advise; Matt agrees behaviour, formulated features, domain models and ADRs. The assembled plan needs no separate approval ceremony.
- One iteration is one slice: one rule, or one piece of engineering. Split anything bigger.
- Make business decisions explicit.
- Document the agreed domain model systematically rather than leaving commands, events, invariants or ownership for implementation to invent.
- Make technical decisions explicit enough to start.
- Make acceptance criteria testable.
- Make validation observable.
- If a user sees it, it needs a design: check the design system for an existing one, and if it is missing, record a reminder to create it (fast-follow if already building).
- Do not implement locally during this skill; `bin/dev fabro deliver` owns implementation after Matt explicitly approves launching it or runs it himself.
