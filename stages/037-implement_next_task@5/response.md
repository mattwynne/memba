1. **Selected todo line**
   - `005 Author the check-email / delivery-progress preview, covering the progress states.`

2. **Changes made**
   - Added `design-system/wireframes/check-email-delivery-progress.html`.
   - Preview is self-contained with:
     - first-line `@dsCard` header;
     - `@startingPoint` header;
     - daisyUI prebuilt CDN CSS;
     - inline Memba theme tokens;
     - plain CSS for all layout/styling;
     - no app/shared CSS links.
   - Mirrored the shipped `AuthLive.SignIn` check-email surface:
     - `/auth/check-email`
     - `/auth/check-email/:request_id`
     - IDs/copy including:
       - `auth-sign-in-sent`
       - `sign-in-link-sent-notice`
       - `auth-email-progress`
       - `auth-email-progress-message`
       - `request-another-sign-in-link`
       - “Check your email for the sign-in link.”
       - “Sign-in link progress”
   - Covered the delivery-progress states from iteration 032:
     - no request ID / neutral guidance
     - created / preparing
     - sent / neutral
     - provider accepted
     - fallback after no accepted event
     - expired request
   - Did not change app code, routes, LiveViews, templates, or `.feature` files.

3. **Focused validation run**
   - `git diff --check -- design-system/wireframes/check-email-delivery-progress.html docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`
     - Passed.
   - Python static preview validation:
     - confirmed first-line `@dsCard`;
     - confirmed `@startingPoint`;
     - confirmed daisyUI CDN;
     - confirmed no unexpected stylesheet links;
     - confirmed required shipped IDs/copy/progress messages;
     - confirmed no “email is in your inbox” overclaim;
     - confirmed final newline;
     - checked for unresolved Tailwind-like class markers.
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed.
     - ExUnit: `799 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 005 Author the check-email / delivery-progress preview, covering the progress states.`
   - To:
     - `- [x] 005 Author the check-email / delivery-progress preview, covering the progress states.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Plan references no ADRs explicitly.
   - Reviewed relevant accepted ADR context:
     - ADR 0021 / 0022: this task only documents the shipped committed-progress/live-update surface; no read-model/PubSub/projection behavior was changed.
     - ADR 0016: no email provider behavior or dependencies were changed.
   - Static DS-only change stays within the approved iteration scope and does not alter app behavior.