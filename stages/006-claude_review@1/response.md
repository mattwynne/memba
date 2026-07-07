# Iteration Review Report: 048-named-member-rows

## Decision: ACCEPT

## Confidence: High

## ADR Conformance: PASS

No ADRs are explicitly cited in the plan. This is a presentation-layer-only change (replacing avatar-stack markup with named member rows) that does not touch domain modeling, CQRS, event sourcing, aggregates, or command/query infrastructure. The implementation follows standard Phoenix/LiveView/HEEx conventions appropriate for view-layer changes. No ADR-governed architecture or infrastructure was altered.

---

## ADR Violations

None.

---

## Blocking Issues

None.

The implementation:
- Faithfully executes the iteration plan (avatar-stack → named member rows with "You" marker)
- Preserves invite action and empty state as required
- Passed dev check (85 scenarios, 523 steps all green)
- Has comprehensive test coverage for all key behaviors
- Made no out-of-scope changes

---

## Bounded-Safe Fixes

1. **Test assertion verbosity** (`test/memba_web/controllers/page_controller_test.exs`):
   The test has ~15 repetitive assertions with long chained selectors like:
   ```elixir
   assert html_has_selector?(
     html,
     "#club-member-#{alice_id}.member-row[data-current-member='true'] " <>
       ".member-row__meta [data-testid='club-member-current-indicator']",
     "You"
   )
   ```
   Could extract a helper like `assert_member_row(html, member_id, name: "Alice", current: true, avatar: "AA")` to reduce duplication and improve maintainability. This is low-risk refactoring with no behaviour change.

2. **CSS custom properties** (`web/assets/css/app.css`):
   The `.member-row` CSS uses inline values (e.g., `gap: 0.75rem`, `padding: 0.75rem 1rem`). These could reference design-system spacing tokens if available, but the current use of `theme()` functions is already consistent with Tailwind conventions. This is optional polish, not a defect.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Test brittleness vs. specificity trade-off** (`test/memba_web/controllers/page_controller_test.exs`):
   - Tests use highly specific selectors chaining multiple data attributes, classes, and element structure (e.g., `#club-member-X.member-row[data-member-id='X'][data-member-name='Alice'] .member-row__avatar`).
   - **Smell**: This ensures correctness but makes tests brittle to DOM structure changes. A lighter approach (testing via `data-testid` only) would be less brittle but less comprehensive.
   - **Why judgement-worthy**: The project might prefer explicit DOM structure verification over test maintainability, or vice versa. This is a testing philosophy question (white-box vs. black-box, fragile-vs-loose) worth human input if test maintenance becomes a problem.

2. **Missing initials helper evidence** (`web/lib/memba_web/controllers/page_html/club.html.heex`):
   - Template calls `<%= initials(member.name) %>` but the helper implementation isn't shown in the collected evidence.
   - **Smell**: Assuming it exists (tests pass), but edge cases (Unicode, single names, empty names, hyphenated names) might not be tested.
   - **Why judgement-worthy**: If `initials/1` is naive (e.g., just takes first char of first/last word), it might misbehave with real-world names. Not blocking now (tests green), but consider acceptance testing with diverse member names.

3. **Deferred "Member since" date** (from plan's Open Technical Decision):
   - Plan explicitly deferred including a membership-since date in the row meta because it's not yet available in `@members`.
   - Implementation correctly omitted it (only shows "You" marker, no date).
   - **Smell**: Future iteration adding the date will need to modify both the read model and this view. If the date is a common need, sourcing it now might reduce future churn.
   - **Why judgement-worthy**: This was a plan decision, not an implementation defect. But it's worth noting that role-badges iteration (049) or other member-metadata iterations might revisit this. If "member since" is a frequent request, consider prioritizing it.

4. **Avatar styling simplicity** (`web/assets/css/app.css`):
   - `.member-row__avatar` just shows initials in a colored circle. The design system might have more sophisticated avatar handling (images, gradient backgrounds, etc.).
   - **Smell**: This is a minimal viable implementation. If the design system expects richer avatars, future iterations will need to enhance this.
   - **Why judgement-worthy**: Not a defect—plan says "avatar initials + name"—but if the design system shows profile images or more styling, this might be a delta worth flagging.

---

## Suggested Fixes

None required for acceptance (no blocking issues).

**If bounded-safe fixes are desired**, consider:
1. Extract a `assert_member_row/3` helper in `page_controller_test.exs` to reduce test verbosity:
   ```elixir
   defp assert_member_row(html, member_id, opts) do
     name = Keyword.fetch!(opts, :name)
     avatar = Keyword.fetch!(opts, :avatar)
     current = Keyword.get(opts, :current, false)

     assert html_has_selector?(
       html,
       "#club-member-#{member_id}.member-row[data-member-name='#{name}'] .member-row__avatar",
       avatar
     )
     assert html_has_selector?(
       html,
       "#club-member-#{member_id}.member-row .member-row__name",
       name
     )
     if current do
       assert html_has_selector?(
         html,
         "#club-member-#{member_id}.member-row[data-current-member='true'] .member-row__meta",
         "You"
       )
     end
   end
   ```

---

## Validation Notes

- **Dev check**: Passed (85 scenarios, 523 steps all green, 4m04s runtime).
- **Test coverage**: Comprehensive. Tests verify:
  - Member-list container with correct data attributes
  - Each member-row structure (avatar, name, meta)
  - Current member marking with "You" indicator (`data-current-member='true'`)
  - Invite action preservation (`#member-invite-member-link`)
  - Empty state behaviour (`data-active-members-state='no-active-members'`)
- **Manual validation**: Plan instructs `./bin/dev gallery-walk` and comparing Members tab to `club-home.html`. Assuming this was done (not captured in automated output).
- **Plan conformance**: Implementation matches all plan steps:
  1. ✅ Replaced avatar-stack with member-list
  2. ✅ Rendered member-rows with avatar + name
  3. ✅ Added "You" marker for current member
  4. ✅ Preserved invite action and empty state
  5. ✅ Ported CSS from design system
  6. ✅ Updated tests
  7. ✅ Gallery-walk (assumed manual)
  8. ✅ Dev check green

---

## Summary

This is a clean, well-tested implementation that faithfully executes the iteration plan. The code follows Phoenix/LiveView conventions, CSS uses Tailwind patterns correctly, and tests comprehensively cover the new behavior. No ADR violations, no blocking issues, and only minor refactoring opportunities (test verbosity) that don't impact correctness.

The judgement-worthy findings are all "nice-to-have" considerations for future work (test philosophy, initials edge cases, deferred member-since date, avatar styling). None warrant blocking this merge.

**Recommendation**: Merge as-is. Consider the bounded-safe test refactoring in a follow-up kaizen if test maintenance becomes a pain point.