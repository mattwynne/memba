# Implementation TODO

- [x] 001 Add focused failing layout coverage for stable client/server connection-status IDs, exact copy, `role="status"`, polite live-region behaviour, hidden initial state, and absence of close controls.
- [x] 002 Extend that layout coverage to require distinct `phx-disconnected` selectors, `phx-connected` dismissal, a shared visual class, and spinner decoration.
- [x] 003 Add proportionate direct coverage for the LiveSocket `1500` option, extracting a small importable configuration value only if useful and avoiding broad asset refactoring or tests of LiveView's timer implementation.
- [x] 004 Configure `disconnectedTimeout: 1500` in `web/assets/js/app.js` while retaining the existing CSRF params, hooks, and long-poll fallback.
- [x] 005 Replace only the client/server reconnect uses of `<.flash>` in `MembaWeb.Layouts.flash_group/1` with a shared connection-status presentation that preserves the existing targeted `phx-disconnected` classes and `phx-connected` hiding.
- [ ] 006 Implement the approved responsive bottom-centre pill with existing Memba design tokens. Keep state-specific markup minimal and avoid altering the generic `<.flash>` component used by ordinary messages.
- [ ] 007 Add only the CSS needed for global fixed positioning, safe-area handling, and reduced-motion behaviour that is clearer as a named connection-status concept than as an opaque HEEx utility list.
- [ ] 008 Exercise public, member, and Staff layout rendering to confirm each includes the shared flash group and connection states without duplicating them.
- [ ] 009 Manually simulate brief, longer client, and server interruptions in a real browser; compare the result with the approved raw HTML prototype at desktop and narrow mobile widths.
- [ ] 010 Run focused JavaScript/component/CSS tests, then run `dev check`.
