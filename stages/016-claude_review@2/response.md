# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

No ADR cited by the iteration plan appears to govern this club-home tab UI implementation. The touched code is Phoenix LiveView presentation wiring, HEEx templates, CSS, and render tests. It does not involve domain modeling, Commanded aggregates, projections, event streams, read models, CQRS boundaries, or object responsibility changes that would invoke project ADRs.

## ADR violations

None identified.

## Blocking issues

1. **Tab active-state JS is not idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   Both tab click handlers use:

   ```elixir
   JS.toggle_class("is-active", to: ".section-tab")
   |> JS.add_class("is-active")
   ```

   When a user clicks an already-active tab:
   - `toggle_class` removes `is-active` from the active tab and adds it to the inactive tab
   - `add_class` then re-adds it to the clicked tab
   - **Result:** both tabs have `is-active` class

   This is a user-visible behavioral defect that:
   - Violates the intended one-active-tab UI pattern
   - Breaks WAI-ARIA tablist semantics (two tabs cannot both be `aria-selected="true"`)
   - Creates visual/ARIA state divergence

   **Evidence:** Implementation diff shows both Conversations and Members tabs using `JS.toggle_class("is-active", to: ".section-tab")` followed by `JS.add_class("is-active")`.

   **Fix required:** Change `JS.toggle_class` to `JS.remove_class` in both tab buttons.

2. **Client-side tab interaction has no automated behavioral coverage**

   The LiveView tests verify initial render state (tab controls present, default panel shown, permissions/content placement) but do not exercise the `phx-click` tab-switching behavior or verify the JS command sequences.

   **Impact:** The blocking bug above passed dev check because:
   - Static HTML assertions don't catch JS interaction defects
   - LiveView tests can't easily verify client-side JS without browser integration
   - The `toggle_class` vs `remove_class` distinction doesn't appear in rendered HTML

   **Fix required:** Either:
   - Add browser-level tests (Wallaby/Hound) that simulate tab clicks, OR
   - Add structural assertions that decode and verify the `phx-click` JS operation list (confirming `remove_class`, not `toggle_class`), OR
   - Obtain explicit human decision that this interaction remains manual-only coverage

3. **Agent repair attempt produced no changes**

   Three independent AI reviewers (Claude Sonnet 4.5, GPT-5.5, Gemini) all correctly identified the `toggle_class` bug and missing ARIA attributes. An agent was instructed to apply bounded review fixes but the `verify_review_repair` stage failed because **no working tree diff was produced**.

   The agent falsely claimed:
   > "Current implementation already used `JS.remove_class(...)` rather than `JS.toggle_class(...)`"

   The implementation evidence (stages 5 and 14, identical diffs) proves this is incorrect: both tabs still use `toggle_class`.

   The agent also claimed to add ARIA attributes but produced no changes.

   **Impact:** The blocking issues remain unfixed. The second dev check (stage 14) passed only because the working tree is unchanged from the first check.

## Bounded-safe fixes

1. **Complete ARIA tab/panel relationships**

   Current state:
   - Tabs have `role="tab"` and `aria-selected` ✓
   - Tablist has `role="tablist"` ✓
   - Tabs lack stable `id` attributes ✗
   - Tabs lack `aria-controls` pointing to panels ✗
   - Panels lack `role="tabpanel"` ✗
   - Panels lack `aria-labelledby` pointing back to tabs ✗

   Per WAI-ARIA tabs pattern best practices, add:
   - `id="conversations-tab"` and `id="members-tab"` to tab buttons
   - `aria-controls="conversations-panel"` to Conversations tab
   - `aria-controls="members-panel"` to Members tab
   - `role="tabpanel"` to both `#conversations-panel` and `#members-panel`
   - `aria-labelledby="conversations-tab"` to Conversations panel
   - `aria-labelledby="members-tab"` to Members panel

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level club ID source format detection  
   **Why it may need human judgement:** The template computes `club_id_source` by regex-matching the club ID to distinguish UUID vs slug format, then constructs a `by-id/...` or `by-slug/...` path segment. This couples routing/format knowledge to the HEEx template. If this pattern repeats elsewhere, centralizing it in a view helper or route helper would improve maintainability. However, it's localized and functional for this slice.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines  
   **Why it may need human judgement:** The Conversations and Members tab click handlers contain nearly identical JS command sequences, differing only in panel/action targets. With two tabs, explicit duplication is clear and maintainable. If the club-home IA grows (the plan defers an About tab), this could become drift-prone and merit a helper extraction. Not necessary now.

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

### Accessibility polish (bounded-safe)

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

### Test coverage (blocking issue #2)

Decision needed: choose one approach:

**Option A:** Add browser-level interaction tests (if supported):
```elixir
# In a Wallaby/Hound test
test "clicking tabs switches active state", %{session: session} do
  session
  |> visit(~p"/")
  |> click(css("button", text: "Members"))
  |> assert_has(css(".section-tab.is-active", text: "Members"))
  |> refute_has(css(".section-tab.is-active", text: "Conversations"))
  |> click(css("button", text: "Members"))  # Click same tab again
  |> assert_has(css(".section-tab.is-active", text: "Members"))  # Still only Members active
end
```

**Option B:** Add structural JS command assertions:
```elixir
test "tab click handlers use idempotent state transitions", %{conn: conn, member: member} do
  {:ok, _view, html} = conn |> signed_in_club_host(member) |> live(~p"/")
  
  # Parse phx-click attribute from Conversations tab button
  [_, encoded_js] = Regex.run(~r/phx-click="([^"]+)"/, html)
  js_ops = Jason.decode!(URI.decode(encoded_js))
  
  # Verify it uses remove_class, not toggle_class
  assert Enum.any?(js_ops, fn [op, args] -> 
    op == "remove_class" && args["names"] == "is-active" && args["to"] == ".section-tab"
  end)
  refute Enum.any?(js_ops, fn [op, _] -> op == "toggle_class" end)
end
```

**Option C:** Document as manual-only coverage with explicit human decision that client-side JS interactions for this slice are verified manually via gallery-walk and ad-hoc testing.

## Validation notes

- **Dev check:** Passed twice (stages 5 and 14), but passed with the bug present because tests don't exercise client-side behavior.
- **Acceptance suite:** 85 scenarios green, 523 steps passed; no feature-file changes (as required).
- **Implementation broadly plan-conforming:** Tab controls render, Conversations is default panel, per-section actions appear, manage-members gating works, email affordance moved, Members panel content present.
- **Blocking bug not caught:** The `toggle_class` issue would manifest when a user clicks the same tab twice—a scenario not covered by static render tests.
- **Agent repair failed:** Despite receiving correct diagnoses from three reviewers, the agent produced no working tree changes and misreported the implementation state.
- **Manual validation required after fix:** Load club home; verify only one tab is active at a time; click each tab; click same tab repeatedly; confirm visual state matches ARIA state.

---

**Reject reasons:**
1. User-visible behavioral bug (non-idempotent tab state) that violates ARIA semantics
2. Incomplete accessibility (missing ARIA tab/panel relationships)
3. Inadequate automated coverage gap that allowed the bug to pass dev check
4. Failed agent repair attempt left all blocking issues unresolved

The fixes are minimal (2 word changes + 8 attributes + coverage decision), but the behavioral defect and coverage gap are real blockers that need resolution before merge.