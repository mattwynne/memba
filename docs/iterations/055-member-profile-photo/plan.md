# Members set their own profile photo

Date: 2026-08-13
Status: validated

## Goal

A signed-in member can add, replace, and remove a profile photo from the Profile tab of
`/my/settings`. Once set, the photo stands in for their initials everywhere Memba draws an avatar.

## Background / Context

Every avatar in Memba today is CSS initials derived from a Person's name — the global bar, club
member rows, conversation avatar-stacks, message authors, and the design system's own
`components/avatars` card. There is **no file upload anywhere in the application**: no
`allow_upload/3`, no blob storage, no object-store dependency, no image library.

That makes this iteration the first upload pipeline in the codebase, which is why it is a separate
slice from iteration 054's name editing rather than bundled with it (see
[054](../054-member-name-editing/plan.md)). Iteration 054 should ship first; this iteration assumes
the Profile tab already has its editable-field structure.

Initials are not replaced as a pattern. They remain the fallback for every member without a photo,
which is most members on day one.

## Related Problems

- [`docs/problems/2026-06-23-interface-too-fancy-for-simple-app-use.md`](../../problems/2026-06-23-interface-too-fancy-for-simple-app-use.md):
  **neither resolved nor worsened, but relevant.** Real member photos make lists scannable in a way
  initials do not, which pulls toward the app-like feel that note asks for. It also adds visual
  weight. Keep the treatment plain: a circle, no shadows, no hover flourishes.
- [`docs/problems/2026-06-08-club-onboarding-details-not-collected.md`](../../problems/2026-06-08-club-onboarding-details-not-collected.md):
  **left unresolved.** A photo is optional and self-service; this is not the reusable required-details
  mechanism that note calls for, and must not be mistaken for it.
- [`docs/problems/2026-06-06-staff-merge-people.md`](../../problems/2026-06-06-staff-merge-people.md):
  **left unresolved, with a new wrinkle.** Merging duplicate people will eventually have to decide
  which photo survives. Not this iteration's problem, but worth knowing it now exists.

## Scope

### In scope

- A `Photo` field on the Profile tab of `/my/settings` with the states in the design: no photo
  (initials + `Add a photo`), photo set (`Change photo` / `Remove photo`), uploading, and the three
  error states.
- A LiveView JS hook that downscales and **centre-crops** the chosen file to a square in a canvas
  before upload. No crop screen — the member's path is pick → progress → done.
- Client-side rejection, before decoding, of files over 25 MB and of non-image files.
- `Phoenix.LiveView.allow_upload/3` for the resulting square image, with server-side validation that
  does not trust the hook: content type sniffed from the bytes, decoded dimensions bounded, and a
  hard byte cap on what is stored.
- Storing the image bytes in Postgres (`bytea`), one current photo per Person.
- A photo-serving route behind `club_member_required`, with `ETag`/`Cache-Control` so repeat renders
  do not re-read the bytes.
- Replacing a photo (a second upload supersedes the first) and removing it (back to initials).
- Rendering the photo wherever an avatar is drawn today, with initials as the fallback.
- Live refresh of an open `/my/settings` via `Memba.ReadModelChanges`.

### Out of scope

- An interactive cropper (drag/zoom/reposition). Decided against during planning; centre-crop only.
- Photos anywhere outside the app: email templates, public club pages, and the marketing site keep
  initials or no avatar. Emails cannot carry a signed-in-only image, and making photos public is
  explicitly rejected below.
- Club logos or club avatars. Different aggregate, different permissions.
- Staff or Membership Admins setting or removing another member's photo, and any moderation,
  reporting, or takedown workflow for an inappropriate photo.
- Multiple photos, photo history, or restoring a removed photo.
- Animated GIF preservation — an animated GIF is accepted and flattened to a still square by the
  canvas crop. This is a consequence of the chosen approach, not a feature.
- Object storage (Tigris/S3) and any general-purpose media pipeline. Explicitly deferred; see
  Technical Decisions.
- `srcset`/multiple stored sizes. One stored square, scaled by CSS.

## Iteration Type

Behaviour-facing.

The changed user-observable rule: **a member chooses the picture their clubs see, and it replaces
their initials.** Previously every avatar in Memba was derived from a name with no member control.

## Acceptance Scenarios / Feature Files

BDD decision: **Required.**

The iteration is member-visible, changes what other members see, introduces acceptance/rejection
policy for uploads, and carries a privacy rule about who can fetch a photo. Four "default to Gherkin"
signals apply, and the rejection and failure cases are exactly the ones worth stating in
stakeholder-readable terms.

Scenarios go in
[`acceptance-tests/features/member_profile.feature`](../../../acceptance-tests/features/member_profile.feature),
shared with iteration 054, tagged `@iteration-055 @todo-domain @todo-ui`:

Rule: A member's photo stands in for their initials

- Alice adds a photo (settings + Bob sees it in the member list).
- Alice replaces her photo with a newer one.
- Alice removes her photo and goes back to her initials.

Rule: Only images Memba can display are accepted as photos

- Alice picks a document instead of a photo.
- Alice picks a photo far too big to handle.

Rule: A failed upload leaves the member's existing photo in place

- Alice's upload fails part way through.

Rule: A member's photo is only visible to people signed in to Memba

- A signed-out visitor cannot fetch Alice's photo.

Both runners exclude these while tagged (`not @todo-ui` for the browser profile in
`acceptance-tests/cucumber.js`, `not @todo-domain` for the domain profile in `web/config/test.exs`),
so the build stays green before implementation.

## Allowed acceptance feature changes

- `acceptance-tests/features/member_profile.feature`: implementation may remove or narrow the
  temporary `@todo-domain` / `@todo-ui` tags on the seven `@iteration-055` scenarios and add the step
  definitions they need. Reason: they are written ahead of implementation as this slice's acceptance
  criteria. `@iteration-055` tags must be preserved, and the `@iteration-054` scenarios in the same
  file must be left untouched. Implementation must not weaken or delete a scenario to make it pass —
  in particular, the signed-out-visitor scenario is a privacy constraint, not a nice-to-have.

## Designs

Designed and pushed:
[`design-system/templates/account-settings.html`](../../../design-system/templates/account-settings.html)
→ cloud `templates/account-settings/account-settings.html`. Render-verified headlessly at 1320px
(no console/network errors, no horizontal overflow, all states present) before pushing.

The template covers the final Profile tab across iterations 054 and 055. This iteration builds the
photo half. States, from the "Profile tab · photo" rows:

- **Photo — none set:** 72px initials circle, `Add a photo`, hint
  `Until you add one, your clubs see your initials.`
- **Photo — set:** the same circle filled with the photo, `Change photo` (soft) and `Remove photo`
  (ghost), hint `Removing it puts your initials back.` Removal is a direct action with no
  confirmation dialog — consistent with how `Remove` already works on email rows.
- **Photo — uploading:** the avatar dims under a `rgb(37 41 29 / 0.45)` overlay
  (`.profile-avatar--uploading`) rather than being swapped for a spinner, so the target of the upload
  stays visible; a determinate `.upload-progress` bar and `Uploading your photo…` sit beside it, with
  a `Cancel` action.
- **Photo — file too large / wrong file type:** initials still shown, an `.alert alert-error` beneath
  the field: `That photo is bigger than 25 MB. Choose a smaller one.` and `That file isn't an image
  we can use. Choose a JPG, PNG, GIF or WebP.`
- **Photo — upload failed:** the **existing photo is still rendered**, actions become
  `Try again` / `Remove photo`, hint `Your existing photo is still in place.`, alert
  `We couldn't upload that photo. Please try again.`

Field-level hint copy is `JPG, PNG, GIF or WebP — we'll crop it to a square for you.` — deliberately
naming no pixel size, because the hook handles sizing. The 25 MB figure is a guard rail on the file
the member picked, checked **before** the browser tries to decode it; it is not the limit on what
gets stored.

The avatar-menu surface in the same template shows the photo replacing the initials in the global
bar, with the note that this holds anywhere an avatar is drawn — member rows and conversation
avatar-stacks included. Initials remain the fallback, not a separate pattern.

New page-local classes: `.profile-photo`, `.profile-photo__controls`, `.profile-photo__actions`,
`.profile-avatar--lg`, `.profile-avatar--photo`, `.profile-avatar--uploading`, `.upload-progress*`,
`.profile-hint`. Rendering a photo in the **shared** avatar vocabulary (global bar, member rows,
avatar-stacks) does touch shell CSS in `styles.css`, which is imported by `web/assets/css/app.css` —
keep that change to what is needed to fill an existing avatar circle with an image.

**Buttons:** the template draws raw daisyUI classes, but the app now has a unified `<.button>` core
component (`web/lib/memba_web/components/core_components.ex`, commit `aab58490a`). Build the photo
actions with it, not raw classes: `btn-soft` → `variant="secondary"`, `btn-ghost` → `variant="ghost"`,
all at `size="sm"`.

**Avatar rendering:** the global bar and its identity menu moved into `.global-bar` / `.app-menu__who`
(commit `cebaeb9af`), and those rules are now in the tracked `styles.css` mirror, so the avatar sites
this iteration must fill with a photo are all in one place rather than split between the app and the
cloud-only `memba.css`.

## Acceptance Criteria

- The Profile tab shows an initials circle and `Add a photo` when the member has no photo.
- Choosing an image uploads it and the settings page then shows it in place of the initials.
- The uploaded image is stored as a square; a non-square original is centre-cropped, not distorted or
  letterboxed.
- A member with a photo sees `Change photo` and `Remove photo`.
- Uploading a second photo replaces the first; the superseded bytes do not remain the served photo.
- `Remove photo` restores the initials in settings and everywhere else an avatar is drawn.
- A file over 25 MB is rejected before decoding with `That photo is bigger than 25 MB. Choose a
  smaller one.`, and the existing photo (or initials) is unchanged.
- A non-image file is rejected with `That file isn't an image we can use. Choose a JPG, PNG, GIF or
  WebP.`, and the existing photo (or initials) is unchanged.
- A failed upload shows `We couldn't upload that photo. Please try again.` and leaves the previously
  stored photo in place and still rendered.
- Server-side validation independently enforces image content type, bounded dimensions, and a byte
  cap — a request that bypasses the JS hook cannot store an arbitrary file.
- A member's photo is served only to signed-in members; an unauthenticated request for it does not
  return the image.
- The photo appears in the global bar avatar, the club member list, and conversation avatar-stacks;
  members without a photo still show initials in the same places.
- Repeat page loads do not re-download unchanged photo bytes (ETag or equivalent).
- An open `/my/settings` refreshes when the photo changes.
- Existing person, membership, messaging, and email behaviours continue to pass — in particular,
  email templates still render initials.

## Open Business Decisions

None known.

Decided during planning:

- **Postgres `bytea`, not object storage.** No new infrastructure, credentials, or bucket lifecycle;
  works with `auto_stop_machines`; included in existing backups; reversible later.
- **Browser-side resize, no server image library.** Avoids adding ImageMagick/Vix to the Docker image
  and devenv.
- **Automatic centre-crop, no crop UI.** Cheapest path, and the design stays accurate.
- **Signed-in-only photo serving.** Every member surface already sits behind `club_member_required`;
  a member's face should not hang on a guessable public URL. The cost is that photos cannot appear in
  emails, which is accepted.

## Implementation Plan

1. Inspect `MySettingsLive` after iteration 054, the Person aggregate/projection, the avatar rendering
   points (`core_components.ex`, `layouts.ex`, `member_dashboard_presentation.ex`,
   `club.html.heex`, `admin_components.ex`), and the shared avatar CSS in `styles.css` before changing
   anything.
2. Add a `person_photos` table keyed by `person_id`: bytes, content type, byte size, a content hash
   for ETag/cache-busting, and timestamps. One current row per Person.
3. Add Membership commands/events for the state transitions: a photo being set (or replaced) and a
   photo being removed. Keep the **bytes out of the event store** — events carry the reference and
   metadata (hash, content type, size); the bytes live in the projection table. Recording megabytes of
   image data as immutable domain events would bloat the store permanently and is the main modelling
   trap in this slice.
4. Add the application-service entry points on `Memba.Membership`, returning tagged errors the
   LiveView renders as the designed messages.
5. Project photo state into the Person read model (has-photo, content hash) so avatar rendering can
   decide between photo and initials without loading bytes, and publish on `Memba.ReadModelChanges`
   per [ADR 0021](../../adr/0021-publish-committed-read-model-changes.md).
6. Add the photo-serving controller action under the `club_member_required` pipeline, with `ETag` and
   `Cache-Control`, returning 404 for a Person with no photo.
7. Write the LiveView JS hook: reject >25 MB and non-image files before decoding, decode into a
   canvas, centre-crop to a square, downscale to 256×256, export to a compressed blob, hand it to the
   LiveView upload. Report client-side rejections back to the LiveView so it can render the designed
   error states.
8. Wire `allow_upload/3` with server-side validation that does not trust the hook: sniff the content
   type from the bytes, bound the decoded dimensions, and cap stored size.
9. Build the Profile tab photo field per the design, including uploading, rejected, and failed states,
   with stable IDs for LiveView tests.
10. Update the shared avatar rendering so a photo fills the existing circle and initials remain the
    fallback, at every avatar site found in step 1. Keep email templates on initials.
11. Add domain tests for set/replace/remove and the read-model projection.
12. Add controller tests for photo serving: signed-in success, unauthenticated rejection, 404 without
    a photo, and ETag/conditional-request behaviour.
13. Add LiveView tests for the empty, set, uploading, rejected, failed, and removed states, plus live
    refresh.
14. Implement the `@iteration-055` acceptance scenarios and remove their `@todo-domain @todo-ui` tags.
15. Run `dev check` and fix all issues.

## Open Technical Decisions

- **Where the bytes are read from on render.** The controller reads from the projection table. Whether
  that table is queried through `Memba.Membership` or a narrower photo-serving read module is an
  implementation judgement; prefer whichever keeps the projection's storage details from leaking into
  the web layer, consistent with how the other read models are accessed.
- **Cache-busting shape.** Either a content hash in the photo URL with a long `Cache-Control`, or a
  stable URL with `ETag` revalidation. The hashed-URL form avoids stale avatars after a change with no
  revalidation round trip and is preferred, but either satisfies the acceptance criteria.
- **Test fixtures for uploads.** The acceptance scenarios name photo files; the browser Cucumber suite
  will need small committed fixture images and a way to drive a file input through a LiveView upload.
  Settle the fixture location and size during implementation.
- **Whether the JS hook needs a no-JS fallback.** The app is LiveView-first and already requires JS to
  function, so a hook is consistent with ADR 0015; a degraded no-hook upload path is probably
  unnecessary, but the server-side validation in step 8 must stand alone regardless.

## New Capability

Memba can accept, store, and serve member-supplied images — its first upload pipeline. Members become
recognisable to each other by face rather than by two letters. The pattern established here (validate
in the browser, re-validate on the server, store in Postgres, serve behind auth with cache headers) is
the reference for any later image feature, and the decision to keep bytes out of the event store is
the precedent that matters most.

## Validation Plan

- Run `dev check` after implementation.
- Domain/context tests:
  - setting a photo records it and updates the read model;
  - a second upload replaces the first;
  - removing a photo clears it and restores initials-only state;
  - events carry metadata and references, not image bytes.
- Controller tests:
  - a signed-in member can fetch another member's photo;
  - an unauthenticated request does not return the image;
  - a Person with no photo returns 404;
  - a conditional request with a matching validator is not re-sent.
- LiveView tests:
  - empty state renders initials and `Add a photo`;
  - a successful upload renders the photo;
  - an oversized file renders the 25 MB message and leaves state unchanged;
  - a non-image file renders the file-type message and leaves state unchanged;
  - a failed upload renders the failure message with the previous photo still shown;
  - remove restores initials;
  - an open settings page refreshes after a change elsewhere.
- Acceptance tests:
  - the seven `@iteration-055` scenarios in `member_profile.feature`, with the temporary
    `@todo-domain @todo-ui` tags removed.
- Manual demo:
  1. Sign in as a club member with no photo; confirm initials in the global bar and member list.
  2. Account settings → Profile → `Add a photo`; choose a large, non-square phone photo.
  3. Confirm the progress state, then the square photo, with no distortion.
  4. Confirm the photo in the global bar, the club member list, and a conversation avatar-stack.
  5. Sign in as another member of the same club and confirm they see the photo.
  6. Sign out and request the photo URL directly; confirm it is not served.
  7. Choose a PDF and confirm the file-type message; confirm the existing photo is untouched.
  8. `Remove photo`; confirm initials return everywhere.
  9. Send a club message and confirm the email still renders initials.

## Risks / Follow-ups

- **Event-store bloat** is the biggest modelling risk. If image bytes end up in events, the store
  grows permanently and cannot be pruned. Step 3 exists to prevent it; review should check it.
- **Postgres row size and DB growth.** A 256×256 image is small, but this is still user media in the
  primary database. If Memba later hosts club photos or event images, revisit object storage — the
  serving route is the seam that makes that switch cheap.
- **The JS hook is trusted for convenience, never for safety.** If the server-side validation in step 8
  is weak, a crafted request could store arbitrary bytes that are later served to members. Treat this
  as the security-sensitive part of the iteration.
- **No moderation path.** A member can upload anything as their photo and only they can remove it. If
  a club needs a photo taken down, there is no workflow — capture a problem note rather than widening
  this slice.
- **Photos are absent from emails**, so a member's mail and the app will look different. Accepted
  consequence of signed-in-only serving; revisit only if it bothers people.
- **Animated GIFs are flattened.** Nobody has asked for animated avatars; note it if they do.
- Shared avatar CSS lives in `styles.css`, which `web/assets/css/app.css` imports into the real app.
  Changes there are app-wide, not preview-only — keep them to what filling an avatar circle with an
  image actually needs.
