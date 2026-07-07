# Iteration Review Report: 048 — Named Member Rows

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The plan does not cite any ADRs, and the implementation evidence shows a presentation-layer change limited to the club Members tab markup, CSS, and controller/view tests. There is no evidence of changes to domain modeling, Commanded/CQRS flows, aggregates, event streams, projections, read models, routing architecture, or infrastructure.

No accepted ADR-governed architecture appears to have been replaced or bypassed.

## ADR violations

None.

## Blocking issues

None.

The implementation appears consistent with the iteration goal:

- The Members tab now renders named member rows instead of an avatar-stack card.
- Rows include avatar initials and visible member names.
- The current member row is marked with a “You” indicator.
- The Invite member action is preserved.
- The empty state remains covered.
- There is no evidence of out-of-scope permission, domain, or read-model changes.
- The automated check stage passed.

## Bounded-safe fixes

1. **Extract member-row assertion helpers in `test/memba_web/controllers/page_controller_test.exs`**

   The test evidence shows repeated long selectors for each row, combining ids, classes, data attributes, descendants, and expected text. This is valid but verbose.

   A private helper such as `assert_member_row/4` or `assert_current_member_row/4` would preserve coverage while making the test easier to read and maintain.

2. **Reduce repeated white-box selector coupling where possible**

   Some `.member-list` / `.member-row` class assertions are valuable because the plan explicitly required porting design-system class names. However, every row assertion does not necessarily need to repeat the full structural selector.

   A bounded cleanup could keep one or two structural/design-system assertions, then use row ids, `data-testid`, and visible text for most behaviour checks.

3. **Audit whether `data-member-name` is needed in production markup**

   Evidence shows rows include `data-member-name`. If this exists only to make tests easier, the visible `.member-row__name` text may be sufficient.

   This is not a correctness issue, but removing duplicate name data could reduce escaping/special-character fragility and avoid unnecessary user data duplication in attributes. Only do this after confirming no CSS, JS, analytics, tests, or acceptance helpers depend on it.

## Judgement-worthy non-blocking code-health findings

1. **File: `test/memba_web/controllers/page_controller_test.exs` — highly structural DOM assertions**

   **Smell:** The tests appear to assert exact DOM structure, CSS classes, data attributes, and descendant relationships for multiple rows.

   **Why it may need human judgement:** This gives strong confidence that the design-system row markup was adopted, which matters for this slice. The trade-off is brittleness: future purely visual refactors may require test rewrites even if user-visible behaviour remains correct. The team may want to decide whether these tests should primarily protect design-system structure or user-observable behaviour.

2. **File: `web/lib/memba_web/controllers/page_html/club.html.heex` — initials generation edge cases**

   **Smell:** The view renders avatar initials via `initials(member.name)`. The evidence covers normal two-word names like “Alice Adams” and “Bob Builder,” but does not show edge-case coverage for single names, multi-part names, apostrophes, hyphenated names, non-ASCII names, or blank/unusual values.

   **Why it may need human judgement:** This is acceptable for the current iteration, but member names are user-facing and can be messy. If initials are or will become a shared UI convention, the project may want explicit presentation rules and dedicated tests around initials generation.

3. **File: `web/assets/css/app.css` — copied design-system CSS fragments**

   **Smell:** The plan explicitly required porting `member-list` and `member-row` CSS from `design-system/` into the app bundle with matching names. That is plan-conforming, but it continues a manual-copy pattern between the design mirror and app CSS.

   **Why it may need human judgement:** If many future slices copy CSS from the design system into `app.css`, drift may become likely. This does not block the iteration, but a later tooling or ownership decision may be useful if duplication grows.

4. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`; presentation/read-model boundary — minimal row metadata**

   **Smell:** The plan said to include “member since” only if already available through `MemberDashboardPresentation`; otherwise omit it. The implementation appears to correctly omit it and only render the “You” marker.

   **Why it may need human judgement:** This is the right slice boundary now. Future iterations adding role badges or membership metadata may need to revisit the presentation/read-model shape rather than continuing to layer conditional view-only metadata.

## Suggested fixes

No fixes are required before merge.

If applying bounded-safe polish, prioritize:

1. Add private test helpers in `page_controller_test.exs`, for example:
   - `assert_member_list(html, count)`
   - `assert_member_row(html, member_id, name:, initials:, current?: false)`
   - `assert_current_member_indicator(html, member_id)`
   - `refute_current_member_indicator(html, member_id)`

2. Keep targeted assertions proving `.member-list` and `.member-row` design-system classes exist, but avoid repeating full nested CSS selectors for every behavioural assertion.

3. Audit `data-member-name`; remove it only if it is confirmed to be test-only and unused elsewhere.

## Validation notes

- The review pipeline started from a clean working tree.
- Sandbox runtime check passed.
- The dev check stage ran `dev ci` successfully.
  - 85 scenarios passed.
  - 523 steps passed.
- Automated evidence covers:
  - named member rows,
  - avatar initials,
  - visible member names,
  - current member marked with “You,”
  - non-current member not marked current,
  - invite action preservation,
  - active-members list state/count attributes,
  - empty state behaviour.
- No acceptance feature-file changes were required by the plan.
- The plan’s visual validation step, `./bin/dev gallery-walk`, is not shown in the supplied review transcript. I do not treat that as blocking given the green automated checks and plan-conforming evidence, but visual parity should still be confirmed if it has not already been done.