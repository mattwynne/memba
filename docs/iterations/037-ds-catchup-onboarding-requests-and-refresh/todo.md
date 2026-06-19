# Implementation TODO

- [x] 001 Read the shipped surfaces to mirror them accurately: `auth_live/onboard.ex`, `get_started.html.heex`, `admin/requests_live/`, `Memba.Onboarding.NewRequestEmail`, and the then-current post-034 member templates (`page_html/club.html.heex`, `page_html/message.html.heex`, `member_message_live/`).
- [x] 002 Confirm the repo preview location/convention from 036 and the self-contained head block (daisyUI CDN + theme `:root` vars + needed raw tokens), reusing the phase-2 convention and class-mapping cheat sheet.
- [ ] 003 Author the public account-request flow preview (including email-verification states).
- [ ] 004 Author the staff request review & convert preview.
- [ ] 005 Author the new-request notification email preview; confirm/refresh the welcome email only if drifted.
- [ ] 006 Author the empty / first-run state preview(s).
- [ ] 007 Refresh the club-home and member-messaging/read previews to the post-034 member pages.
- [ ] 008 Render-verify each file with headless Chrome; fix any unstyled/broken components (watch for accidental Tailwind utility usage that won't resolve statically).
- [ ] 009 Ensure `@dsCard` headers and relative asset paths are correct on every new/changed file.
- [ ] 010 Run `dev check` to confirm the static files leave the build green.
