# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

This iteration is Phoenix/LiveView presentation work: HEEx markup, CSS, `Phoenix.LiveView.JS` client-side tab switching, and render/controller tests for the club-home section tabs. It does not appear to touch domain modelling, Commanded aggregates, projections, event streams, CQRS boundaries, read models, or ADR-governed infrastructure.

## ADR violations

None identified.

## Blocking issues

1. **Club-home tab active-state JS is non-idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use:

   ```elixir
   JS.toggle_class("is-active", to: ".section-tab")
   |> JS.add_class("is-active")
   ```

   This is not idempotent. If the user clicks the already-active tab:

   - `toggle_class` removes `is-active` from the active tab and adds it to the inactive tab.
   - `add_class("is-active")` then re-adds it to the clicked tab.
   - Result: both tab buttons can have the visual active class.

   The `aria-selected` attributes are reset separately, so this can also create visual/ARIA divergence: one tab is announced selected while both appear active. That is a user-visible defect in the core client-side interaction introduced by this iteration.

2. **ARIA tab/panel relationships are incomplete**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The implementation has the basic tab shape, but the tab/panel relationships appear incomplete for a real tab interface. The plan explicitly introduces an app-like tabbed interface and calls out keyboard/ARIA behaviour in validation.

   Missing/required relationships include:

   - Stable `id` on each tab button.
   - `aria-controls` from each tab to its panel.
   - `role="tabpanel"` on each panel.
   - `aria-labelledby` from each panel back to its controlling tab.

   This should be fixed before acceptance because the iteration’s primary UI pattern is a tab interface, not merely two buttons with show/hide behaviour.

3. **Client-side tab behaviour lacks automated protection**

   `dev ci` passed, but the current coverage appears to verify static/default render state only: both controls render, Conversations is the default panel, actions are present/gated, and both panels’ content exists.

   The important interaction is implemented entirely with `Phoenix.LiveView.JS`, with no server round-trip. The `toggle_class` defect passed the suite because no automated test exercises or structurally verifies the generated JS command sequence.

   This needs either:

   - Browser-level coverage that clicks tabs repeatedly, or
   - Structural assertions over rendered `phx-click` JS commands, or
   - An explicit human decision that this client-only behaviour remains manual-only for this slice.

4. **Review repair did not modify the implementation**

   The repair attempt produced no working-tree diff and referenced paths that do not match the reviewed file path. The current review context still lists the synthesized blockers as open. Therefore the previous rejection conditions should be treated as unresolved.

## Bounded-safe fixes

1. Replace `JS.toggle_class("is-active", to: ".section-tab")` with `JS.remove_class("is-active", to: ".section-tab")` in both tab click handlers.

2. Add complete tab/panel ARIA wiring:
   - `id` on each tab button.
   - `aria-controls` on each tab button.
   - `role="tabpanel"` on each panel.
   - `aria-labelledby` on each panel.

3. Add focused regression coverage for both rendered tab click handlers:
   - Assert `remove_class` is used.
   - Assert `toggle_class` is absent.
   - Assert `aria-selected` reset/set commands are present.
   - Assert expected panel/action show-hide commands are present.
   - Assert no server `push` event is used for tab switching.

4. Optionally scope `.section-tab` selectors to the club-home tab group wrapper to reduce future fragility if another tab group is added to the page.

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level route/source construction for `club_id_source`.  
   **Why it may need human judgement:** The template appears to inspect whether the selected club identifier is UUID-like and constructs a `by-id/...` or `by-slug/...` source. This is functional locally, but it couples route/source-format knowledge into HEEx. If this pattern repeats, it should likely move to a helper or be prepared as an assign before rendering.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines.  
   **Why it may need human judgement:** With two tabs, explicit duplication is acceptable. The plan notes future IA expansion, however, so additional tabs could make the duplicated JS pipelines drift-prone. A helper may become worthwhile once the pattern grows.

## Suggested fixes

### 1. Make tab active-state transitions idempotent

For the Conversations tab handler:

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

For the Members tab handler:

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
```

```heex
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

### 3. Add targeted regression coverage

Add a focused test that parses the rendered tab buttons and inspects/decodes their `phx-click` JS command payloads. It should cover both tabs and verify:

- Active state is cleared with `remove_class`, not `toggle_class`.
- `aria-selected` is reset for all tabs and set for the selected tab.
- The correct panel and action containers are shown/hidden.
- No server event push is used for tab switching.

## Validation notes

- `dev ci` passed before review.
- Acceptance suite passed: 85 scenarios, 523 steps.
- No acceptance feature-file changes are needed.
- Static plan fidelity appears broadly satisfied: tabs render, Conversations defaults active, per-section actions are present, invite gating exists, email affordance is preserved, and Members content renders.
- Rejection is due to a real client-side interaction defect, incomplete tab accessibility wiring, and missing automated protection for the new client-only behaviour.
- After repair, rerun `dev check` on the repaired state and manually verify repeated tab clicks:
  1. Conversations initially active.
  2. Click Members; only Members active.
  3. Click Members again; only Members remains active.
  4. Click Conversations; only Conversations active.
  5. Click Conversations again; only Conversations remains active.
  6. Panels and per-tab actions show/hide correctly.
  7. Tab/panel ARIA attributes are present and consistent.