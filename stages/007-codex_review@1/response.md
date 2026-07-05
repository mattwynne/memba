# Iteration 045 Implementation Review

## Decision: REJECT

## Confidence: High

## ADR conformance: PASS

No ADR cited by the iteration plan appears to govern this presentation-only LiveView/tab UI change. The implementation does not appear to touch domain modeling, Commanded aggregates, projections, event streams, read models, or CQRS infrastructure. I found no ADR-level architecture conflict in the provided evidence.

## ADR violations

None identified.

## Blocking issues

1. **Client-side tab state can show both tabs as active**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   The tab click handlers use:

   ```elixir
   JS.toggle_class("is-active", to: ".section-tab")
   ```

   followed by adding `is-active` back to the clicked tab.

   This works when switching from one tab to the other, but clicking the currently active tab toggles `is-active` onto the inactive tab and then re-adds it to the clicked tab. Result: both tabs can be styled active at the same time.

   Example from the default state:

   - Conversations has `is-active`
   - Members does not
   - User clicks Conversations again
   - `toggle_class` removes `is-active` from Conversations and adds it to Members
   - `add_class("is-active")` adds it back to Conversations
   - Both tabs are visually active

   The panels still appear to be shown/hidden correctly, and `aria-selected` may still be set on only the clicked tab, but the visual selected state and ARIA selected state can diverge. This violates the intended tab behavior in the plan.

2. **The automated coverage did not exercise the client-side tab transition behavior**

   `dev check`/`dev ci` passed, but the current tests appear to verify the initial render state and permissions/content placement only. Because this tab interaction is implemented entirely with `Phoenix.LiveView.JS` and no server round trip, normal LiveView render assertions do not catch the broken repeated-click behavior above.

   This is a behavioral gap in the implemented UI. The fix should either add suitable automated browser-level coverage if the project has a supported path for client-side JS interaction tests, or receive an explicit human decision that this small client-side interaction remains manually verified.

## Bounded-safe fixes

1. **Replace tab-wide `toggle_class` with tab-wide `remove_class`**

   This is a small, safe behavior-preserving fix for the intended one-active-tab invariant.

2. **Add complete ARIA relationships for the tab panels**

   The tabs have `role="tab"` / `aria-selected`, but the panels should also be connected to the tabs.

   Add:

   - Stable IDs on tab buttons, e.g. `id="conversations-tab"` and `id="members-tab"`
   - `aria-controls` on each tab button
   - `role="tabpanel"` on each panel
   - `aria-labelledby` on each panel

   This improves accessibility and keeps the implementation closer to the WAI-ARIA tabs pattern without changing product behavior.

## Judgement-worthy non-blocking code-health findings

1. **Template-level routing/path source logic**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   **Smell:** The template appears to compute a `club_id_source` by inspecting whether `@selected_club.id` looks like a UUID and then choosing either a `by-id/...` or `by-slug/...` path segment.

   **Why it may need human judgement:** This works locally, but it couples routing/source-format knowledge to the HEEx template. If the same routing distinction appears elsewhere, it would be healthier to centralize it in a view/helper or route/path helper so templates only render prepared URLs. This does not need to block the iteration.

2. **Duplicated tab-switching JS pipelines**

   **File:** `lib/memba_web/controllers/member/club_home_html/home.html.heex`

   **Smell:** The Conversations and Members tabs likely contain near-identical `JS` pipelines that differ only in selected panel/action targets.

   **Why it may need human judgement:** With only two tabs, duplication is acceptable and probably clearer. If additional club-home tabs are planned, this may become drift-prone. Consider extracting a small helper only if the pattern repeats in later slices.

## Suggested fixes

### Required fix

Change both tab click handlers from `JS.toggle_class/2` to `JS.remove_class/2`.

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

Use explicit tab/panel relationships:

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

After applying the fix, rerun the project check required by the workflow.

## Validation notes

- `dev check`/`dev ci` passed in the provided review context.
- Acceptance suite passed: 85 scenarios, 523 steps.
- The implementation appears broadly plan-conforming: tab controls, default Conversations panel, per-section actions, member-management gating, and both panels’ content are represented.
- The blocking issue is not caught by the current automated tests because it is a client-only `Phoenix.LiveView.JS` state transition.
- Manual validation after the fix should include:
  1. Load club home.
  2. Confirm Conversations is initially active.
  3. Click Members; only Members is active.
  4. Click Members again; only Members remains active.
  5. Click Conversations; only Conversations is active.
  6. Click Conversations again; only Conversations remains active.