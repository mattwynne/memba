# Problems

## Sign-in email shows the wrong Memba icon

Observed: 2026-06-06

Status: Resolved by [iteration 031: Brand, email, and navigation polish](../iterations/031-brand-email-navigation-polish/plan.md). Sign-in email tests now assert the Memba sprig branding rather than the old check icon. Evidence: `web/test/memba/accounts/auth_email_test.exs`.

The Memba sign-in email shows a check icon instead of the Memba sprig icon.

Expected:

- The sign-in email uses the correct Memba sprig icon.
- People receiving the email see branding that matches Memba.
