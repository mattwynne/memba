# Calm LiveView reconnection feedback

Date: 2026-09-12
Status: ready

## Goal

Let routine LiveView reconnections after a browser tab sleeps complete without visual noise, while giving calm, accurate feedback when a client/network interruption or server interruption lasts longer than 1.5 seconds.

## Background / Context

Production investigation on 2026-09-12 found that Memba had not crashed: the Fly Machine and BEAM had remained up continuously, the current release had produced no HTTP 5xx responses, PostgreSQL and the application supervisors were healthy, and a fresh WebSocket handshake succeeded. The observed tab recovered by itself. The evidence points to the browser suspending its WebSocket while the tab slept and LiveView reconnecting when the tab woke.

Memba currently uses the Phoenix-generated disconnected-state treatment in `MembaWeb.Layouts.flash_group/1`. It presents client and server interruptions as large red daisyUI error toasts with a close button. LiveView 1.1.30 already supports delaying `phx-disconnected` commands through the `LiveSocket` `disconnectedTimeout` option; its default is 500ms. A longer presentation delay can suppress routine wake-up reconnect noise without delaying reconnection itself.

Matt reviewed and approved the compact bottom-centre raw HTML prototype for this iteration. The two interruption types retain distinct wording but share the same calm visual treatment.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md): **partially addresses.** This iteration makes a global member-visible system state simpler, quieter, and more app-like. It does not resolve the broader cross-device design direction described by the note.
- No captured problem directly describes noisy LiveView tab-wake reconnection feedback.

## Scope

### In scope

- Configure the production LiveSocket with `disconnectedTimeout: 1500` milliseconds.
- Preserve LiveView's immediate reconnect attempts; delay only execution of the disconnected-state presentation commands.
- Replace the generated client and server error toasts with compact, bottom-centre connection-status pills based on the approved prototype.
- Use `Connection paused — reconnecting…` for the client/network interruption state.
- Use `Memba is temporarily unavailable — retrying…` for the server interruption state.
- Apply the treatment through the shared flash group so it is consistent across public, member, and Staff LiveViews.
- Keep the current page visible while reconnecting.
- Remove dismiss/close controls from these transient connection states.
- Hide the status automatically when LiveView reconnects.
- Provide responsive positioning, polite assistive-technology announcement, and reduced-motion behaviour.
- Keep ordinary informational and error flash messages unchanged.

### Out of scope

- Changing LiveView's reconnect algorithm, retry cadence, transport fallback, or server connection handling.
- Adding a prolonged-failure state, elapsed-time copy change, manual retry, or Reload button.
- Detecting or explaining the precise network failure to the user.
- Connectivity telemetry, logging, alerting, or production health monitoring.
- Restyling ordinary success, informational, validation, or error flash messages.
- Adding a new third-party UI or toast dependency.
- Changing page content or preserving additional client-side state across a LiveView remount.

## Iteration Type

Behaviour-facing UX polish.

The user-observable rule is: a connection interruption shorter than 1.5 seconds produces no reconnect indicator; a longer interruption presents the appropriate calm status until connection returns.

## Acceptance Scenarios / Feature Files

BDD decision: **Not useful for this slice.**

The behaviour is user-visible, but it is a technical transport timing and presentation state rather than a product-domain rule. Expressing millisecond timing, browser suspension, LiveView root error classes, and WebSocket reconnection in Gherkin would couple stakeholder documentation to infrastructure and add little modelling value. Focused component/configuration tests and manual browser simulation are clearer.

No acceptance feature files or scenarios change.

## Designs

The approved design source is [`reconnect-indicator-prototype.html`](reconnect-indicator-prototype.html), a self-contained raw HTML prototype reviewed interactively by Matt on 2026-09-12.

It defines:

- a compact fixed pill centred near the bottom safe area;
- Memba paper, sage, ink, and line tokens;
- a subtle spinner rather than an error icon;
- one concise status line;
- no close button;
- a short entrance/exit transition with a reduced-motion fallback; and
- interactive controls demonstrating a brief hidden reconnect, a longer client interruption, a server interruption, and automatic dismissal.

This prototype is the implementation reference under Matt's explicit override to use a collaboratively reviewed raw HTML design in this Pi planning session. DesignSync was not used. Implementation should translate the prototype into existing Memba Tailwind/theme conventions rather than shipping prototype-only controls or duplicating page-shell markup.

## Acceptance Criteria

- `LiveSocket` is configured with `disconnectedTimeout: 1500`.
- LiveView begins reconnecting immediately on disconnection; the 1.5-second value affects only when `phx-disconnected` presentation commands execute.
- If LiveView reconnects before 1.5 seconds elapse, neither connection-status pill becomes visible.
- If a client/network interruption lasts at least 1.5 seconds, the client status becomes visible with the exact text `Connection paused — reconnecting…`.
- If a server interruption lasts at least 1.5 seconds, the server status becomes visible with the exact text `Memba is temporarily unavailable — retrying…`.
- The client and server states share the approved compact bottom-centre visual treatment while retaining stable, distinct DOM IDs and LiveView selectors.
- Only the state matching LiveView's client/server error class is shown.
- The current page remains visible and is not dimmed, blocked, or replaced while reconnecting.
- The connection state has no close button and does not invite user action.
- A successful connection hides either visible status automatically.
- The status uses `role="status"` with polite live-region behaviour rather than presenting a transient reconnect as an urgent alert.
- The status does not steal keyboard focus and does not block pointer interaction with the page.
- The pill remains within the viewport with suitable side margins on narrow screens and respects the bottom safe area where supported.
- Motion is subtle, and users requesting reduced motion do not receive a spinning or animated treatment.
- Ordinary `flash-info` and `flash-error` messages retain their current appearance, dismiss behaviour, semantics, and tests.
- Public, member, and Staff LiveViews all receive the shared treatment.
- No new JavaScript or CSS dependency is added.
- `dev check` passes on the delivered implementation.

## Open Business Decisions

None known.

Confirmed decisions:

- The presentation delay is exactly 1.5 seconds.
- Client and server interruptions retain distinct wording.
- Client copy is `Connection paused — reconnecting…`.
- Server copy is `Memba is temporarily unavailable — retrying…`.
- The compact bottom-centre pill direction is approved.
- The treatment applies to every LiveView surface.
- Prolonged-failure escalation is deliberately deferred.

## Implementation Plan

1. Add focused failing coverage for the shared connection-status markup in `web/test/memba_web/components/layouts_test.exs`: stable client/server IDs, exact copy, `role="status"`, polite live-region behaviour, hidden initial state, distinct `phx-disconnected` selectors, `phx-connected` dismissal, shared visual class, spinner decoration, and absence of close controls.
2. Add proportionate coverage for the LiveSocket option so a regression from `1500` is detected without re-testing Phoenix LiveView's own timer implementation. Prefer extracting a small importable configuration value/module if that makes the JavaScript assertion direct; do not introduce broad asset refactoring solely for this test.
3. Configure `disconnectedTimeout: 1500` in `web/assets/js/app.js` while retaining the existing CSRF params, hooks, and long-poll fallback.
4. Replace only the client/server reconnect uses of `<.flash>` in `MembaWeb.Layouts.flash_group/1` with a dedicated shared connection-status presentation. Preserve the existing `phx-disconnected` client/server class targeting and `phx-connected` hiding behaviour.
5. Implement the approved responsive bottom-centre pill with existing Memba design tokens. Keep state-specific markup minimal and avoid altering the generic `<.flash>` component used by ordinary messages.
6. Add only the CSS needed for global fixed positioning, safe-area handling, and reduced-motion behaviour that is clearer as a named connection-status concept than as an opaque HEEx utility list.
7. Exercise public, member, and Staff layout rendering to confirm each includes the shared flash group and connection states without duplicating them.
8. Manually simulate brief, longer client, and server interruptions in a real browser; compare the result with the approved raw HTML prototype at desktop and narrow mobile widths.
9. Run focused JavaScript/component/CSS tests, then run `dev check`.

## Open Technical Decisions

None known.

Implementation may choose whether the shared pill markup remains a private component in `MembaWeb.Layouts` or becomes a narrowly reusable core component. Prefer the smallest boundary that avoids duplicate client/server markup without expanding the generic flash API.

## New Capability

Memba can distinguish routine background-tab wake-up reconnections from meaningful interruptions in its presentation: fast recoveries remain visually silent, while longer client or server interruptions receive calm, branded, automatically dismissing feedback across every LiveView surface.

## Validation Plan

- Render `MembaWeb.Layouts.flash_group/1` and assert both initial hidden connection states, exact copy, semantics, LiveView bindings/selectors, common presentation class, and no close control.
- Preserve existing layout and generic flash tests to prove normal flash messages are unchanged.
- Verify the effective LiveSocket configuration sets `disconnectedTimeout` to exactly `1500` while preserving existing options.
- In a browser connected to a LiveView, simulate a reconnect that completes in less than 1.5 seconds and confirm no connection indicator is displayed.
- Simulate a client/network interruption longer than 1.5 seconds and confirm the client copy and approved pill appear, the page remains visible and interactive-looking, and the pill disappears automatically on reconnection.
- Simulate a server-error interruption longer than 1.5 seconds and confirm the server copy appears in the same visual treatment and disappears automatically on reconnection.
- Check that the two error classes do not display both pills simultaneously under their intended states.
- Check desktop and narrow mobile viewport placement, including side margins and bottom safe-area behaviour.
- Enable reduced-motion preferences and confirm the indicator remains understandable without spinning or entrance animation.
- Confirm the status does not receive focus or block page pointer interaction.
- Run `dev check` on the committed delivery candidate.

## Risks / Follow-ups

- A delay that is too short would preserve the original flash; one that is too long would leave a real interruption unexplained. The agreed 1.5 seconds is explicit and should be reviewed manually under realistic tab-wake behaviour.
- LiveView's client/server root classes can overlap during some failures. Preserve the framework's existing targeted selector behaviour and verify that users do not see duplicate pills.
- A CSS animation alone must not undermine reduced-motion support or screen-reader clarity.
- The raw prototype contains simulation controls and representative page content only for review; none of that prototype scaffolding belongs in production.
- Follow-up only if evidence warrants it: add a prolonged-failure state with a Reload action after a separately agreed threshold.
- Follow-up only if diagnosis requires it: add client connection telemetry or structured reconnect observability.
