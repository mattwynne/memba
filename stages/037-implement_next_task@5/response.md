1. **Selected todo line**
   - `005 Author the new-request notification email preview; confirm/refresh the welcome email only if drifted.`

2. **Changes made**
   - Added `design-system/emails/new-request-notification.html`.
   - The preview includes:
     - `@dsCard` and `@startingPoint` headers.
     - Self-contained daisyUI CDN + Memba theme `:root` variables.
     - A mail-client style wrapper with subject/envelope metadata:
       - From: `Memba <hello@memba.io>`
       - To: `hello@memba.io`
       - Reply-To requester
       - outbound stream marker
     - Rendered HTML body mirroring `Memba.Onboarding.NewRequestEmail` / `EmailTemplates`:
       - Memba staff notification header.
       - “New Memba access request” heading and plain-text-derived request details.
       - Direct `/admin/requests/:request_id` link.
       - Memba footer with shipped reason/support copy.
     - Plain-text fallback body.
     - Notes for recipient, reply path, and conversion deep link.
   - Confirmed repository-side email/welcome preview files: no repo-side welcome email preview exists to refresh, so I did not add an unrelated welcome preview.

3. **Focused validation commands run and results**
   - Static marker / forbidden shared-style check:
     - `python3 ...` — passed.
   - Static class scan for accidental Tailwind utility reliance:
     - `python3 ...` — passed.
   - Repository email/welcome preview search:
     - `find design-system spikes -path '*email*' -o -iname '*welcome*.html' | sort` — confirmed only the new request preview plus existing reply-notification spike/check-email files; no repo welcome preview to refresh.
   - Whitespace validation:
     - `git diff --check` — passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick` — passed.
     - Result: `799 tests, 0 failures`.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 005 Author the new-request notification email preview; confirm/refresh the welcome email only if drifted.`
   - To:
     - `- [x] 005 Author the new-request notification email preview; confirm/refresh the welcome email only if drifted.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0016 respected: this is a static preview only; no email provider, Swoosh/Mailer boundary, Resend/Postmark switching, webhook, or runtime email configuration changed.
   - No app code, routes, LiveViews, templates, acceptance features, or behavior changed.