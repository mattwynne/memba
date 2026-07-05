# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

No ADR cited by the iteration plan appears to govern this UI-only club-home tab implementation. The touched behaviour is Phoenix/LiveView presentation wiring, CSS, and controller/LiveView render tests; it does not appear to change domain modelling, Commanded aggregates, projections, event streams, CQRS boundaries, or object responsibility boundaries.

## ADR violations

None identified.

## Blocking issues

1. **Repeated tab clicks can leave both tabs visually active**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use `JS.toggle_class("is-active", to: ".section-tab")` before adding `is-active` to the clicked tab.

   That makes the active-state transition non-idempotent:

   - Initial state: Conversations active, Members inactive.
   - Click Conversations again.
   - `toggle_class` removes `is-active` from Conversations and adds it to Members.
   - `JS.add_class("is-active")` then adds it back to Conversations.
   - Result: both tabs have `is-active`.

   The same issue applies when Members is already active and clicked again.

   This is a user-visible behavioural defect in the plan’s core capability: a tabbed interface with one active section. It also risks visual state diverging from `aria-selected`, which is especially undesirable for a tablist.

2. **Client-side tab interaction is not covered by automated feedback**

   `dev ci` passed, and the render tests appear to cover the static/default state: both tab controls render, Conversations is default, actions are placed/gated correctly, and both panels’ content exists.

   However, the important behaviour in this slice is implemented entirely with `Phoenix.LiveView.JS`, with no server round-trip. The current automated coverage did not exercise the client-side state transition and therefore missed the repeated-click defect above.

   This should either receive a suitable implementation/test pass using whatever browser-level JS coverage the project supports, or an explicit human decision that this client-only interaction is manually verified for this slice.

## Bounded-safe fixes

1. **Replace `JS.toggle_class/2` with `JS.remove_class/2` in both tab handlers**

   This makes the tab-state transition idempotent: clear active state from all tabs, then mark the clicked tab active.

2. **Complete the ARIA tab/panel relationships**

   The implementation has `role="tablist"`, `role="tab"`, and `aria-selected`, but the panels should also be explicitly connected to the tabs.

   Add:

   - Stable IDs on tab buttons.
   - `aria-controls` from each tab to its panel.
   - `role="tabpanel"` on each panel.
   - `aria-labelledby` from each panel back to its tab.

3. **Consider scoping tab JS selectors to this tablist/panel group**

   The current selector style, e.g. `.section-tab`, is broad. It is safe while the page has only one `section-tabs` instance, but scoping to a club-home tab group ID or data attribute would make future additions less fragile.

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level route/source construction for `club_id_source`.  
   **Why it may need human judgement:** The template appears to decide whether to use a `by-id/...` or `by-slug/...` route segment by inspecting the selected club ID. This works locally, but it puts routing-source knowledge in HEEx. If this pattern appears in more places, it would be healthier to centralize it in a route/view helper or assign prepared by the controller/LiveView.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines.  
   **Why it may need human judgement:** With two tabs, explicit duplicated pipelines are understandable and easy to read. If the club-home IA grows to more tabs, this duplication could become drift-prone. Extraction is not necessary now, but the pattern should be watched in follow-on slices.

## Suggested fixes

### Required behavioural fix

Update both tab click handlers from `toggle_class` to `remove_class`.

For the Conversations tab:

```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#conversations-panel")
  |> JS.hide(to: "#members-panel")
}
```

For the Members tab:

```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#members-panel")
  |> JS.hide(to: "#conversations-panel")
}
```

### Accessibility polish

Use explicit tab/panel IDs and relationships:

```heex
<button
  id="conversations-tab"
  class="section-tab is-active"
  role="tab"
  aria-selected="true"
  aria-controls="conversations-panel"
>
  Conversations
</button>

<button
  id="members-tab"
  class="section-tab"
  role="tab"
  aria-selected="false"
  aria-controls="members-panel"
>
  Members
</button>

<div
  id="conversations-panel"
  class="section-panel"
  role="tabpanel"
  aria-labelledby="conversations-tab"
>
  ...
</div>

<div
  id="members-panel"
  class="section-panel"
  role="tabpanel"
  aria-labelledby="members-tab"
  style="display: none;"
>
  ...
</div>
```

After applying fixes, rerun the required project check on the exact fixed state.

## Validation notes

- `dev ci` passed in the review context.
- Acceptance suite passed: 85 scenarios, 523 steps.
- The implementation appears broadly plan-conforming in static render shape: tabs, default Conversations panel, per-section actions, manage-members gating, moved email affordance, and Members panel content.
- The rejection is for a client-side behavioural defect not caught by the current tests.
- Manual validation after the fix should include:
  1. Load club home.
  2. Confirm Conversations is initially active and Members is inactive.
  3. Click Members; only Members is active.
  4. Click Members again; only Members remains active.
  5. Click Conversations; only Conversations is active.
  6. Click Conversations again; only Conversations remains active.
  7. Confirm panels and per-tab actions still show/hide as intended.