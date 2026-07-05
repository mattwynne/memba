# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

This iteration is presentation-layer work: Phoenix/HEEx markup, CSS, `Phoenix.LiveView.JS` client-side tab switching, and render-level tests for the club-home tab interface. The reviewed scope does not appear to touch domain modelling, Commanded aggregates, projections, event streams, CQRS boundaries, read models, or ADR-governed infrastructure.

## ADR violations

None identified.

## Blocking issues

1. **Club-home tab active-state JS is non-idempotent**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use `JS.toggle_class("is-active", to: ".section-tab")` before adding `is-active` to the clicked tab.

   This fails when a user clicks the currently-active tab:

   - Initial state: Conversations has `is-active`; Members does not.
   - User clicks Conversations again.
   - `toggle_class` removes `is-active` from Conversations and adds it to Members.
   - `add_class("is-active")` re-adds it to Conversations.
   - Result: both tabs are visually active.

   The same defect applies to Members once it is active. This is a user-visible behaviour bug in the core interaction introduced by the iteration.

2. **ARIA tab/panel relationships are incomplete**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The implementation has the basic tab shape, but the accessible relationships for a real tab interface are incomplete. The tab pattern should include stable relationships between each tab and its panel:

   - tab `id`
   - tab `aria-controls`
   - panel `role="tabpanel"`
   - panel `aria-labelledby`

   Because this iteration explicitly introduces an app-like tabbed interface and the validation plan calls out keyboard/ARIA behaviour, this should be fixed before acceptance.

3. **Client-side tab behaviour is not protected by automated coverage**

   `dev ci` passed, but the current automated coverage appears to verify static/default render state only: both tab controls render, Conversations is default, actions are placed/gated correctly, and both panels’ content exists.

   The important interaction in this slice is implemented entirely with `Phoenix.LiveView.JS`, without a server round-trip. The `toggle_class` defect passed the suite because no test exercises or structurally verifies the generated client-side JS command sequence.

   This needs either targeted automated coverage for the rendered JS wiring, browser-level interaction coverage, or an explicit human decision that this client-only interaction remains manual-only for this slice.

4. **Repair attempts did not change the actual implementation**

   The review repair attempts reported that fixes were already present, but they referenced different/wrong file paths and produced no working-tree diff. Verification failed because no changes were made after the review blockers were identified.

   As a result, the synthesized blockers should still be considered open.

## Bounded-safe fixes

1. Replace `JS.toggle_class("is-active", to: ".section-tab")` with `JS.remove_class("is-active", to: ".section-tab")` in both tab click handlers.

2. Add complete tab/panel ARIA wiring:
   - `id` on each tab button.
   - `aria-controls` from each tab to its panel.
   - `role="tabpanel"` on each panel.
   - `aria-labelledby` from each panel back to its tab.

3. Add targeted regression coverage that decodes or inspects the rendered `phx-click` JS command payloads for both tab buttons and asserts:
   - `remove_class` is used for clearing active tab state.
   - `toggle_class` is absent.
   - `aria-selected` is reset/set as expected.
   - expected panel/action show-hide commands are present.
   - no server push event is used for tab switching.

4. Optionally scope selectors such as `.section-tab` to a club-home tab wrapper to reduce future fragility if another tab group is introduced on the same page.

## Judgement-worthy non-blocking code-health findings

1. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Template-level route/source construction for `club_id_source`.  
   **Why it may need human judgement:** The template appears to inspect whether the selected club identifier is UUID-like and then constructs either a `by-id/...` or `by-slug/...` source. This works locally, but it couples route/source-format knowledge to HEEx. If this pattern repeats, it should probably move into a helper or be prepared before rendering.

2. **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`  
   **Smell:** Duplicated tab-switching JS pipelines.  
   **Why it may need human judgement:** With only Conversations and Members, explicit duplication is acceptable. The plan notes future IA expansion, however, so if more tabs are added, extracting a small helper for tab switching would reduce drift risk.

## Suggested fixes

### 1. Make tab active-state transitions idempotent

Change both tab handlers from `toggle_class` to `remove_class`:

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

Use stable IDs and explicit tab/panel relationships:

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

### 3. Add regression coverage for JS wiring

Add a focused test that parses the rendered tab buttons and decodes/asserts the `phx-click` commands. It should cover both tabs and verify the operation sequence is idempotent and client-only.

## Validation notes

- `dev ci` passed before review.
- Acceptance suite passed: 85 scenarios, 523 steps.
- No acceptance feature-file changes are needed.
- Static plan fidelity appears broadly satisfied: tabs render, Conversations is default, per-section actions are present, manage-members gating is present, email affordance is preserved, and Members content renders.
- The rejection is for a real client-side interaction defect plus incomplete ARIA wiring and missing automated protection for the new JS behaviour.
- After repair, rerun the required project check on the repaired state and manually verify:
  1. Conversations is initially active.
  2. Clicking Members activates only Members.
  3. Clicking Members again leaves only Members active.
  4. Clicking Conversations activates only Conversations.
  5. Clicking Conversations again leaves only Conversations active.
  6. Panels and per-tab actions show/hide correctly.
  7. Tab/panel ARIA attributes are present and consistent.