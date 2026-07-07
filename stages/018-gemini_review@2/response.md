# Iteration Review Report: 048 — Named Member Rows

## Decision: ACCEPT

## Confidence: High

## ADR conformance: PASS

The implementation is a presentation-layer change to the club Members tab: replacing an avatar-stack card with named member rows, preserving invite/empty-state behaviour, and adding matching CSS/tests.

The plan does not cite any ADRs, and the evidence does not show changes to domain modelling, Commanded/CQRS flows, aggregates, event streams, projections, read models, routing architecture, persistence, or infrastructure. No accepted ADR-governed architecture appears to have been replaced, bypassed, or locally reimplemented.

## ADR violations

None.

## Blocking issues

None.

The implementation appears plan-conforming and safe to merge:

1. Members render as named rows rather than the previous avatar stack.
2. Rows include avatar initials and visible member names.
3. The current member row is marked with a “You” indicator.
4. Invite-member actions remain present and permission-gated as before.
5. Empty-state behaviour is preserved.
6. Tests cover the new row rendering, current-member marker, invite action, empty states, and removal of old avatar-stack markup.
7. No out-of-scope domain, permission, read-model, or acceptance-criteria changes are evident.
8. `dev ci` / `dev check` passed successfully.

## Bounded-safe fixes

None required.

The review-synthesis items currently listed as open appear already addressed in the implementation evidence:

1. **`test-member-row-helper`** — Evidence shows member-row assertions are factored through helpers such as `assert_rendered_member_row/3`, with `name`, `initials`, and `current?` keyword arguments.
2. **`audit-data-member-name`** — Evidence shows tests explicitly refute `data-member-name` under `#active-members-list`, and row assertions rely on visible names instead of duplicated name data attributes.

The failed `verify_review_repair` stage reported no working-tree diff after repair. Given the collected implementation evidence already includes the requested helper extraction and `data-member-name` removal checks, this looks like a workflow/state artifact rather than a remaining code defect.

## Judgement-worthy non-blocking code-health findings

1. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`, related view helper for `initials/1`**

   **Smell:** Member avatar initials are rendered via `initials(member.name)`. The evidence covers ordinary two-word names such as “Alice Adams” and “Bob Builder,” but does not show explicit coverage for single-word names, multi-part names, hyphenated names, apostrophes, non-ASCII names, blank names, or nil-like edge cases.

   **Why it may need human judgement:** This is acceptable for the current slice, but member names are user-facing and real-world data can be messy. If initials become a broader shared UI convention, the team may want documented presentation rules and dedicated tests for edge-case name handling.

2. **File: `web/assets/css/app.css`**

   **Smell:** The plan intentionally required manually porting `member-list` / `member-row` CSS from the design-system mirror into the app bundle with matching class names.

   **Why it may need human judgement:** This is plan-conforming and not a defect. However, repeated manual CSS copying between `design-system/` and `web/assets/css/app.css` can create drift over time. If this pattern continues, the team may want a future tooling or ownership decision around CSS synchronization or a single source of truth.

3. **Files: `web/test/memba_web/live/member_dashboard_live_test.exs`, rendered Members-tab markup**

   **Smell:** Tests assert fairly specific DOM structure, classes, ids, data attributes, and descendant relationships.

   **Why it may need human judgement:** For this iteration, structural assertions are reasonable because the plan explicitly required adopting design-system `member-list` / `member-row` class names. The trade-off is brittleness during later visual refactors. Once the Members-tab structure stabilizes, the team may want to rebalance some tests toward user-visible/semantic behaviour while keeping only targeted assertions for required design-system hooks.

4. **Files: `web/lib/memba_web/controllers/page_html/club.html.heex`; presentation/read-model boundary**

   **Smell:** The row metadata currently appears limited to the “You” marker. The plan explicitly deferred “member since” unless that date already flowed through `MemberDashboardPresentation`.

   **Why it may need human judgement:** This is the correct slice boundary now. Future iterations adding role badges, membership dates, or richer member metadata may need to revisit the presentation/read-model shape deliberately rather than accumulating conditional view-only metadata decisions.

## Suggested fixes

No pre-merge fixes are required.

Optional follow-up ideas for later, not blockers:

1. Add or centralize tests for initials generation edge cases if initials become a shared UI pattern.
2. Track whether manually ported design-system CSS begins to drift from `design-system/`.
3. Revisit Members-tab test granularity after the design-system markup stabilizes.

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
  - current member marked with “You,”
  - non-current members not marked current,
  - active member list state/count attributes,
  - invite action preservation,
  - empty-state behaviour,
  - absence of old avatar-stack markup,
  - absence of duplicated `data-member-name` attributes.
- No acceptance feature-file changes were required or indicated.
- The supplied transcript does not include a separate `./bin/dev gallery-walk` visual transcript. Given the focused presentation-only scope, the green automated checks, and the plan-conformance evidence, I do not treat that as blocking, but visual parity should still be confirmed if it has not already been done.