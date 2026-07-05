# Iteration 044 Review Report

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None.

No numbered ADR violation is evident from the supplied plan/evidence. The touched scope is Phoenix layout/CSS/LiveView/test code, not domain modeling, Commanded aggregates, projections, event streams, read models, or CQRS infrastructure. The implementation follows the plan’s binding technical decision to port the shared app-shell classes from the design-system mirror rather than re-expressing the shell locally in Tailwind utilities.

## Blocking issues

None.

The implementation appears plan-conforming, focused, and covered by the completed automated feedback loop. No behavioural gap, permission issue, unsafe state change, ADR conflict, or missing critical coverage was identified.

## Bounded-safe fixes

None required before merge.

I did not identify a concrete low-risk cleanup that is clearly worth applying immediately without changing intended UI behaviour or making a product/design judgement.

## Judgement-worthy non-blocking code-health findings

1. **Identity dropdown accessibility could be made more deliberate**

   - **Files:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The identity dropdown appears to use a regular button plus LiveView JS show/hide behaviour, with basic labelling and a real sign-out form. That is acceptable for this slice, but richer dropdown semantics may be worth standardizing: `aria-expanded`, `aria-haspopup`, clearer menu/menuitem semantics if it is intended to behave as a menu, Escape handling, and focus behaviour after open/close.
   - **Why it may need human judgement:** This is an interaction-design/accessibility standard decision, not just a mechanical refactor. The team should decide whether authenticated navigation dropdowns need a fuller accessible menu pattern now or whether the current simple disclosure behaviour is sufficient.

2. **Source-scanning design-conformance tests are useful but brittle**

   - **Files:** `test/memba_web/club_site_shell_integration_test.exs`
   - **Smell:** The tests inspect source text for required shared shell classes/component usage and forbidden legacy styling patterns. This is a strong guard against design drift, but it can fail on harmless refactors such as component extraction, formatting changes, or semantically equivalent HEEx restructuring.
   - **Why it may need human judgement:** The brittleness may be intentional for this iteration because the plan explicitly requires preserving design-system class names 1:1. Longer term, the team may want to decide whether these checks remain source-level, move to rendered-DOM assertions, or are supplemented by a CSS/design-system sync check.

3. **Visual parity still depends on human/design review**

   - **Files:** `web/assets/css/app.css`, `lib/memba_web/components/layouts.ex`, affected `club_site` LiveViews/templates
   - **Smell:** Automated tests verify rendering, app-shell class usage, identity gating, sign-out wiring, and absence of legacy styling. They do not fully prove pixel/layout parity against `design-system/wireframes/club-home.html` and `design-system/wireframes/member-conversation.html`.
   - **Why it may need human judgement:** This is inherent to a visual shell slice. If `./bin/dev gallery-walk` comparison was completed during implementation, this concern is satisfied. If not, a quick human visual spot-check of club home and conversation remains worthwhile, but this does not block merge given the passing automated suite and plan-conforming implementation.

## Suggested fixes

None required for acceptance.

Optional follow-ups if the team chooses:

- Standardize accessible dropdown/disclosure behaviour for app-shell identity controls.
- Revisit whether source-scanning design guards should be complemented with rendered-DOM assertions.
- Continue using gallery screenshots or visual review for app-shell fidelity checks.

## Validation notes

- `dev ci` / dev check completed successfully.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- Preflight required a clean working tree and sandbox check passed.
- Feature files appear unchanged, preserving existing acceptance criteria.
- Automated evidence covers:
  - shared `club_site` shell rendering,
  - app-bar/app-card/app-foot presence,
  - identity dropdown gating,
  - sign-out form behaviour,
  - `Layouts.initials/1` helper behaviour,
  - rendering of the relevant `club_site` surfaces,
  - checks against hardcoded colours, legacy club-site theme variables, and legacy Tailwind palette utilities.
- No domain/CQRS/event-sourcing architecture changes were implicated by this iteration.