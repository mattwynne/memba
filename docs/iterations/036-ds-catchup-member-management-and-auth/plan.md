# Design-system catch-up: member management & auth check-email

Date: 2026-06-17
Status: merged

## Goal

Bring the claude.ai/design design system back in step with the running app by adding previews for two shipped feature areas that currently have **no design**: member management & invitations, and the auth check-email / delivery-progress surface. After this iteration the DS contains accurate, daisyUI-themed previews of these surfaces, authored in-repo and pushed to the cloud DS, so the DS reflects how the app actually works rather than only the surfaces designed before they shipped.

After this iteration:

- The DS has previews for inviting a member (member-admin and staff variants), completing an invited member's profile, and the sign-in check-email page with its delivery-progress states.
- The badges component card includes the role / Membership-Admin chips as they actually render in the app.
- Each preview is self-contained (daisyUI + the app theme), render-verified, and pushed to the cloud DS.

## Background / Context

The design system is the source of truth for design and is meant to mirror the running app (see `CLAUDE.md`). Several features shipped after their surfaces were last designed, leaving the DS behind. A gap audit against the live DS (`list_files`) and the shipped iterations found these undesigned areas: member management & invitations (027/028/029), onboarding requests (022/030), the auth check-email / delivery-progress surface (032), and cross-cutting empty states. This is more than one slice, so it is being sliced: **036 covers member management & invitations + auth check-email**; onboarding requests and empty-states/refresh are deferred to later iterations.

The phase-2 DS-previews approach is already proven (`docs/specs/2026-06-17-phase2-ds-previews-design.md`): previews render with **prebuilt daisyUI CSS via CDN + the daisyUI theme as `:root` vars** and plain CSS for page layout. A hard lesson from that work: **Tailwind utility classes do not resolve in static prebuilt-CSS previews** — previews must use daisyUI components + plain CSS only, and every page must be render-verified before pushing.

The deliverable is design-system preview files. Delivery is "full Fabro deliver" of the **repo-side** preview files (Fabro operates on the git repo and cannot reach the cloud DS); after the iteration merges, the PM pushes the approved files to the cloud DS via DesignSync.

## Related Problems

- None directly. This is design-system convergence for already-shipped features. It is the first slice of the previously noted follow-up "update the DS with designs for features that we've added with no design."

## Scope

### In scope

Author new design-system preview files in the repo, following the phase-2 self-contained convention (daisyUI CDN `<link>` + theme `:root` vars copied from `web/assets/css/app.css` + plain CSS for layout), each carrying its `@dsCard` header so the DS pane indexes it:

- **Invite a member** preview — reflecting `MemberInvitationLive.New` (`/members/invitations/new`, Membership-Admin invite) and `ClubMemberInvitationsLive.New` (`/clubs/:club_id/invitations/new`, staff invite). Show both variants (in one file with both states, or two files — implementer's call).
- **Profile completion** preview — reflecting the invited-member profile completion surface (`ClubMemberInvitationController#profile`, `club_member_invitation_html/profile.html.heex`).
- **Check-email / delivery progress** preview — reflecting `AuthLive.SignIn` (`/auth/check-email` and `/auth/check-email/:request_id`), including the privacy-preserving delivery-progress states (e.g. sending → sent → delivered) as iteration 032 implemented them.
- **Role / Membership-Admin chips** — extend `components/badges/badges.card.html` (or add a sibling card) to show the role/admin badges as they actually render, using the shared badge taxonomy.
- Render-verify every preview with headless Chrome against the live CDNs before considering it done.
- Establish/confirm a repo location for DS preview source that maps cleanly to the cloud DS paths (see Open Technical Decisions).

### Out of scope

- A member roster / member-list page — it does not exist in the app; do not invent it.
- Onboarding-requests design area (public request + verification, staff review, request emails) — deferred to a later DS-catch-up iteration.
- Empty-states and refresh of existing member surfaces (club-home, member-messaging) — deferred to a later iteration.
- Any change to app code, routes, LiveViews, templates, or behaviour. This iteration only adds static design previews.
- The cloud DesignSync push itself — that is a manual PM step after the iteration merges (documented in Validation Plan), because Fabro cannot reach the cloud DS.
- Marketing site, staff-console previews, and email templates beyond the badge card change.

## Iteration Type

Technical/design. There is no new user-observable app behaviour: the work adds design-system preview artifacts that mirror surfaces the app already ships. No application rule, permission, or flow changes.

## Acceptance Scenarios / Feature Files

BDD decision: **Not applicable.**

No application behaviour changes, so there is no new or changed user-observable rule to express in Gherkin, and no `.feature` files are touched. Correctness is "does the preview faithfully and cleanly render the shipped surface," verified by headless-Chrome render checks and visual comparison to the running app, not by acceptance scenarios. Existing acceptance scenarios remain green and unchanged.

## Acceptance Criteria

- New DS previews exist in the repo for: invite-a-member (member-admin + staff variants), profile completion, and check-email with delivery-progress states.
- The badges component card includes the role / Membership-Admin chips matching how they render in the app.
- Every preview is self-contained: daisyUI prebuilt CSS via CDN + the app theme as `:root` vars + plain CSS for layout; it does **not** rely on Tailwind utility classes and does **not** link the bespoke shared component CSS.
- Each preview carries its `@dsCard` header so the DS pane indexes it, and uses correct relative asset paths.
- Each preview renders cleanly under headless Chrome (no broken/unstyled components) and visually matches the corresponding shipped surface.
- No app code, routes, LiveViews, templates, or `.feature` files are changed.
- `dev check` passes (static preview files do not affect the app build or tests).

## Open Business Decisions

None known. The surfaces already exist in the product; this documents them in the DS.

## Implementation Plan

1. Read the shipped surfaces to mirror them accurately: `member_invitation_live/new.ex`, `admin/club_member_invitations_live/`, `club_member_invitation_html/profile.html.heex`, and `auth_live/sign_in.ex`; note the real fields, states, copy, and delivery-progress states.
2. Confirm the repo preview location and the self-contained head block (daisyUI CDN + theme `:root` vars from `web/assets/css/app.css` + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.
3. Author the invite-a-member preview (member-admin + staff variants).
4. Author the profile-completion preview.
5. Author the check-email / delivery-progress preview, covering the progress states.
6. Extend the badges card with the role / Membership-Admin chips.
7. Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).
8. Ensure `@dsCard` headers and relative asset paths are correct on every new/changed file.
9. Run `dev check` to confirm the static files leave the build green.

## Open Technical Decisions

- **Repo preview location.** Preferred: a `design-system/` mirror directory whose paths match the cloud DS (e.g. `design-system/wireframes/*.html`, `design-system/components/badges/badges.card.html`) so the eventual DesignSync push is a clean directory-to-project sync. Acceptable fallback: continue authoring under `spikes/ds-convert/` as the convergence work did. Choose one and keep it consistent; record the mapping so the PM push step is mechanical.
- **One file vs two for the invite variants** — member-admin and staff invites in a single preview with both states, or two sibling files. Implementer's call based on which renders clearer.
- Exact cloud DS target paths for each new file (decided at push time by the PM, guided by the repo mapping above).

These are implementation details and should not need product decisions.

## New Capability

The design system shows how member invitations, profile completion, and the sign-in check-email/delivery-progress surface actually look and work, instead of omitting them — closing the first slice of the gap between shipped features and the DS, and giving future design iteration a faithful starting point for these surfaces.

## Validation Plan

- Headless-Chrome render screenshots of each new/changed preview, visually compared to the running app surface.
- Confirm no app code, routes, templates, or `.feature` files changed (diff is preview files only).
- `dev check` green.
- **Post-merge PM step (manual, outside Fabro):** push the approved preview files to the cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` via DesignSync, then visually confirm the new cards render in claude.ai/design. This step is required to "bring the DS up to speed" but cannot run inside Fabro.

## Risks / Follow-ups

- **Tailwind-utility trap:** static prebuilt-daisyUI previews silently drop Tailwind utility classes, producing broken renders. Mitigation: daisyUI components + plain CSS only, and mandatory headless-Chrome render verification on every file.
- **Fidelity drift:** the design must reflect what shipped, not an idealized version. Mitigation: implementer reads the actual LiveViews/templates first; PM compares renders to the live app before pushing.
- **Fabro cannot push to the cloud DS.** The iteration only produces repo files; the cloud push is a separate manual PM step. The iteration is not "done" for the stated goal until that push happens, but the push is deliberately out of the Fabro slice.
- **WIP ordering:** this plan can be validated now but cannot deliver until iterations 034 (and then 035) vacate the single implementation WIP slot.
- **Deferred slices:** onboarding-requests previews and empty-states/refresh remain follow-up DS-catch-up iterations.
