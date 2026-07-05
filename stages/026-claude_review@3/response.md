# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

This iteration is Phoenix/LiveView presentation layer work: HEEx templates, CSS, client-side `Phoenix.LiveView.JS` commands, and render tests for the club-home tab UI. The implementation does not touch domain modeling, Commanded aggregates, projections, event streams, read models, CQRS boundaries, or ADR-governed architecture patterns. No ADRs are cited by the plan.

## ADR violations

None identified.

## Blocking issues

1. **Tab active-state JS is non-idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The implementation uses `JS.toggle_class("is-active", to: ".section-tab")` before adding `is-active` to the clicked tab.

   When a user clicks an already-active tab:
   - `toggle_class` removes `is-active` from the active tab and adds it to the inactive tab
   - `add_class` re-adds it to the clicked tab
   - **Result:** both tabs have `is-active` simultaneously

   This is a user-visible behavioral defect that:
   - Violates the one-active-tab UI pattern
   - Breaks WAI-ARIA tablist semantics (two tabs cannot both be `aria-selected="true"`)
   - Creates visual/ARIA state divergence

   **Evidence:** Three independent AI reviewers (Claude Sonnet 4.5, GPT-5.5, Gemini) across two review rounds all identified this exact issue in the same file with identical evidence.

   **Fix required:** Change `JS.toggle_class` to `JS.remove_class` in both tab buttons.

2. **ARIA tab/panel relationships are incomplete**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   Current state:
   - Tabs have `role="tab"` and `aria-selected` ✓
   - Tablist has `role="tablist"` ✓
   - Tabs lack stable `id` attributes ✗
   - Tabs lack `aria-controls` pointing to panels ✗
   - Panels lack `role="tabpanel"` ✗
   - Panels lack `aria-labelledby` pointing back to tabs ✗

   Per WAI-ARIA tabs pattern, the following are missing:
   - `id="conversations-tab"` and `id="members-tab"` on tab buttons
   - `aria-controls="conversations-panel"` on Conversations tab
   - `aria-controls="members-panel"` on Members tab
   - `role="tabpanel"` on both panel elements
   - `aria-labelledby="conversations-tab"` on Conversations panel
   - `aria-labelledby="members-tab"` on Members panel

   Since this iteration explicitly introduces an "app-like tabbed interface" and the validation plan calls out "keyboard/ARIA behaviour," these relationships should be complete before merge.

3. **Client-side tab interaction has no automated behavioral coverage**

   The LiveView tests verify initial render state (tab controls present, default panel shown, permissions, content placement) but do not exercise the `phx-click` tab-switching behavior or verify the JS command sequences.

   **Impact:** The `toggle_class` bug passed dev check because:
   - Static HTML assertions don't catch JS interaction defects
   - LiveView tests can't easily verify client-side JS without browser integration
   - The `toggle_class` vs `remove_class` distinction doesn't appear in rendered HTML

   **Fix required:** Either:
   - Add browser-level tests that simulate tab clicks, OR
   - Add structural assertions that decode and verify the `phx-click` JS operation list, OR
   - Obtain explicit human decision that this interaction remains manual-only coverage

4. **Agent repair attempts produced no working tree changes**

   Two separate agent repair attempts (stages 12 and 22) both:
   - Claimed the fixes were already present in the code
   - Referenced wrong file paths (`web/lib/memba_web/controllers/page_html.ex` vs actual `lib/memba_web/controllers/member/club_home_html/home.html.heex`)
   - Produced zero working tree changes
   - Failed verification (stages 13 and 23)

   **Impact:** All blocking issues remain unfixed. The second dev check (stage 24) passed only because the working tree is unchanged from the first check. Three independent reviewers across two review rounds all identified the same bugs in the same locations with consistent evidence.

## Bounded-safe fixes

1. **Fix tab state to be idempotent**

   Replace `JS.toggle_class("is-active", to: ".section-tab")` with `JS.remove_class("is-active", to: ".section-tab")` in both tab click handlers.

2. **Complete ARIA tab/panel relationships**

   Add stable IDs, `aria-controls`, `role="tabpanel"`, and `aria-labelledby` per the WAI-ARIA tabs pattern.

3. **Add targeted regression coverage**

   Add structural assertions that decode the rendered `phx-click` JS commands and verify:
   - `remove_class` is used (not `toggle_class`)
   - `aria-selected` is reset to false for all tabs and true for the selected tab
   - Expected panel/action show/hide commands are present
   - No server `push` event is used

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level club ID source format detection  
   **Why it may need human judgement:** The template computes `club_id_source` by regex-matching the club ID to distinguish UUID vs slug format, then constructs a `by-id/...` or `by-slug/...` path segment. This couples routing/format knowledge to HEEx. If this pattern repeats elsewhere, centralizing it in a view helper or route helper would improve maintainability. However, it's localized and functional for this slice.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines  
   **Why it may need human judgement:** The Conversations and Members tab click handlers contain nearly identical JS command sequences, differing only in panel/action targets. With two tabs, explicit duplication is clear and maintainable. If the club-home IA grows (the plan defers an About tab), this could become drift-prone and merit helper extraction. Not necessary now.

## Suggested fixes

### Required behavioral fix (blocking issue #1)

In `lib/memba_web/controllers/member/club_home_html/home.html.heex`, replace `JS.toggle_class` with `JS.remove_class` in both tab click handlers:

**Conversations tab:**
```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")  # ← changed from toggle_class
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#conversations-panel")
  |> JS.hide(to: "#members-panel")
  |> JS.show(to: "#section-tabs-action-conversations")
  |> JS.hide(to: "#section-tabs-action-members")
}
```

**Members tab:**
```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")  # ← changed from toggle_class
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#members-panel")
  |> JS.hide(to: "#conversations-panel")
  |> JS.show(to: "#section-tabs-action-members")
  |> JS.hide(to: "#section-tabs-action-conversations")
}
```

### Accessibility polish (blocking issue #2)

**Add stable IDs and `aria-controls` to tab buttons:**
```heex
<button
  id="conversations-tab"
  class="section-tab is-active"
  role="tab"
  aria-selected="true"
  aria-controls="conversations-panel"
  ...
>
  Conversations
</button>

<button
  id="members-tab"
  class="section-tab"
  role="tab"
  aria-selected="false"
  aria-controls="members-panel"
  ...
>
  Members
</button>
```

**Add `role` and `aria-labelledby` to panels:**
```heex
<div
  class="section-panel"
  id="conversations-panel"
  role="tabpanel"
  aria-labelledby="conversations-tab"
>
  ...
</div>

<div
  class="section-panel"
  id="members-panel"
  role="tabpanel"
  aria-labelledby="members-tab"
  style="display: none;"
>
  ...
</div>
```

### Test coverage (blocking issue #3)

Add structural JS command assertions in the LiveView test:

```elixir
test "tab click handlers use idempotent state transitions", %{conn: conn, member: member} do
  {:ok, _view, html} = conn |> signed_in_club_host(member) |> live(~p"/")
  
  # Parse phx-click attribute from Conversations tab button
  [_, encoded_js] = Regex.run(~r/id="conversations-tab"[^>]*phx-click="([^"]+)"/, html)
  js_ops = Jason.decode!(URI.decode(encoded_js))
  
  # Verify it uses remove_class, not toggle_class
  assert Enum.any?(js_ops, fn [op, args] -> 
    op == "remove_class" && args["names"] == "is-active" && args["to"] == ".section-tab"
  end)
  
  refute Enum.any?(js_ops, fn [op, _] -> op == "toggle_class" end)
  refute Enum.any?(js_ops, fn [op, _] -> op == "push" end)
  
  # Verify aria-selected management
  assert Enum.any?(js_ops, fn [op, args] ->
    op == "set_attribute" && args["attr"] == ["aria-selected", "false"]
  end)
end
```

## Validation notes

- **Dev check:** Passed three times (stages 5, 14, 24), but all with the bug present because tests don't exercise client-side behavior
- **Acceptance suite:** 85 scenarios green, 523 steps passed across all three runs; no feature-file changes (as required)
- **Implementation broadly plan-conforming:** Tab controls render, Conversations is default panel, per-section actions appear, manage-members gating works, email affordance moved, Members panel content present
- **Blocking bug not caught:** The `toggle_class` issue manifests when a user clicks the same tab twice—a scenario not covered by static render tests
- **Agent repair attempts failed:** Despite receiving correct diagnoses from six independent reviews (three reviewers × two rounds), the agent produced no working tree changes and misreported both the implementation state and file locations
- **Evidence consistency:** Three independent AI reviewers (Claude Sonnet 4.5, GPT-5.5, Gemini) across two review rounds all identified identical blocking issues with consistent evidence

**Manual validation required after fix:**
1. Load club home
2. Verify only one tab is active at a time
3. Click each tab
4. Click same tab repeatedly
5. Confirm visual state matches ARIA state
6. Verify panels and per-tab actions show/hide correctly
7. Test keyboard navigation
8. Verify screen reader announces tab/panel relationships

---

**Reject reasons:**
1. User-visible behavioral bug (non-idempotent tab state) that violates ARIA semantics
2. Incomplete accessibility (missing ARIA tab/panel relationships required by validation plan)
3. Inadequate automated coverage gap that allowed the bug to pass dev check three times
4. Failed agent repair attempts left all blocking issues unresolved across two repair cycles

The fixes are minimal (2 word changes + 8 ARIA attributes + one test assertion), but the behavioral defect, accessibility gaps, and coverage holes are real blockers requiring human intervention before merge.