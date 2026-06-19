# Implementation TODO

- [x] 001 Read the shipped surfaces to mirror them accurately: `member_invitation_live/new.ex`, `admin/club_member_invitations_live/`, `club_member_invitation_html/profile.html.heex`, and `auth_live/sign_in.ex`; note the real fields, states, copy, and delivery-progress states.
- [x] 002 Confirm the repo preview location and the self-contained head block (daisyUI CDN + theme `:root` vars from `web/assets/css/app.css` + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.
- [x] 003 Author the invite-a-member preview (member-admin + staff variants).
- [x] 004 Author the profile-completion preview.
- [x] 005 Author the check-email / delivery-progress preview, covering the progress states.
- [x] 006 Extend the badges card with the role / Membership-Admin chips.
- [x] 007 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).
- [ ] 008 Ensure `@dsCard` headers and relative asset paths are correct on every new/changed file.
- [ ] 009 Run `dev check` to confirm the static files leave the build green.
