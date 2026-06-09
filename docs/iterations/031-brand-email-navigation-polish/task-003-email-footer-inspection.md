# Task 003 transactional email footer inspection

Selected task:

- `003 Inspect the transactional email layout/helpers from iteration 024 and identify the canonical footer component or helper.`

## Sources inspected

- `docs/iterations/024-email-template-designs/plan.md`
- `docs/iterations/024-email-template-designs/implementation-notes.md`
- `web/lib/memba/email_templates.ex`
- Current transactional email renderers that call `Memba.EmailTemplates.render_shell/1`

## Findings

- Iteration 024 introduced `Memba.EmailTemplates` as the shared transactional email rendering layer.
- `Memba.EmailTemplates.render_shell/1` owns the common v2-compatible document shell/card container and accepts a trusted `:footer` fragment supplied by each email renderer.
- The canonical standard transactional footer helper is:
  - `Memba.EmailTemplates.memba_footer/1`
- `memba_footer/1` renders the consistent Memba footer row with:
  - a Memba mark plus the “Delivered by Memba” / “Delivered for <group> by Memba” line;
  - a link to `https://memba.io`;
  - optional `:recipient_email`, `:reason`, and `:reply_to_email` detail lines;
  - generic support copy when no configured reply-to address is provided, without hard-coding an unconfirmed support mailbox.
- `Memba.EmailTemplates.trust_footer/1` is a separate sign-in/security trust band (“Secured by Memba”). It is useful for auth-like emails, but it is not the general-purpose standard transactional footer.

## Current footer inventory

| Email renderer | Current footer treatment | Notes for later tasks |
| --- | --- | --- |
| `Memba.Accounts.AuthEmail` | `EmailTemplates.trust_footer/1` plus private `auth_footer/1` | Replace the private footer row with `EmailTemplates.memba_footer/1` while preserving the trust band. |
| `Memba.Onboarding.WelcomeEmail` | `EmailTemplates.trust_footer/1` plus private `welcome_footer/1` | Same pattern as sign-in; useful context if task 009 standardises remaining current transactional templates mechanically. |
| `Memba.Membership.ClubMemberInvitationEmail` | Invitation-specific trust band plus `EmailTemplates.memba_footer/1` | Already uses the canonical footer helper. |
| `Memba.Messaging.MemberMessageEmail` | `EmailTemplates.memba_footer/1` | Already uses the canonical footer helper. |
| `Memba.Messaging.InboundClubRejectionEmail` | `EmailTemplates.memba_footer/1` | Already uses the canonical footer helper; later rejection tasks should add/assert behaviour without redesigning this footer. |

## Identified implementation direction

For the remaining footer work in this iteration, treat `Memba.EmailTemplates.memba_footer/1` as the standard transactional email footer. Auth/sign-in emails can still render `EmailTemplates.trust_footer/1` before it because that trust band carries sign-in-specific security reassurance; the standard footer row should come from `memba_footer/1`.
