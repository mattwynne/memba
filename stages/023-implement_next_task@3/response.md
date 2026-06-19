1. **Selected todo line**
   - `003 Author the public account-request flow preview (including email-verification states).`

2. **Changes made**
   - Added `design-system/wireframes/onboarding-request-flow.html`.
   - The preview includes:
     - `@dsCard` / `@startingPoint` headers.
     - Self-contained daisyUI CDN + app theme `:root` variables.
     - Public `/get-started` signed-out email-verification state.
     - `/auth/check-email/:request_id` progress states.
     - Verified-email requester form.
     - Existing signed-in requester form.
     - Submitted acknowledgement state.
     - `/auth/onboard` staff onboarding branch, since the plan calls out `AuthLive.Onboard`.
   - No app code, routes, LiveViews, templates, or `.feature` files were changed.

3. **Focused validation run**
   - `python3` static preview marker/class scan — passed.
     - Confirmed required shipped-state markers and no Tailwind utility classes in the preview markup.
   - `python3` HTML/head marker check — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed.
     - `799 tests, 0 failures`.
   - `git diff --check -- docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/todo.md` — passed.
   - Preview whitespace/final-newline check — passed.
   - Final `git status --short` shows only:
     - `M docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/todo.md`
     - `?? design-system/wireframes/onboarding-request-flow.html`

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 003 Author the public account-request flow preview (including email-verification states).`
   - To:
     - `- [x] 003 Author the public account-request flow preview (including email-verification states).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0015 remains respected: no member app rendering architecture was changed.
   - ADR 0016 remains respected: no email delivery/provider logic was changed.
   - This task only adds a static DS preview artifact and does not alter application behavior or acceptance coverage.