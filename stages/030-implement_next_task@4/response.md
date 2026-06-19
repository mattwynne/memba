1. **Selected todo line**
   - `004 Author the profile-completion preview.`

2. **Changes made**
   - Added `design-system/wireframes/profile-completion.html`.
   - The preview is self-contained with:
     - `@dsCard` and `@startingPoint` headers.
     - daisyUI CDN CSS.
     - Memba theme tokens copied inline.
     - Plain CSS for layout; no app CSS links.
   - Mirrored the shipped profile completion surface from:
     - `web/lib/memba_web/controllers/club_member_invitation_html/profile.html.heex`
     - `web/lib/memba_web/controllers/club_member_invitation_controller.ex`
   - Included the real shipped structure/copy/IDs for:
     - `club-member-profile-completion`
     - `club-member-profile-completion-form`
     - `club-member-profile-name-input`
     - `complete-club-member-profile-button`
     - “Tell us your name”
     - “Your name”
     - `Robin Example`
     - “Join Kootenay Alpine Club”
   - Included the representative validation state:
     - Flash/error copy: `Please tell us your name.`
     - Input error state for the name field.
   - Did not change app code, routes, templates, LiveViews, or `.feature` files.

3. **Focused validation run**
   - `git diff --check -- design-system/wireframes/profile-completion.html docs/iterations/036-ds-catchup-member-management-and-auth/todo.md`
     - Passed.
   - Python static preview validation:
     - Confirmed first-line `@dsCard`.
     - Confirmed daisyUI CDN link.
     - Confirmed no app/shared CSS asset links.
     - Confirmed final newline.
     - Confirmed no Tailwind-like utility classes in HTML class attributes beyond allowed daisyUI classes.
     - Confirmed shipped IDs and key copy are present.
     - Passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed.
     - ExUnit: `799 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 004 Author the profile-completion preview.`
   - To:
     - `- [x] 004 Author the profile-completion preview.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Plan references no ADRs explicitly.
   - Reviewed relevant accepted ADRs:
     - ADR 0015: this task only mirrors the existing shipped controller-rendered invitation profile surface; it does not introduce new member app implementation or routing changes.
     - ADR 0016: no provider-specific email behavior or dependencies were introduced.
     - ADR 0006: no delivery-status model/UI behavior was changed.
     - ADR 0013: no app behavior changed, so no new PhoenixTest coverage was needed; validation used static preview checks plus `dev check --quick`.