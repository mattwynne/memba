# 15. Use LiveView for member application pages

Date: 2026-06-01

## Status

accepted

## Context

Memba's member-facing product is an application, not a set of mostly static pages. Member pages increasingly need authenticated state, club context, forms, confirmations, error states, progressive interaction, and a consistent white-label app shell.

Recent member-message work exposed friction from treating member app pages as controller-rendered templates first and LiveViews only when interaction becomes unavoidable. That creates churn: routes, templates, tests, and acceptance helpers need to move later when a page gains stateful behaviour such as compose confirmations or expandable receipt groups.

The product direction is that club-member app surfaces should feel coherent and interactive. Static marketing and legal pages have different needs and do not benefit from LiveView by default.

## Decision

Use Phoenix LiveView by default for member application pages.

This includes authenticated club-member surfaces such as:

- club home / member dashboard;
- compose flows;
- message detail and receipt views;
- future member-only workflows that depend on identity, club context, forms, or interaction.

Static pages may remain controller-rendered templates when they are genuinely static or marketing/legal content, for example:

- `/about`;
- `/terms`;
- `/privacy`;
- logged-out marketing pages unless they need LiveView interaction.

When adding or changing a member application surface, start with a LiveView unless there is a specific reason not to. Do not make controller rendering the default just because the first version appears simple.

## Consequences

Member app pages have a consistent implementation model as they grow from display to interaction.

Future interaction such as confirmations, expand/collapse, validation, live updates, filtering, or stateful navigation can be added without moving the page from controller templates to LiveView later.

Tests can use LiveView/PhoenixTest patterns consistently for member app behaviour.

Simple member pages may carry a small amount of LiveView structure before they strictly need it. This is an acceptable trade-off for consistency and reduced churn.

Controller-rendered templates remain appropriate for static marketing/legal content and simple non-app pages.
