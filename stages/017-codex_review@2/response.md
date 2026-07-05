# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

This iteration appears to be a presentation-layer Phoenix/LiveView/HEEx/CSS change for the club-home tab UI. The provided evidence does not show changes to domain modeling, Commanded aggregates, projections, event streams, read models, CQRS boundaries, or object responsibility boundaries. I found no accepted ADR conflict in the reviewed scope.

## ADR violations

None identified.

## Blocking issues

1. **Club-home tab active-state JS is non-idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use `JS.toggle_class("is-active", to: ".section-tab")` and then add `is-active` to the clicked tab.

   That works when switching from the inactive tab to the active tab, but fails when clicking the already-active tab:

   - Initial state: Conversations has `is-active`; Members does not.
   - User clicks Conversations again.
   - `toggle_class` removes `is-active` from Conversations and adds it to Members.
   - `add_class("is-active")` adds it back to Conversations.
   - Result: both tabs are visually active.

   The same failure can occur with Members. This is a user-visible defect in the core tab behaviour and can create divergence between visual active state and `aria-selected`.

2. **ARIA tab/panel relationships are incomplete**

   The implementation includes a tablist/tabs shape, but the tab panels are not fully wired as accessible tab panels in the evidence reviewed.

   The tab pattern should include stable relationships between each tab and its controlled panel:

   - tab `id`
   - tab `aria-controls`
   - panel `role="tabpanel"`
   - panel `aria-labelledby`

   Without these, the UI is visually tab-like but incomplete for assistive technology. Because this slice explicitly introduces an app-like tabbed interface and the validation plan calls out keyboard/ARIA behaviour, this should be fixed before acceptance.

3. **Automated coverage does not protect the client-side tab behaviour**

   `dev ci` passed, but the current tests appear to cover the static/default render state: tab controls render, Conversations is default, actions are placed/gated correctly, and both panels’ content exists.

   The important behaviour in this slice is implemented entirely with `Phoenix.LiveView.JS`, with no server round trip. The non-idempotent `toggle_class` defect passed the suite because no test inspects or exercises the generated client-side JS transition.

   This needs either:

   - targeted structural assertions over the rendered `phx-click` JS command payloads, or
   - browser-level JS interaction coverage if the project supports it, or
   - an explicit human decision that this specific client-only interaction remains manual-only coverage.

## Bounded-safe fixes

1. **Replace tab-wide `toggle_class` with tab-wide `remove_class`**

   In both tab click handlers, clear active state from all tabs, then add active state to the clicked tab.

2. **Add complete tab/panel ARIA attributes**

   Add stable IDs and relationships for both tabs and both panels.

3. **Add targeted regression coverage for the rendered JS commands**

   A low-risk test can decode/assert the rendered `phx-click` command sequence and verify that it uses `remove_class`, not `toggle_class`, and that it does not push a server event.

4. **Optionally scope tab selectors to the club-home tab group**

   Selectors such as `.section-tab` are safe while there is only one tab group on the page, but scoping them to a wrapper ID/data attribute would reduce future fragility if another `section-tabs` component appears on the page.

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level route/source construction for `club_id_source`.  
   **Why it may need human judgement:** The template appears to inspect whether the selected club identifier looks like a UUID and then construct either a `by-id/...` or `by-slug/...` path source. This works locally, but it couples route/source-format knowledge to HEEx. If this pattern repeats, it should probably move into a helper or be assigned before rendering.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines.  
   **Why it may need human judgement:** With only Conversations and Members, explicit duplication is acceptable. However, the plan notes future IA expansion, and an About tab is deferred. If additional tabs are added, extracting a small helper for tab switching may prevent drift.

## Suggested fixes

### Required behavioural fix

Change both tab handlers from `JS.toggle_class/2` to `JS.remove_class/2`.

For Conversations:

```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#conversations-panel")
  |> JS.hide(to: "#members-panel")
  |> JS.show(to: "#section-tabs-action-conversations")
  |> JS.hide(to: "#section-tabs-action-members")
}
```

For Members:

```elixir
phx-click={
  JS.remove_class("is-active", to: ".section-tab")
  |> JS.set_attribute({"aria-selected", "false"}, to: ".section-tab")
  |> JS.add_class("is-active")
  |> JS.set_attribute({"aria-selected", "true"})
  |> JS.show(to: "#members-panel")
  |> JS.hide(to: "#conversations-panel")
  |> JS.show(to: "#section-tabs-action-members")
  |> JS.hide(to: "#section-tabs-action-conversations")
}
```

### Required ARIA polish

Use explicit tab/panel relationships, for example:

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

### Required coverage fix or human decision

Preferred bounded test fix: add structural assertions that decode the rendered `phx-click` JS payloads for both tabs and assert:

- `remove_class` is present for `.section-tab`
- `toggle_class` is absent
- `aria-selected` is reset to false for all tabs and true for the selected tab
- the expected panel/action show/hide commands are present
- no server `push` event is used

After code/test changes, rerun the required project check on the exact repaired state.

## Validation notes

- `dev ci` passed before review.
- Acceptance suite passed: 85 scenarios, 523 steps.
- Acceptance feature files appear unchanged.
- The implementation is broadly plan-conforming in static render shape: tabs, default Conversations panel, per-tab actions, manage-member gating, moved email affordance, and Members panel content are present.
- The rejection is for a client-side behavioural defect and missing/insufficient automated protection around the new tab JS wiring.
- Manual validation after the fix should include:
  1. Load club home.
  2. Confirm Conversations is initially active.
  3. Click Members; only Members is active.
  4. Click Members again; only Members remains active.
  5. Click Conversations; only Conversations is active.
  6. Click Conversations again; only Conversations remains active.
  7. Confirm panels and per-tab actions show/hide correctly.
  8. Confirm tab/panel ARIA attributes are present and consistent.