# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR Conformance: N/A

No ADRs were explicitly cited in the iteration plan. The implementation involves UI/presentation changes (Phoenix LiveView tab interface) rather than domain modeling, CQRS, or event-sourcing architecture. The code follows standard Phoenix 1.8 and LiveView patterns based on the project reference guidelines.

## ADR Violations

None identified. The plan did not cite specific ADRs, and the implementation follows general Phoenix LiveView conventions.

## Blocking Issues

1. **Tab state management bug in `home.html.heex`**
   
   **Problem:** Both tab buttons use `JS.toggle_class("is-active", to: ".section-tab")`, which toggles the class on ALL tab elements. When a user clicks the same tab twice, both tabs end up with `is-active`:
   
   - Click Members: toggle removes from Conversations, adds to Members ✓
   - Click Conversations: toggle removes from Members, adds to Conversations ✓  
   - Click Conversations AGAIN: toggle removes from Conversations, adds to Members, then `add_class` adds back to Conversations → both tabs active ✗
   
   **Impact:** Violates ARIA tablist patterns (two tabs cannot both be `aria-selected="true"`). Users clicking the same tab would see both tabs styled as active.
   
   **Evidence:** Lines in `home.html.heex`:
   ```heex
   phx-click={
     JS.toggle_class("is-active", to: ".section-tab")  # ← Bug: should be remove_class
     |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
     |> JS.add_class("is-active")
     ...
   }
   ```
   
   **Fix Required:** Change `JS.toggle_class` to `JS.remove_class` in both tab buttons (Conversations and Members).

## Bounded-Safe Fixes

1. **Add missing ARIA attributes to tab panels**
   
   The panels lack required `role="tabpanel"` and `aria-labelledby` attributes per WAI-ARIA tabs pattern:
   
   - Add `role="tabpanel"` to both `#conversations-panel` and `#members-panel`
   - Add `id` attributes to tab buttons (e.g., `id="conversations-tab"`, `id="members-tab"`)
   - Add `aria-labelledby="conversations-tab"` to `#conversations-panel`, same for Members
   
   This improves accessibility without changing behavior.

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Template-level path construction logic** (`home.html.heex` lines ~42-48)
   
   **Smell:** Club ID format detection (`UUID` vs slug) is performed in the template using a regex match, then passed to `member_compose_path/2` helper. This mixes presentation with routing logic.
   
   ```heex
   <% club_id_source =
     if String.match?(@selected_club.id, ~r/^[0-9a-f]{8}-...$/i) do
       "by-id/#{@selected_club.id}"
     else
       "by-slug/#{@selected_club.slug}"
     end
   %>
   <.link navigate={member_compose_path(@selected_club, club_id_source)} ...>
   ```
   
   **Why judgement:** This works, but centralizing club-path construction in a context module or LiveView helper might improve maintainability. The regex-in-template approach couples routing logic to the view. However, it's localized and functional, so deferring refactoring is reasonable.

2. **No interactive tab-clicking tests**
   
   **Smell:** The LiveView tests verify initial render state (tab controls present, default panel shown) but not the tab-switching interaction or ARIA state updates after clicking.
   
   **Why judgement:** Client-side JS interactions tested via LiveView tests are limited without browser integration tests (Wallaby/Hound). The current test coverage is appropriate for LiveView tests, but the lack of click-behavior coverage allowed the `toggle_class` bug to pass. This is a testing-strategy decision: accept LiveView render tests + manual QA for JS interactions, or invest in browser-level tests.

## Suggested Fixes

### Fix 1: Correct tab state management (BLOCKING)

In `lib/memba_web/controllers/member/club_home_html/home.html.heex`, replace `JS.toggle_class` with `JS.remove_class` in both tab buttons:

**Conversations tab (line ~51):**
```heex
phx-click={
  JS.remove_class("is-active", to: ".section-tab")  # ← Changed from toggle_class
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#conversations-panel")
  |> JS.hide(to: "#members-panel")
}
```

**Members tab (line ~69):**
```heex
phx-click={
  JS.remove_class("is-active", to: ".section-tab")  # ← Changed from toggle_class
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#members-panel")
  |> JS.hide(to: "#conversations-panel")
}
```

### Fix 2: Add ARIA attributes to panels (BOUNDED-SAFE)

**Tab buttons:** Add `id` attributes
```heex
<button id="conversations-tab" class="section-tab is-active" role="tab" ...>
<button id="members-tab" class="section-tab" role="tab" ...>
```

**Panels:** Add `role` and `aria-labelledby`
```heex
<div class="section-panel" id="conversations-panel" role="tabpanel" aria-labelledby="conversations-tab">
<div class="section-panel" id="members-panel" role="tabpanel" aria-labelledby="members-tab" style="display: none;">
```

## Validation Notes

- **Dev check:** Passed (85 scenarios green, 523 steps passed)
- **Automated test coverage:** Verifies initial render state; tab controls present; default panel shown; action visibility gated by permissions; content in correct panels. Does NOT verify click interactions or ARIA state updates.
- **Blocking bug not caught:** The `toggle_class` issue would only manifest when a user clicks the same tab twice—a scenario not covered by static render tests.
- **Manual validation:** After applying Fix 1, manually test: (1) click Members → verify only Members is active; (2) click Conversations → verify only Conversations is active; (3) click Conversations again → verify only Conversations remains active (not both).

---

**Reject Reason:** The tab state management bug (Fix 1) is a clear behavioral defect violating ARIA best practices. The fix is trivial (one-word change from `toggle_class` to `remove_class`), but the bug would be user-visible if someone clicks the same tab twice. Given the high confidence in the diagnosis and the minimal fix required, this blocks merge until corrected.