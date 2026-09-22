# Problem: Auth iteration planning missed BDD scenarios

Date: 2026-05-31

## Context

We delivered iteration 010, `docs/iterations/010-shared-magic-link-auth/plan.md`, for shared magic-link authentication.

After implementation, Matt asked about the business rule that anyone with a `memba.io` email can sign up/sign in as staff through the magic-link form. We discovered that the iteration had ExUnit coverage but no acceptance feature scenarios for the magic-link authentication behaviour.

The immediate question was: "how did we miss BDD scenarios in planning?"

## Expected standard

For user-facing/domain behaviour, planning should surface business rules and examples as BDD scenarios when they clarify the domain behaviour.

The project-local iteration planning skill says to consider BDD discovery/formulation when an iteration changes acceptance tests or introduces non-obvious user/domain behaviour, and to draft or update acceptance feature files/scenarios when they clarify the iteration's domain behaviour.

The BDD formulation standard is that scenarios should document business rules in stakeholder language, grouped under `Rule:` where useful.

## What happened

Iteration 010 was planned and implemented with a large set of acceptance criteria around authentication, including:

- shared email magic-link sign-in,
- neutral responses for unknown email addresses,
- magic links for active club members,
- magic links for `memba.io` staff addresses,
- single-use and expiring tokens,
- signed-in member home page behaviour,
- staff access to `/admin/*`,
- non-staff denial from `/admin/*`,
- people who are both staff and members.

No `.feature` file was created or changed for these behaviours. Existing feature files remained only:

- `acceptance-tests/features/homepage.feature`,
- `acceptance-tests/features/member_message_deliverability.feature`,
- `acceptance-tests/features/operator_email_deliverability.feature`.

The plan's implementation and validation sections asked for automated tests, but only named lower-level test categories such as token, session, auth email, controller, LiveView, and authorization tests. It did not require BDD scenarios or acceptance feature changes.

The implementation run's final evidence reported `No acceptance .feature changes detected.` as if that were acceptable rather than a warning for a user-facing authentication slice.

## Impact

The delivered code has automated coverage, but the main business behaviour is not documented in living acceptance examples.

This creates several risks:

- Product rules are harder for Matt and future collaborators to review before or after implementation.
- Changes to authentication policy may be treated as technical refactoring instead of business-rule changes.
- Future agents may miss or regress important behaviours because the acceptance suite does not express them.
- Planning can appear complete even when user-facing behaviour has no BDD formulation.

## What allowed it to happen

The workflow relied on the planner and reviewer to notice when BDD scenarios were needed, but there was no hard guardrail for behaviour-facing iterations.

Suspected system weaknesses:

- The iteration plan template has an `Acceptance Criteria` section but no explicit `Acceptance Scenarios / Feature Files` section.
- The iteration-planning checklist says to consider BDD, but this can be skipped without any visible warning or required rationale.
- Plan validation did not flag a broad user-facing authentication slice whose validation plan omitted acceptance feature scenarios.
- The implementation workflow accepted `No acceptance .feature changes detected.` without distinguishing technical slices from business-behaviour slices.
- The review workflow did not challenge the absence of Gherkin scenarios despite the iteration introducing several new domain rules.

## Observations

- The missing scenarios were noticed only after implementation and deployment conversation had already moved on to manual testing.
- The behaviour was clearly business-facing: people sign in, staff authorization is based on an email domain, unknown people are handled neutrally, and club members see their clubs.
- The plan itself contained enough examples/rules to have produced BDD scenarios during planning.
- ExUnit tests gave a false sense that the behaviour was fully covered; they did not serve as stakeholder-readable examples.
- The current feature suite has no authentication feature file, so there was no obvious place where the omission would stand out.

## Why this matters

Authentication rules define who can access member and staff surfaces. Missing BDD scenarios for those rules weakens the product's executable specification at exactly the point where misunderstandings can become security, support, or trust problems.

If this pattern repeats, future iterations may accumulate technical tests while the business-facing acceptance suite falls behind the product's real behaviour.

## Open questions

- Should every behaviour-facing iteration plan require either new/updated BDD scenarios or an explicit explanation of why BDD is not useful for that slice?
- Should plan validation reject user-facing plans that omit acceptance feature scenarios when the acceptance criteria describe business rules?
- Should implementation or review workflows treat `No acceptance .feature changes detected.` as a warning when the plan is not explicitly marked as a technical-only slice?
- Where should shared authentication scenarios live: a new `shared_magic_link_authentication.feature` file or a broader access/authentication feature?

## Possible prevention ideas

- Add an `Acceptance Scenarios / Feature Files` section to the iteration plan template.
- Update plan validation to ask: "Is this behaviour-facing? If yes, where are the Gherkin scenarios or the explicit reason for not adding them?"
- Teach the iteration-planning skill to classify each iteration as behaviour-facing or technical, then make BDD formulation a required decision for behaviour-facing work.
- Teach review to flag behaviour-facing implementation evidence that says `No acceptance .feature changes detected.` unless the plan explicitly justified that outcome.

## Resolution

Date: 2026-05-31

Root cause: Planning and plan validation asked agents to consider BDD scenarios, but there was no required, visible BDD decision in the plan format. A behaviour-facing plan could list lower-level automated tests, omit feature scenarios, and still pass validation because reviewers had no hard readiness check for either named Gherkin scenarios or an explicit no-Gherkin rationale.

Fix applied:

- `.pi/skills/iteration-planning/SKILL.md`: added required `Iteration Type` and `Acceptance Scenarios / Feature Files` plan sections; behaviour-facing iterations must now name feature files/scenarios or explain why Gherkin is not useful, and planning must present that decision to Matt. Added stronger BDD heuristics so the planner defaults to Gherkin for business rules, permissions, lifecycle states, policy, safety/trust implications, edge-case-heavy behaviour, and examples that would help Matt catch misunderstandings.
- `.fabro/workflows/plan-validation/prompts/{review,gemini_review,claude_review,codex_review}.md`: added independent-review checks for iteration classification and the behaviour-facing BDD scenario decision.
- `.fabro/workflows/plan-validation/prompts/acceptance.md`: added the same acceptance-readiness check and made the returned report call out the BDD scenario decision explicitly.
- `.fabro/workflows/plan-validation/prompts/synthesize.md` and `.fabro/workflows/plan-validation/prompts/recheck.md`: added missing iteration classification or missing behaviour-facing BDD decision to the fail-closed readiness standard.
- `.fabro/workflows/plan-validation/test/fixtures/unanimous-pass/plan.md`: updated the passing fixture to model the new required sections and explicit allowed feature-file change.

Validation:

- `fabro validate .fabro/workflows/plan-validation/workflow.toml --no-upgrade-check` — passed; existing goal-gate retry warnings only.
- `bash .fabro/workflows/iteration-implementation/scripts/test_guard_acceptance_feature_changes.sh` — passed.
- `bash .fabro/workflows/iteration-review/scripts/test_final_artifact_gate.sh` — passed.

Remaining follow-up:

- Review-stage prompts still primarily treat feature files as locked post-implementation; if Matt wants an additional late warning for behaviour-facing implementations with no feature-file diff, add a separate evidence check after the new planning-time guard has had a chance to run.
