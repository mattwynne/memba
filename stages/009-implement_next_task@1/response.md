1. **Selected todo line**
   - `001 Read the shipped surfaces to mirror them accurately: auth_live/onboard.ex, get_started.html.heex, admin/requests_live/, Memba.Onboarding.NewRequestEmail, and the then-current post-034 member templates (...)`

2. **Changes made**
   - Added `docs/iterations/037-ds-catchup-onboarding-requests-and-refresh/surface-notes.md`
     - Captures routes, shells, IDs, copy, states, forms, email structure, empty states, and shared component cues from the shipped app surfaces.
     - Includes notes from:
       - `/auth/onboard`
       - `/get-started`
       - `/admin/requests`
       - `Memba.Onboarding.NewRequestEmail`
       - member club home, message detail/read, and compose surfaces
   - Updated only the selected todo line in `todo.md` from unchecked to checked.
   - No app code, routes, templates, LiveViews, tests, or feature files were changed.

3. **Focused validation**
   - `git diff --check` — passed with no whitespace errors.
   - `git status --short` — confirmed only:
     - modified `todo.md`
     - new `surface-notes.md`
   - I did not run `dev check` because this was a docs-only/planning-note task; the repo instructions say not to run it for docs-only changes unless explicitly needed.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 001 Read the shipped surfaces...`
   - To:
     - `- [x] 001 Read the shipped surfaces...`

5. **Todo splits/additions/reordering**
   - None. I implemented exactly the first unchecked task.

6. **ADR conformance evidence**
   - The plan did not explicitly reference any ADRs.
   - I inspected current nearby ADRs:
     - ADR 0015: member application pages use LiveView by default.
     - ADR 0016: email provider choice remains switchable at the boundary.
   - The captured notes reflect the current LiveView member surfaces and email-provider-neutral notification design without changing architecture or behaviour.