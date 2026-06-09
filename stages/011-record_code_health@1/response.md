I’ll append the supported judgement-worthy review findings to `docs/code-health.md` under a dated iteration section, since the synthesis omitted them but all independent reviewers identified them.{"cmd": "sed -n '1,240p' docs/code-health.md"}CODE_HEALTH_RECORDING_FAILED: I could not edit `docs/code-health.md` because this chat has no repository file-editing/tool access available.

The following findings still need recording under a dated section for `docs/iterations/031-brand-email-navigation-polish/plan.md`. The review synthesis omitted them, but independent reviewer reports consistently identified them as judgement-worthy:

```md
## 2026-06-09 – Iteration 031 brand/email/navigation polish review

Plan: `docs/iterations/031-brand-email-navigation-polish/plan.md`

Note: Review synthesis did not list code-health findings, but independent reviewer reports identified the following judgement-worthy issues.

### Root-domain derivation is becoming domain-routing logic

- Evidence: `web/lib/club_site_web.ex` includes helper logic for producing the main Memba root URL from club-site/subdomain context.
- Risk: This is correct for the current club-subdomain case, but future host families such as staff, API, staging, regional, or custom club domains could make localized string-shaping fragile.
- Suggested next action: If more domain patterns are introduced, centralize host/root URL generation in a dedicated domain-routing or URL-configuration module.

### Contextual sender display-name format is inline

- Evidence: `web/lib/memba/messaging/inbound/reject_message.ex` constructs the rejection sender display name using the product-specific `<club name> via Memba` format at the call site.
- Risk: Not duplicated today, but future contextual emails could produce inconsistent “via Memba” formatting if each constructs sender names independently.
- Suggested next action: If additional emails use contextual sender display names, extract a small sender-identity helper/builder and test it centrally.

### Support contact information remains partly hardcoded

- Evidence: `support@memba.io` appears as a literal/default in the transactional footer component and related email copy.
- Risk: If support addresses become environment-specific, tenant-specific, or operationally rotated, scattered literals will be harder to update safely.
- Suggested next action: When support contact flexibility is needed, move support contact details into shared application configuration or a small contact-info helper.

### Email rendering coverage is structural, not client-realistic

- Evidence: Email tests verify generated HTML structure, footer/sprig presence, sender shape, and copy using DOM-style assertions.
- Risk: These tests do not catch real email-client quirks such as SVG rendering, CSS limitations, layout differences, or accessibility behavior in inbox clients.
- Suggested next action: If transactional email presentation becomes more critical, add preview tooling or periodic real-inbox smoke checks for sign-in and rejection emails.
```