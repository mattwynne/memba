# 23. Use URL-addressable LiveView state

Date: 2026-07-06

## Status

accepted

## Context

Memba's member-facing app surfaces increasingly contain visible states such as tabs, filters, selected panels, and detail modes. When those states live only in client-side DOM changes, users cannot bookmark or share the current state, browser Back/Forward behaviour is surprising, refreshes lose context, and automated tests can miss important behaviour.

ADR 0015 already says member application pages should use Phoenix LiveView by default. The club-home Conversations/Members tabs exposed the next rule: visible application state should be part of the route whenever practical, and LiveView should own the state transition instead of custom JavaScript.

## Decision

Visible state changes in member application pages should be reflected in the URL whenever practical.

Use Phoenix LiveView routes, `handle_params/3`, `<.link patch={...}>`, and `push_patch/2` for in-page state changes wherever possible. This lets LiveView update browser history with pushState while avoiding full server reloads.

Use full navigation or a server reload only when the destination is a different application surface, crosses LiveView sessions, leaves the LiveView router, or cannot safely be represented as a LiveView patch.

Avoid custom JavaScript for application state transitions that LiveView routing can model. JavaScript remains appropriate for progressive enhancement, local-only browser behaviour, third-party widgets, and interactions that do not represent durable page state.

Examples of URL-addressable visible state include:

- selected tabs or sections;
- filters, search terms, and pagination;
- selected list/detail modes;
- expandable modes that users may expect to bookmark, share, refresh, or navigate back to.

Small transient UI details such as a menu being open, a tooltip being visible, or a focus ring do not need URLs unless they become meaningful application states.

## Consequences

Users can refresh, share, bookmark, and use Back/Forward without losing visible application context.

Tests can assert routed states and LiveView patches instead of decoding custom client-side JavaScript.

Member app code stays closer to the product architecture in ADR 0015: LiveView owns stateful application surfaces.

Some UI work will require route and `handle_params/3` design earlier than a client-only implementation would. That is an acceptable cost for durable state, accessibility, and predictable navigation.
