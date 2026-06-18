# Member page design-system alignment

Date: 2026-06-17
Status: merged

## Goal

Bring the four member-facing pages onto the shared Memba design system so the member experience — the heart of the app — is visually consistent with the design. Member pages currently hand-roll buttons, avatars, and status indicators and carry an off-brand delivery palette; this iteration adopts the shared daisyUI components and the sage palette, and removes the per-club white-label theming layer (to be restarted as its own piece later).

After this iteration:

- Member pages use the shared `button`, `avatar`, and `status_badge` components instead of bespoke markup.
- Member delivery-status visuals use Memba's sage-based palette (no off-brand blue).
- Member pages render in the canonical sage Memba theme; the `--club-site-*` white-label layer is gone.
- No hardcoded hex remains on member pages.

## Background / Context

The design-system convergence work (button/status_badge/avatar components on daisyUI + the `app.css` sage theme, plus the design previews) is done. The member-facing LiveViews/templates predate it: they hand-roll buttons/avatars/status with Tailwind utilities driven by a per-club white-label variable layer (`--club-site-*` via `Layouts.club_site`), and the email-delivery breakdown uses blue for "Delivered" — a color outside Memba's sage/apricot palette.

White-labelling (per-club accent colour) was deliberately set aside: it will be restarted as its own initiative. For now member pages should render in the fixed sage theme, so this iteration **removes** the `--club-site-*` plumbing rather than defaulting it.

This is a polish/convergence iteration. It must not change member workflows (compose/send, read, sign-in, invite, navigation) beyond small fixes that surface naturally.

## Related Problems

- No problem note maps directly; this is design-system convergence for member pages.
- [`docs/problems/2026-06-17-obliterate-opened-email-delivery-status.md`](../../problems/2026-06-17-obliterate-opened-email-delivery-status.md): **explicitly out of scope and not entangled.** Delivery-status work here only re-colours the statuses Memba actually supports; it does not add, remove, or depend on the deprecated "opened" status.

## Scope

### In scope

- Replace hand-rolled buttons on member pages with `MembaWeb.CoreComponents.button` (variants primary/secondary/ghost/danger, sizes), across:
  - Club home: "Send club message", "Invite member", empty-state send link, "Sign out".
  - Message read: "Sign out", any actions.
  - Compose: submit/cancel actions, "Sign out".
  - Public club page: "Email me a sign-in link", "Visit Memba home".
- Replace hand-rolled initials avatars with `MembaWeb.CoreComponents.avatar` (message sender initials; club-home member avatar stack, including the "+N" overflow).
- Use `MembaWeb.CoreComponents.status_badge` where a status pill is shown, reconciled to the shared tone taxonomy.
- Re-colour the **member** email-delivery visuals to the sage-based palette: Delivered → sage (positive), Sending → warning, Delivery problem → error. Applies to the club-home receipt mini-bars and the message-read delivery-breakdown card. **Member surfaces only** — do not change staff delivery views.
- Remove the `--club-site-*` white-label theming layer used by member pages (`Layouts.club_site` and the templates), rendering member pages in the canonical sage daisyUI theme using tokens/daisyUI classes.
- Small behaviour/copy fixes that surface during polish, kept minimal; record anything non-trivial as a new problem note rather than expanding the slice.
- Add/update component and LiveView/template tests for the changed component usage and the member delivery-colour mapping. No hardcoded hex.

### Out of scope

- Building or restoring per-club white-label theming (separate future initiative).
- Changing staff delivery-status colours or any staff/admin surfaces.
- The "opened" delivery-status obliteration (separate problem/iteration).
- Adding design-system designs for app features that lack them (separate follow-up).
- New member features, flows, or copy rewrites beyond incidental fixes.
- Marketing site and email templates.
- A responsive redesign — preserve existing desktop/mobile behaviour, don't reimagine it.

## Iteration Type

Behaviour-facing polish iteration (predominantly presentational; small behaviour/copy fixes permitted).

User-observable changes:

- Member pages look consistent with Memba's design system (shared components, sage theme).
- Member email-delivery status uses on-brand sage colours, not blue.

## Acceptance Scenarios / Feature Files

BDD decision: **No new domain Gherkin.**

This iteration is visual/component alignment with no new domain behaviour; stakeholder-readable scenarios would not add meaningful acceptance coverage beyond the existing member messaging/delivery scenarios, which keep passing unchanged. Visual correctness is verified by component/LiveView tests plus `./bin/dev gallery-walk` screenshots of the member pages (club home, message read, compose, public club page) at desktop and mobile. Existing `@iteration-0xx` member scenarios must remain green.

## Acceptance Criteria

- All buttons on the four member pages render via `CoreComponents.button` (no bespoke `<button>`/`<a class="...btn...">` styling on those pages).
- Member sender/initials avatars render via `CoreComponents.avatar`, including the club-home stack and "+N" overflow.
- Member email-delivery visuals use the sage palette: Delivered = sage, Sending = warning, Problem = error; no blue appears in member delivery bars/cards.
- Staff delivery-status views are unchanged.
- The `--club-site-*` white-label layer is removed; member pages render in the canonical sage theme and no longer depend on `Layouts.club_site` accent variables.
- No hardcoded hex (`[#......]` or inline hex) is introduced on member pages; only tokens/daisyUI classes.
- Existing member behaviours keep working: reading a message, composing/sending, sign-in, inviting a member, navigation, sign out.
- Member pages remain responsive at desktop and mobile (verified via gallery-walk).
- `dev check` passes.

## Open Business Decisions

None outstanding.

Confirmed decisions:

- Remove the white-label plumbing now; restart white-labelling as a separate initiative later.
- Delivery-colour change applies to member surfaces only.
- Adopt the shared button/avatar/status_badge components.

## Implementation Plan

1. Inventory the member templates/layout and their bespoke markup: `web/lib/memba_web/controllers/page_html/club.html.heex`, `message.html.heex`, the compose template, the public club page template, and `Layouts.club_site` (`--club-site-*`).
2. Remove the `--club-site-*` layer: replace its variables/classes with sage tokens + daisyUI classes; simplify or retire the white-label parts of `Layouts.club_site` while keeping the member page chrome (header/footer) working in sage.
3. Replace member-page buttons with `<.button>`, mapping each to the right variant/size; preserve `href`/`navigate`/form behaviour.
4. Replace member initials avatars with `<.avatar>`, including the club-home stack and "+N".
5. Re-map the member delivery-status colours to sage/warning/error in the member presentation/helper used by the receipt mini-bars and the message-read breakdown card (e.g. the member `status_bg_class`/`MemberEmailDeliveryPresentation` path), without touching the staff delivery path. Apply `status_badge` where a pill is the right element.
6. Sweep the four member pages for any remaining hardcoded hex; replace with tokens/daisyUI classes.
7. Add/update component, LiveView, and template tests for button/avatar/status usage and the member delivery-colour mapping; keep existing member tests green.
8. Run `./bin/dev gallery-walk` and review the member screenshots (desktop + mobile) for visual correctness.
9. Run `dev check`.

## Open Technical Decisions

- Exact extent to which `Layouts.club_site` can be simplified versus replaced — keep member-page header/footer chrome working; don't break the public club page layout.
- Whether the member delivery-colour mapping lives in a member-specific helper or the shared presentation module — choose the path that changes member surfaces only and leaves staff untouched.

These are implementation details and should not need product decisions.

## New Capability

The member experience — club home, reading and composing club messages, and the public club page — looks and feels like one coherent Memba product built from the shared design system, with on-brand delivery status, replacing the bespoke, off-palette, white-label-scaffolded member UI.

## Validation Plan

- Component/LiveView/template tests for button, avatar, and status usage on member pages.
- Tests for the member delivery-status colour mapping (Delivered = sage, etc.) with staff path asserted unchanged.
- `./bin/dev gallery-walk` visual review of all four member pages at desktop + mobile.
- Confirm existing member messaging/delivery acceptance scenarios remain green.
- Full `dev check` before delivery is complete.

## Risks / Follow-ups

- Removing `--club-site-*` could ripple into the public club page and the club chrome (header/footer). Keep the chrome working; if removal proves larger than polish, narrow to the member app pages and record the public club page as a follow-up.
- The delivery-status colour mapping may currently be shared between member and staff surfaces. If so, fork a member-specific mapping (or parameterise) so staff colours stay unchanged, and note any shared-helper cleanup as a follow-up.
- White-labelling is now removed, not parked behind a flag — restarting it later is a deliberate separate initiative; ensure removal is clean rather than half-disabled.
- Keep the slice presentational; if a behaviour/copy issue is non-trivial, file a problem note instead of widening scope.
