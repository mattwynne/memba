# Problem: BDD discovery did not challenge a costly business rule before iteration planning

Date: 2026-09-23

## Context

Iteration 064 planned custom-group leave/removal in [`docs/iterations/064-leave-and-remove-group-members/plan.md`](../iterations/064-leave-and-remove-group-members/plan.md). Its original accepted behaviour said that leaving must clear conversation follows and that rejoining must not restore them.

Implementation and review then tried to distinguish old follows, delayed follow work, removal, re-addition and genuinely new follows. The retained recovery evidence records seven revisions of the same follow-cleanup task. The later factory retrospective records 16 failed iteration-064 runs, 7.63 run-hours and $273.66 API-equivalent cost in the full sequence: [`docs/notes/2026-09-21-software-factory-retrospective.md`](../notes/2026-09-21-software-factory-retrospective.md).

Matt and the planning agent subsequently returned to BDD discovery and simplified the product model:

- follow preferences survive absence;
- no email deliveries are created for messages posted while the person is absent;
- rejoining creates no backlog;
- future messages resume the preserved preference;
- recipients are fixed when a message is posted, so queued deliveries are not cancelled;
- provider crash handling is outside this slice;
- the current scope is one conversation belonging to one group.

This separates a person's notification preference from current eligibility and from an already-created delivery. It removes the business requirement that drove most of the attempted follow-cleanup architecture.

## Expected standard

The [`bdd-discovery` skill](../../.pi/skills/bdd-discovery/SKILL.md) should help Matt and agents reach the simplest adequate behaviour before an iteration plan fixes scope or implementation begins. Example mapping should not only add examples within an assumed rule. It should challenge whether the rule matters, seek counterexamples, expose independent policy dimensions, and turn avoidable complexity into questions or deferred stories.

After the behaviour model is agreed, iteration planning should include a collaborative domain-modelling session with Matt covering concepts, lifecycle, commands, events, invariants and ownership. Consequential ADRs should record decisions made with Matt rather than being created autonomously during implementation.

## What happened

The original examples explored many consequences of the rule that leaving clears follows, but discovery did not adversarially examine the rule itself. In particular, it did not clearly separate:

- whether the follow preference is deleted or merely inactive;
- when email eligibility is decided;
- whether absence creates a backlog;
- whether already-queued delivery work is cancelled;
- whether multi-group conversation authorization is in scope; or
- whether provider failure semantics belong in the iteration.

The iteration plan and its validators treated safe remove/re-add ordering as bounded implementation detail. Implementation review correctly found successive ordering defects, but the workflow continued trying to implement the costly rule rather than returning to product discovery and asking whether the guarantee was needed.

## Impact

This created avoidable architecture, rework and review cost before the product rule was simplified. It also reduced Matt's control over domain and ADR decisions: approval of stakeholder-visible behaviour was treated as permission for agents to select consequential domain architecture later.

The risk is broader than iteration 064. A plausible example map can appear thorough while all examples inherit the same unnecessary assumption. More examples then deepen commitment to the assumption instead of testing its value.

## What allowed it to happen

- The current `bdd-discovery` skill encourages questions and slicing but does not require an adversarial challenge to each important rule.
- Example mapping has no explicit pass for simpler alternative rules, counterexamples, or separation of preference, eligibility, decision timing and side effects.
- Planning can move from approved examples to implementation shape without a structured domain-modelling session with Matt.
- Plan validation checks whether rules and decisions are explicit, but explicitness can make an unnecessarily strong rule look ready.
- When implementation reveals disproportionate complexity, the delivery loop has no strong route back to BDD discovery to reopen the business model.

## Observations

- The old rule was explicitly reviewed, so this was not an implementor ignoring product direction. The missing protection was a cost-informed challenge before that direction became fixed scope.
- The later simplified rules preserve the core product outcome—no emails while absent and no backlog—without destroying the underlying preference.
- The original plan itself contained warning signals: asynchronous cleanup, delayed work, re-addition, automatic and manual follows, replay, queued deliveries and two bounded contexts.
- The existing [`feature-file quality` kaizen](2026-06-13-feature-file-quality-review-gap.md) concerns formulation and living-documentation quality. This observation is different: well-written examples can still share an unchallenged, unnecessarily expensive rule.

## Why this matters

Business-rule simplification has much greater leverage before implementation than architectural simplification after implementation. If discovery does not challenge the model, implementation agents can spend substantial effort correctly solving a problem the product does not need.

It also matters for governance. Commands, events and domain-model changes are consequential decisions. Matt wants to participate in the modelling session and remain in the driving seat when an ADR is decided.

## Open questions

- What adversarial roles or questions reliably challenge a map without turning discovery into a long review ceremony?
- When should adversarial subagents run: after an initial map, after Matt answers open questions, or both?
- How should their disagreements be presented so Matt decides rather than the synthesis agent silently choosing?
- What should trigger the subsequent collaborative domain-modelling session?
- How should the plan document concepts, commands, events, invariants, ownership, temporal examples and required ADR decisions without prematurely designing implementation details?
- When technical reconnaissance exposes high cost, how should planning return to example mapping rather than optimize the existing rule?

### Evaluation realism

Iteration 064 could be a useful regression fixture by replaying only the information available before implementation and checking whether discovery raises the missing policy questions. It cannot by itself prove that the skill works in realistic planning:

- a fixture derived from a known failure risks teaching the expected answer;
- a rubric can reward keywords such as “preference” or “backlog” without measuring whether the conversation helped Matt;
- scripted stakeholder responses do not reproduce a live, evolving discussion;
- adversarial subagents using related models may share the same assumptions;
- success on one historical case may overfit iteration 064.

Open evaluation questions include whether to use blinded pre-implementation artifacts, alternative stakeholder answers, unrelated lifecycle examples, deliberately misleading maps, human review by Matt, and prospective shadow use in real planning sessions. Automated evals may demonstrate specific discovery behaviours, but realistic usefulness may require human-rated or prospective evidence.

## Possible prevention ideas

- Add an adversarial subagent review loop to `bdd-discovery` that challenges rule value, missing examples and scope before formulation.
- Require the review to produce questions and simpler alternatives, not silently rewrite the map or decide for Matt.
- Follow the agreed example map with a collaborative domain-modelling session covering concepts, commands, events, invariants and context ownership.
- Record the agreed domain model systematically in the iteration plan and require Matt's involvement before accepting consequential ADRs.
- Use iteration 064 as one retrospective eval fixture while explicitly treating eval realism and overfitting as unresolved, and supplement it with unrelated cases and human evidence before claiming effectiveness.

## Resolution

Date: 2026-09-24

Root cause: Example mapping encouraged concrete examples and slicing, but did not make simplification an explicit goal or require an adversarial challenge before readiness. A map could therefore thoroughly explain the consequences of an assumed rule without asking whether that rule or its mechanism was needed.

Fix applied:

- `.pi/skills/bdd-discovery/SKILL.md`: made the goal the simplest rule set that is good enough for now while thoroughly exploring retained scope; added outcome-versus-mechanism challenges and one bounded parallel adversarial review using the product, development, and testing Three Amigos lenses.
- The skill now records the map as a lightweight Gherkin skeleton using `Feature:`, `Rule:`, and `Example:` names. Questions and sliced stories remain alongside it as lists, while scenario steps stay in `bdd-formulation`.
- The review returns missed cases, possible removals, disagreements, and trade-offs without changing agreed rules or scope. The stakeholder and team retain the decisions, and the review does not loop automatically.

Validation:

- `git diff --check` — passed.
- `python3 scripts/check_kaizen_ledger.py` — passed.
- Independent review found the simplicity/thoroughness balance, generic framing, one-round bound, and lack of iteration-064-specific answers sound. Its blocking stakeholder-ownership ambiguity was corrected by constraining the synthesizer as well as the reviewers.
- Follow-up independent review confirmed that native `Rule:` and zero-step `Example:` skeletons are accepted by the project's browser and Elixir Gherkin parsers. Its blocking discovery/formulation wording conflict was corrected by distinguishing the discovery skeleton from scenario and step formulation.
- `dev check` was not run because this is a skill/documentation-only change with no executable examples.

Effectiveness and follow-up:

- This validates that the agreed instruction is present; it does not demonstrate better real-world discovery outcomes.
- Iteration 064 supplied causal evidence but is contaminated by hindsight and was not used as an effectiveness test. Passing a replay could reward known words or answers rather than useful discovery.
- No blinded unrelated case, live stakeholder session, or prospective planning sample has yet measured useful questions, false challenges, decision burden, or material simplification. Related-model subagents also do not provide fully independent evidence.
- Keep this note open for representative unrelated or prospective evidence. Do not start a second experiment while the ledger's current experiment occupies the WIP limit.
