# Iteration Review Report: 048 — Named Member Rows

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

This iteration is a presentation-layer change for the club Members tab: replacing the prior avatar-stack card with named member rows, adding a current-member “You” indicator, preserving invite/empty-state behavior, and porting the matching CSS.

The plan does not cite ADRs, and the implementation evidence does not show changes to domain modeling, aggregates, commands, projections, event streams, read models, routing architecture, or infrastructure. No ADR-mandated architecture appears to have been bypassed or replaced.

## ADR violations

None.

## Blocking issues

None.

The implementation appears plan-conforming and safe to merge:

1. Members now render as named rows rather than an avatar stack.
2. Rows include avatar initials and visible member names.
3. The current member row is marked with “You”.
4. Invite member actions are preserved.
5. Empty-state behavior is preserved.
6. Tests cover the new row rendering, current-member marker, invite action, and empty states.
7. The implementation avoids out-of-scope permission, read-model, or domain changes.
8. `dev check` / `dev ci` passed successfully.

## Bounded-safe fixes

None required.

The review-synthesis items appear already addressed in the current implementation evidence:

1. **Member-row test helper extraction** — evidence shows tests now use `assert_rendered_member_row/3` with keyword arguments for `name`, `initials`, and `current?`.
2. **`data-member-name` audit/removal** — evidence shows tests explicitly refute `data-member-name` under `#active-members-list`, and row assertions use visible member names rather than duplicated data attributes.

The failed `verify_review_repair` stage reported no working-tree diff since repair start, but the collected evidence already contains the requested polish. That looks like a workflow/state artifact rather than an implementation defect.

## Judgement-worthy non-blocking code-health findings

1. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`, related view helpers — initials generation edge cases**

   **Smell:** Member avatar initials are generated from `initials(member.name)`. The evidence covers ordinary two-word names such as “Alice Adams” and “Bob Builder”, but does not show explicit coverage for single-word names, multi-part names, hyphenated names, apostrophes, non-ASCII names, blank names, or nil-like edge cases.

   **Why it may need human judgement:** This is acceptable for the current slice, but member names are user-facing and real-world data can be messy. If initials are a recurring UI pattern, the project may want a shared, documented presentation helper with dedicated tests for name handling.

2. **File: `web/assets/css/app.css` — manual design-system CSS porting**

   **Smell:** The plan explicitly required porting `member-list` / `member-row` CSS from the design-system mirror into app CSS with matching class names. That is plan-conforming, but it continues a manual-copy pattern.

   **Why it may need human judgement:** This is not a defect in this iteration. However, if many future iterations copy CSS fragments from `design-system/` into `web/assets/css/app.css`, drift risk increases. A later tooling or ownership decision around design-system CSS synchronization may be useful.

3. **Files: `web/test/memba_web/live/member_dashboard_live_test.exs`, rendered Members tab markup — structural DOM assertions**

   **Smell:** The tests assert fairly specific IDs, classes, data attributes, and descendant structure. This gives strong confidence that the design-system markup was adopted, but it also couples tests to DOM structure.

   **Why it may need human judgement:** For this iteration, structural assertions are reasonable because the plan explicitly required adopting `member-list` / `member-row` classes. Over time, the team may want to decide whether these tests should primarily protect design-system structure or user-observable behavior to avoid unnecessary churn during visual refactors.

4. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`, presentation/read-model boundary — deferred member metadata**

   **Smell:** The plan’s technical decision said to include “member since” only if already available through `MemberDashboardPresentation`; otherwise omit it. The implementation correctly appears to omit it and render only the current-member “You” meta marker.

   **Why it may need human judgement:** This is the correct slice boundary now. Future iterations adding role badges or membership metadata may need to revisit the presentation/read-model shape rather than accumulating conditional view-only metadata decisions.

## Suggested fixes

No pre-merge fixes are required.

If the team chooses follow-up polish later, consider:

1. Add or centralize tests for initials generation edge cases if initials become a shared UI convention.
2. Track whether manually ported design-system CSS is starting to drift from `design-system/`.
3. Rebalance future Members-tab tests toward semantic/user-visible assertions once design-system structure is stable.

## Validation notes

- Review started from a clean working tree.
- Sandbox runtime check passed.
- `dev ci` / `dev check` passed:
  - 85 scenarios passed.
  - 523 steps passed.
- Automated evidence covers:
  - named member rows,
  - avatar initials,
  - visible member names,
  - current member marked with “You”,
  - non-current member not marked as current,
  - active member list state/count attributes,
  - invite action preservation,
  - empty-state behavior,
  - absence of the old avatar-stack markup,
  - absence of duplicated `data-member-name` attributes.
- No acceptance feature-file changes were required or indicated.
- The supplied transcript does not include a separate `gallery-walk` visual transcript, but given the plan-conformance gate, green automated checks, and focused presentation-only scope, this is not blocking for merge.