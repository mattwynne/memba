# Iteration 044 Review Report

- **Decision:** ACCEPT
- **Confidence:** High
- **ADR conformance:** PASS

## ADR violations

None.

The touched implementation is in the Phoenix web/layout/CSS/test layer. No domain modeling, Commanded aggregate, projection, event stream, read-model, or CQRS infrastructure changes appear implicated. The implementation follows the governing design-system decision from the plan: port shared app-shell component classes from the design mirror rather than locally re-expressing the shell in Tailwind utilities.

## Blocking issues

None.

The implementation appears plan-conforming, avoids obvious out-of-scope behaviour, and passed the automated feedback loop.

## Bounded-safe fixes

None required before merge.

I did not identify a concrete low-risk refactor that is clearly worth applying immediately without product/design judgement.

## Judgement-worthy non-blocking code-health findings

1. **Identity dropdown accessibility could be strengthened**

   - **Files:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The dropdown appears to use a normal button plus LiveView JS show/hide behaviour and has basic labelling, but fuller dropdown/menu accessibility patterns may not yet be present: e.g. `aria-expanded`, `aria-haspopup`, explicit menu/menuitem semantics where appropriate, Escape-key behaviour, and predictable focus handling.
   - **Why it may need human judgement:** This is not necessarily a blocker for this slice, especially if the UI is visually and behaviourally correct, but accessibility expectations for authenticated navigation controls should be decided deliberately. Adding richer ARIA/focus behaviour may be small technically, but the desired interaction model belongs with product/design standards.

2. **Static source-scanning tests are useful but somewhat brittle**

   - **Files:** `test/memba_web/club_site_shell_integration_test.exs`
   - **Smell:** The design-conformance tests inspect source text for required class/component usage and forbidden legacy styling patterns. This is valuable as a drift guard, but source-text assertions can fail on harmless refactors, formatting changes, component extraction, or alternate-but-equivalent HEEx structure.
   - **Why it may need human judgement:** The brittleness may be acceptable here because the iteration explicitly wants to lock the shared shell to design-system classes. Longer term, the team may want to decide whether these checks should remain source-level, move toward rendered-DOM assertions, or be supplemented by a more direct design-system/CSS sync check.

3. **Manual visual parity remains a human validation concern**

   - **Files:** `web/assets/css/app.css`, `lib/memba_web/components/layouts.ex`, affected LiveViews/templates using `club_site`
   - **Smell:** The plan’s design intent depends on visual fidelity to `design-system/wireframes/club-home.html` and `member-conversation.html`. Automated tests confirm rendering, class usage, and lack of legacy styling, but they do not fully prove pixel/layout parity.
   - **Why it may need human judgement:** This is inherent to a UI shell slice. If `gallery-walk` comparison was performed during implementation, this is satisfied. If not, product/design review should still spot-check the club home and conversation pages, but this does not block the code review given the green automated pass and plan-conformance gate.

## Suggested fixes

None required for acceptance.

Optional follow-ups if the team chooses:

- Add richer ARIA/focus behaviour to the identity dropdown.
- Revisit whether source-scanning design-conformance tests should be complemented by rendered-DOM assertions.
- Continue using gallery screenshots as the visual parity feedback loop for app-shell changes.

## Validation notes

- `dev ci` / dev check completed successfully.
- Acceptance suite passed: **85 scenarios, 523 steps**.
- Working tree was clean at review preflight.
- Feature files appear unchanged, preserving existing acceptance criteria.
- Automated coverage described in the implementation evidence includes:
  - shared `club_site` shell rendering,
  - app-bar/app-card/app-foot presence,
  - identity dropdown gating,
  - sign-out form behaviour,
  - `Layouts.initials/1` helper coverage,
  - all relevant `club_site` surfaces still rendering,
  - checks against hardcoded colours, legacy club-site theme variables, and legacy Tailwind palette utilities.

Overall, this is a clean, focused implementation of the shared app shell with strong automated coverage and no identified ADR or behavioural blockers.