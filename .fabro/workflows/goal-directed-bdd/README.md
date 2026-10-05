# Goal-directed BDD delivery — parallel experiment (design draft)

This is a *separate*, non-publishing **one-scenario historical rehearsal**, not a
replacement for `iteration-implementation`. The pilot graph exercises the first
BDD loop using `Eve asks to join Board` from iteration 066. It accepts an old
approved plan and its agreed example, **not** a predicted implementation task
list. It neither completes 066's other examples nor claims whole-plan conformance.
The full multi-scenario design below is the target if this bounded test works.

## Non-negotiable scenario loop

For **each agreed executable scenario**, in plan order:

1. Choose exactly one scenario from the approved plan's scenario manifest.
   The manifest names its feature path, exact scenario name, proving boundary,
   focused command, and permitted feature edits. Reject missing, duplicate,
   ambiguous, unsupported or feature-/rule-level `@todo` selections. A browser
   journey needs a browser-capable focused runner; a domain runner cannot stand
   in for it. Permit at most one active scenario-level `@wip`.
2. **Before changing production code**, persist the predicted failure and
   intended outcome, put `@wip` on that scenario (remove its scenario-level
   `@todo` if present), and run *only* that scenario. Record command, exit
   status, selected-test count, output hash and diagnostic. Red must be the
   predicted *behaviour* failure, not a missing step, harness failure, timeout,
   unrelated assertion or zero selected tests. Surprise red or green stops for
   clarification/replanning; neither silently authorizes implementation.
3. Implement only what is needed for this scenario, with supporting failing
   unit/application/LiveView tests where they expose the design or edge cases.
   Run those focused tests and rerun the `@wip` scenario. Keep unrelated state
   (form, route, access and privacy) intact; do not turn the scenario into a
   test of an easier boundary or weaken its assertions to make it green.
4. After the scenario goes green, independently review the actual changed code,
   test meaning, allowed feature edits, before/after evidence, and scope.
   Technical findings return to the same bounded loop automatically; a new
   business rule or architectural choice stops for Matt. Acceptance, not a
   successful checkpoint alone, allows removing `@wip` and moving to the next
   agreed scenario. Preserve both a saved unaccepted candidate and the last
   accepted checkpoint on failure. A revised check must stay scenario-focused.

The model cannot self-report a red/green transition. Deterministic gate code
must execute the focused command, verify exactly one selected scenario, compare
observed versus predicted diagnostics, and own `@wip` tag changes. The reviewer
must not be able to accept missing/stale evidence; the guard checks scenario,
source HEAD, feature hash, and candidate/checkpoint identity. A green scenario
on its own is insufficient: unit tests may still be needed and independent
review still has veto power.

## Iteration completion

Only after **all** agreed scenarios have accepted evidence, no `@wip` remains,
and plan constraints and supporting technical obligations have been proved:

- Run the complete `dev check` on the exact candidate. A failed or interrupted
  command is not a pass. Avoid repeated unbounded checks inside the per-scenario
  loop.
- Independently check conformance against the *whole* validated plan, including
  exclusions, non-scenario technical obligations, valid notification contracts
  and acceptance feature change policy. Repair requires a new exact-state gate.
- Preserve the existing clean-tree, source-HEAD, checkpoint, final-artifact and
  guarded publication boundaries. A sandbox commit or a reviewer verdict never
  implicitly publishes. Launch through the established iteration WIP slot and
  predecessor checks, never concurrently with another implementing iteration.

Technical iterations with **no agreed executable scenario** need their own
explicitly approved technical-proof path. This is not permission to skip an
applicable scenario or leave one `@todo`. An already-green agreed scenario is
recorded as observed-green and independently reviewed for coverage; it never
licenses unscoped implementation under a fabricated red.

## Pilot and open engineering work

The first graph and deterministic gate cover **one** historical domain scenario.
Its isolated tests cover red/green, wrong red, undefined step, zero selected,
feature-level `@todo`, changed scenario, reviewer veto and missing checkpoint.
It has schema-validated shot and review output, and no publication node. Before
using this as a real delivery workflow, generalize it to an approved scenario
manifest, cover browser examples at their own boundary, and test routing,
restart, revision budgets, final conformance and failure paths with Fabro
runtime fixtures. Do not alter `bin/dev fabro deliver` while it is a pilot.
Reuse existing preflight and publication *policies*, not the old task-packet or
`todo.md` acceptance artifact format; those scripts currently require their
own task-specific evidence and cannot safely be invoked unchanged. Keep
publication disabled until an equivalent guarded final artifact contract exists.

Limit the pilot by wall time and model cost, checkpoint/review cadence and a
same-finding no-progress stop. Compare total delivery time, Matt interruptions
by reason, review findings, focused and final failures, recovery effort and
quality against the current workflow. Explicitly stop rather than extending
budgets or auto-publishing when evidence is absent. This rehearsal uses a disposable checkout of **pre-implementation iteration
066** with the already-agreed domain step driver, moved from feature-level
`@todo` to scenario-level `@todo`. Its target red is the missing *product*
command, not a missing step definition. The pilot stops without publication
even if its focused scenario and `dev ci` pass. Keep a 30-minute working budget
and at most two revision visits; stop on any missing or contradictory evidence.
