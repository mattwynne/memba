# Iteration Review Report: 048 — Named Member Rows

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The iteration appears to be a presentation-layer change limited to the club Members tab: HEEx markup, CSS, and controller/view tests. The plan does not cite any ADRs, and the collected evidence does not show changes to domain modeling, aggregates, commands, projections, event streams, read models, routing architecture, or infrastructure.

No ADR-mandated architecture appears to have been bypassed or replaced.

## ADR violations

None.

## Blocking issues

None.

The implementation appears consistent with the iteration goal:

- Members tab renders named member rows instead of the prior avatar-stack card.
- Each row includes avatar initials and member name.
- The current member row is marked with a “You” indicator.
- Invite action remains present and gated as before.
- Empty state remains covered.
- No evidence of out-of-scope domain or permission changes.
- `dev check` / `dev ci` passed: 85 scenarios, 523 steps.

## Bounded-safe fixes

1. **Reduce selector duplication in `test/memba_web/controllers/page_controller_test.exs`**

   The test evidence shows many long selector assertions repeated for each member row, e.g. checking row id, classes, data attributes, avatar, name, current-member marker, and invite link.

   This is not incorrect, but it is verbose and will be expensive to maintain if row markup evolves. A small private helper such as `assert_member_row/4` or `assert_current_member_row/4` would keep the same coverage while making the test intent clearer.

2. **Avoid testing too many styling/class details where behaviour is the concern**

   Assertions currently appear to couple behaviour to exact CSS classes such as `.member-row`, `.member-row__avatar`, `.member-row__name`, and `.member-row__meta`.

   Some class assertions are useful because the plan explicitly required porting `member-list` / `member-row` design-system classes. However, tests that combine ids, classes, data attributes, and descendant structure may become brittle. Consider keeping one or two structural/class assertions for design-system conformance, and using `data-testid` / semantic text assertions for behavioural expectations.

3. **Consider removing or minimizing `data-member-name` if it is only test scaffolding**

   Evidence shows rows carrying `data-member-name='Alice Adams'` / similar. If this attribute is only present to support tests, it may be unnecessary because the visible `.member-row__name` already exposes the name.

   Keeping names in data attributes is not a blocker, but it duplicates user-visible content and can create escaping/special-character test fragility for names containing quotes or unusual characters.

## Judgement-worthy non-blocking code-health findings

1. **File: `web/lib/memba_web/controllers/page_html/club.html.heex` — View logic depends on `initials(member.name)`**

   **Smell:** The implementation uses generated initials for member avatars. The evidence proves common two-word names such as “Alice Adams” and “Bob Builder”, but does not show coverage for one-word names, blank/edge-case names, non-ASCII names, apostrophes, hyphenated names, or multi-part names.

   **Why judgement may be needed:** This is acceptable for the current iteration because the plan only asks for avatar initials + name, and tests pass. However, real member names can be messy. If initials are user-facing across the product, the project may want a shared, well-tested presentation helper with explicit name-handling rules.

2. **File: `test/memba_web/controllers/page_controller_test.exs` — White-box DOM assertions**

   **Smell:** The tests appear highly specific about DOM shape, ids, data attributes, classes, and nested descendants.

   **Why judgement may be needed:** This gives strong confidence that the design-system row markup was adopted, which is valuable for this slice. The trade-off is that future visual refactors may require test rewrites even when user behaviour is unchanged. A human may want to decide whether Members tab tests should be primarily structural/design-system assertions or primarily user-visible behaviour assertions.

3. **File: `web/assets/css/app.css` — Design-system CSS copied into application bundle**

   **Smell:** The plan explicitly required porting `member-list` and `member-row` CSS from `design-system/` into `web/assets/css/app.css` with 1:1 names. That is plan-conforming, but it continues the duplication between the design-system mirror and app CSS.

   **Why judgement may be needed:** If this pattern repeats, the app may accumulate manually ported CSS fragments that drift from the design-system source. This is not a defect in this iteration, but it may warrant a later discussion about a single source of truth or tooling for design-system CSS synchronization.

4. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`, presentation/read-model boundary — Member metadata remains minimal**

   **Smell:** The plan’s open technical decision says to include “member since” only if already available through `MemberDashboardPresentation`; otherwise omit it. The implementation appears to omit it and only shows the “You” marker.

   **Why judgement may be needed:** This is correct for the slice. Future iterations adding role badges or membership metadata may need to revisit the read model/presentation shape. The current implementation should not be expanded now, but this is a likely future seam.

## Suggested fixes

No fixes are required before merge.

If applying bounded-safe polish, I would prioritize:

1. Extract test helpers in `test/memba_web/controllers/page_controller_test.exs`, for example:
   - `assert_member_list(html, count)`
   - `assert_member_row(html, member_id, name:, initials:, current?: boolean)`
   - `refute_current_member_indicator(html, member_id)`

2. Keep one assertion that verifies `.member-list` / `.member-row` design-system classes are present, but avoid repeating full structural selectors for every row unless the structure itself is the behaviour under test.

3. Reconsider whether `data-member-name` is needed in production markup. If not needed for behaviour, accessibility, analytics, or tests, prefer asserting the visible name text instead.

## Validation notes

- `dev ci` / `dev check` passed successfully.
  - 85 scenarios passed.
  - 523 steps passed.
- Automated evidence covers:
  - Named member rows.
  - Avatar initials.
  - Current member marked with “You”.
  - Non-current member not marked as current.
  - Members list container state/count attributes.
  - Invite member action preservation.
  - Empty state behaviour.
- No acceptance feature-file changes were indicated.
- Manual/gallery validation was part of the plan, but the supplied review output does not include a `./bin/dev gallery-walk` transcript. I am not treating that as blocking because the implementation is otherwise plan-conforming and automated checks are green, but visual parity should still be confirmed if it has not already been done.