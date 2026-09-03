# Design-system catch-up: onboarding requests + empty states & member refresh

Date: 2026-06-17
Status: merged

## Goal

Close the remaining gap between the running app and the claude.ai/design design system by adding previews for the onboarding-request surfaces and for empty/first-run states, and by refreshing the existing member previews so they mirror the post-034 member pages. After this iteration (and its cloud push), the DS reflects how the app actually works across the member, auth, member-management, and onboarding-request surfaces — completing the DS-catch-up work begun in 036.

After this iteration:

- The DS has previews for the public account-request flow (with email-verification states), the staff request-review & convert screen, and the new-request notification email.
- The DS has canonical empty/first-run state previews (e.g. a club home with no messages yet).
- The existing member previews (club home, member messaging/read) mirror the post-034 member pages (sage palette, shared components, no white-label layer).
- Each preview is self-contained (daisyUI + the app theme), render-verified, and pushed to the cloud DS.

## Background / Context

The design system is meant to mirror the running app (see `CLAUDE.md`). A gap audit found several shipped surfaces with no design; iteration 036 took the first slice (member management & invitations + auth check-email). This iteration takes the **final two DS-catch-up slices**: onboarding requests (022/030) and empty-states + refresh of existing member surfaces.

The phase-2 DS-previews approach is proven (`docs/specs/2026-06-17-phase2-ds-previews-design.md`): previews render with **prebuilt daisyUI CSS via CDN + the daisyUI theme as `:root` vars** plus plain CSS for layout. Hard lesson carried forward: **Tailwind utility classes do not resolve in static prebuilt-CSS previews** — use daisyUI components + plain CSS only, and render-verify every page before pushing.

The deliverable is design-system preview files. Delivery is "full Fabro deliver" of the **repo-side** preview files following the repo preview-location convention that iteration 036 establishes; Fabro cannot reach the cloud DS, so after the iteration merges the PM pushes the approved files to the cloud DS via DesignSync.

Two dependencies matter:

- The **member-surface refresh** must mirror the **post-034 (and 035)** member pages — sage palette, shared `button`/`avatar`/`status_badge` components, white-label layer removed — not today's pre-034 markup. This iteration sits behind 034 → 035 → 036 in the single implementation WIP slot, so by delivery time those are merged; the implementer must read the then-current member templates.
- It **follows the repo preview-location convention 036 sets** so the cloud push stays a clean directory sync.

## Related Problems

- None directly. This is design-system convergence for already-shipped features — the final slice of the follow-up "update the DS with designs for features that we've added with no design."

## Scope

### In scope

Author new/updated design-system preview files in the repo, following the phase-2 self-contained convention (daisyUI CDN `<link>` + theme `:root` vars copied from `web/assets/css/app.css` + plain CSS for layout), each carrying its `@dsCard` header so the DS pane indexes it, and following the repo preview-location convention from 036:

- **Public account-request flow** preview — reflecting `AuthLive.Onboard` (`/auth/onboard`) and the verified-email entry (`get_started.html.heex`, iteration 030), including the email-verification states.
- **Staff request review & convert** preview — reflecting `RequestsLive.Index` (`/requests`, `/requests/:request_id` convert, iteration 022): the request list/review and the convert-to-club action.
- **New-request notification email** preview — reflecting `Memba.Onboarding.NewRequestEmail`. (The welcome email is already in the DS; confirm/refresh only if it has drifted.)
- **Empty / first-run states** preview(s) — canonical empty states such as a club home with no messages yet, using the shared components and sage theme.
- **Refresh existing member previews** — update the club-home and member-messaging/read previews so they mirror the post-034 member pages (sage palette, shared components, white-label layer removed).
- Render-verify every preview with headless Chrome against the live CDNs before considering it done.

### Out of scope

- Any change to app code, routes, LiveViews, templates, or behaviour. This iteration only adds/updates static design previews.
- A request-rejection email preview — no such email ships today; do not invent one.
- The cloud DesignSync push itself — a manual PM step after the iteration merges (documented in Validation Plan), because Fabro cannot reach the cloud DS.
- Marketing site and staff-console previews beyond the request-review screen listed above.
- Re-designing or changing the member surfaces — the refresh mirrors what 034 shipped; it does not reimagine layout or behaviour.
- New feature areas beyond onboarding requests and empty-states/refresh (those gaps are now fully covered across 036 and 037).

## Iteration Type

Technical/design. There is no new user-observable app behaviour: the work adds/updates design-system preview artifacts that mirror surfaces the app already ships. No application rule, permission, or flow changes.

## Acceptance Scenarios / Feature Files

BDD decision: **Not applicable.**

No application behaviour changes, so there is no new or changed user-observable rule to express in Gherkin, and no `.feature` files are touched. Correctness is "does the preview faithfully and cleanly render the shipped surface," verified by headless-Chrome render checks and visual comparison to the running app. Existing acceptance scenarios remain green and unchanged.

## Acceptance Criteria

- New DS previews exist for: the public account-request flow (with email-verification states), the staff request-review & convert screen, the new-request notification email, and empty/first-run states.
- The existing club-home and member-messaging/read previews are refreshed to mirror the post-034 member pages (sage palette, shared components, no white-label layer); no off-brand blue or `--club-site-*` remnants.
- Every preview is self-contained: daisyUI prebuilt CSS via CDN + the app theme as `:root` vars + plain CSS for layout; it does **not** rely on Tailwind utility classes and does **not** link the bespoke shared component CSS.
- Each preview carries its `@dsCard` header and correct relative asset paths, and follows the repo preview-location convention from 036.
- Each preview renders cleanly under headless Chrome (no broken/unstyled components) and visually matches the corresponding shipped surface.
- No app code, routes, LiveViews, templates, or `.feature` files are changed.
- `dev check` passes (static preview files do not affect the app build or tests).

## Open Business Decisions

None known. The surfaces already exist in the product; this documents them in the DS.

## Implementation Plan

1. Read the shipped surfaces to mirror them accurately: `auth_live/onboard.ex`, `get_started.html.heex`, `admin/requests_live/`, `Memba.Onboarding.NewRequestEmail`, and the then-current post-034 member templates (`page_html/club.html.heex`, `page_html/message.html.heex`, `member_message_live/`).
2. Confirm the repo preview location/convention from 036 and the self-contained head block (daisyUI CDN + theme `:root` vars + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.
3. Author the public account-request flow preview (including email-verification states).
4. Author the staff request review & convert preview.
5. Author the new-request notification email preview; confirm/refresh the welcome email only if drifted.
6. Author the empty / first-run state preview(s).
7. Refresh the club-home and member-messaging/read previews to the post-034 member pages.
8. Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).
9. Ensure `@dsCard` headers and relative asset paths are correct on every new/changed file.
10. Run `dev check` to confirm the static files leave the build green.

## Open Technical Decisions

- **Email preview rendering convention** — whether the new-request notification email preview follows the same self-contained head approach as the existing `emails/*.html` DS files (likely yes); match the existing email-preview convention rather than the app-page one.
- **Empty-state packaging** — whether empty states live as their own preview file(s) or as additional states within the refreshed club-home preview. Implementer's call based on what reads clearest in the DS pane.
- Exact cloud DS target paths for each new/updated file (decided at push time by the PM, guided by the 036 repo mapping).

These are implementation details and should not need product decisions.

## New Capability

The design system shows the onboarding-request journey (public request + verification, staff review/convert, the notification email) and canonical empty states, and its member previews match the shipped member pages — closing the DS-vs-app gap that 036 began and giving future design iteration a faithful, complete starting point.

## Validation Plan

- Headless-Chrome render screenshots of each new/changed preview, visually compared to the running app surface.
- Confirm no app code, routes, templates, or `.feature` files changed (diff is preview files only).
- `dev check` green.
- **Post-merge PM step (manual, outside Fabro):** push the approved preview files to the cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` via DesignSync, then visually confirm the new/updated cards render in claude.ai/design. Required to "bring the DS up to speed" but cannot run inside Fabro. After this push, the DS-catch-up work (036 + 037) is complete.

## Risks / Follow-ups

- **Tailwind-utility trap:** static prebuilt-daisyUI previews silently drop Tailwind utility classes, producing broken renders. Mitigation: daisyUI components + plain CSS only, plus mandatory headless-Chrome render verification.
- **Stale-refresh risk:** the member-surface refresh must reflect the post-034/035 state, not today's. Mitigation: implementer reads the then-current member templates; if for any reason 034/035 are not yet merged at delivery time, narrow this iteration to the onboarding-request + empty-state previews and record the member refresh as a follow-up rather than mirroring soon-to-change markup.
- **Convention dependency:** follows the repo preview-location convention 036 establishes; if 036 has not landed that convention by delivery time, set it here and keep it consistent.
- **Fabro cannot push to the cloud DS:** the iteration only produces repo files; the cloud push is a separate manual PM step, and the stated goal is not fully met until that push happens.
- **WIP ordering:** validatable now, but cannot deliver until 034 → 035 → 036 vacate the single implementation WIP slot.
