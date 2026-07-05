# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

This iteration is a Phoenix/LiveView presentation-layer change: HEEx, CSS, client-side `Phoenix.LiveView.JS` wiring, and render tests for the club-home tab UI. The reviewed scope does not appear to touch domain modelling, Commanded aggregates, event streams, projections, CQRS boundaries, read models, or ADR-governed infrastructure.

## ADR violations

None identified.

## Blocking issues

1. **Tab active-state JS is non-idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use `JS.toggle_class("is-active", to: ".section-tab")` before adding `is-active` to the clicked tab.

   This fails when a user clicks the already-active tab:

   - Initial state: Conversations has `is-active`; Members does not.
   - User clicks Conversations.
   - `toggle_class` removes `is-active` from Conversations and adds it to Members.
   - `add_class("is-active")` adds it back to Conversations.
   - Result: both tabs are visually active.

   The same issue applies when Members is already active and clicked again. This is a user-visible defect in the core tab interaction and can leave visual state diverging from `aria-selected`.

2. **ARIA tab/panel relationships are incomplete**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The implementation has the basic tab shape, but the accessible relationships are incomplete for a real tab interface.

   The tab pattern should include:

   - Stable tab IDs.
   - `aria-controls` from each tab to its panel.
   - `role="tabpanel"` on each panel.
   - `aria-labelledby` from each panel back to its tab.

   Because this iteration explicitly introduces an app-like tabbed interface and the validation plan calls out ARIA behaviour, this should be fixed before merge.

3. **Client-side tab behaviour is not protected by automated coverage**

   `dev ci` passed, but the current automated coverage appears to verify static/default render state only: both controls render, Conversations is default, actions are present/gated, and both panels’ content exists.

   The important interaction in this slice is implemented entirely with `Phoenix.LiveView.JS`, with no server round-trip. The non-idempotent `toggle_class` defect passed because no test exercises or structurally verifies the generated JS command sequence.

   This needs one of:

   - Browser-level JS interaction coverage, if supported by the project.
   - Structural assertions over the rendered `phx-click` JS commands.
   - An explicit human decision that this client-only interaction remains manual-only for this slice.

## Bounded-safe fixes

1. Replace `JS.toggle_class/2` with `JS.remove_class/2` in both tab click handlers.

2. Add complete tab/panel ARIA wiring:
   - Tab IDs.
   - Tab `aria-controls`.
   - Panel `role="tabpanel"`.
   - Panel `aria-labelledby`.

3. Add targeted regression coverage for the rendered LiveView JS commands:
   - Assert `remove_class` is used.
   - Assert `toggle_class` is absent.
   - Assert `aria-selected` reset/set commands are present.
   - Assert the expected panel/action show/hide commands are present.
   - Assert no server push event is used for tab switching.

4. Optionally scope selectors such as `.section-tab` to a club-home tab wrapper. This is not required for the current two-tab page, but it would reduce fragility if another tab group is added later.

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level route/source construction for `club_id_source`.  
   **Why it may need human judgement:** The template appears to inspect whether the selected club identifier is UUID-like and then choose a `by-id/...` or `by-slug/...` path source. This works locally, but it couples route/source-format knowledge to HEEx. If this pattern repeats, it should move into a helper or assign prepared before rendering.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines.  
   **Why it may need human judgement:** With only Conversations and Members, the duplication is acceptable and easy to read. If future slices add more tabs, extracting a small helper for tab switching would reduce drift risk.

## Suggested fixes

### 1. Make tab state idempotent

Use `remove_class`, not `toggle_class`, before activating the clicked tab.

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

And for Members:

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

### 2. Complete ARIA relationships

Example shape:

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

### 3. Add regression coverage for JS wiring

A bounded test can parse the rendered tab buttons and decode/assert the `phx-click` command payloads. It should verify both tab handlers clear active state with `remove_class`, never use `toggle_class`, set `aria-selected` correctly, and show/hide the correct panel/action elements.

After applying fixes, rerun `dev check` on the exact repaired state.

## Validation notes

- `dev ci` passed before review.
- Acceptance suite passed: 85 scenarios, 523 steps.
- No acceptance feature-file changes are needed.
- Static plan-conformance appears broadly satisfied: tabs render, Conversations is default, actions are placed per section, invite gating is present, the email affordance is preserved, and Members content renders.
- The rejection is for a real client-side behavioural defect plus missing automated protection for that interaction.
- Manual validation after repair should include:
  1. Load club home.
  2. Confirm Conversations is initially active.
  3. Click Members; only Members is active.
  4. Click Members again; only Members remains active.
  5. Click Conversations; only Conversations is active.
  6. Click Conversations again; only Conversations remains active.
  7. Confirm panels and per-tab actions show/hide correctly.
  8. Confirm tab/panel ARIA attributes are present and consistent.