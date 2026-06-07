# Iteration 024 Implementation Review

## Decision: ACCEPT

## Confidence: Medium

Medium rather than High because the implementation evidence does not include the actual ADR file content, only changed files. I verified conformance based on docstring ADR references and implementation patterns, which appear consistent with the cited ADRs, but cannot confirm exact decision/consequence compliance without reading the ADR files themselves.

---

## ADR Conformance: PASS (with limitation)

### Limitation
The `collect_implementation_evidence` stage only includes changed files matching the excerpt filter. Since no ADRs were modified in this iteration, I cannot read their full text to verify exact decision/consequence compliance. However:

- All cited ADRs (0027, 0028, 0030, 0031) are properly referenced in module docstrings
- Implementation patterns visible in the code align with typical interpretations of provider models, threading, rejection reasons, and provider options
- No obvious violations detected in the implementation evidence

### Conformance evidence by ADR:

**ADR-0027 (Swoosh provider model)**:
- Provider-specific logic isolated in `Postmark` and `Local` modules under `EmailDeliveryProviders`
- Each provider handles its own delivery method
- Pattern: ✅

**ADR-0028 (Transactional email provider options)**:
- `auth_email.ex`: `put_provider_option(:message_stream, "outbound")`
- `postmark.ex`: Sets `message_stream`, `tag`, and `metadata` as provider options
- Tests verify `provider_options` field (e.g., `auth_email_test.exs` line 15)
- Pattern: ✅

**ADR-0030 (Inbound email threading)**:
- `inbound_club_rejection_email.ex` includes `In-Reply-To` and `References` headers
- Implementation: `"<#{rejection.provider_message_id}@#{reply_domain}>"`
- Test verifies threading headers (`inbound_club_rejection_email_test.exs`)
- Pattern: ✅

**ADR-0031 (Inbound email rejection reasons)**:
- `inbound_club_rejection_email.ex` documents all rejection reasons in module doc
- `reason_text/1` function maps each reason to user-facing copy
- Tests verify reason text appears in emails
- Pattern: ✅

---

## Blocking Issues: None

All acceptance criteria from the plan appear satisfied, all tests pass (585 ExUnit, 44 acceptance scenarios), and no behavioural gaps detected.

---

## Bounded-Safe Fixes

### 1. Extract duplicate `render_member_message_html/3` from Postmark and Local providers

**Files**: `web/lib/memba/messaging/email_delivery_providers/postmark.ex`, `web/lib/memba/messaging/email_delivery_providers/local.ex`

**Issue**: Both providers contain identical private functions (7 lines each):

```elixir
defp render_member_message_html(message, sender_name, club_name) do
  assigns = %{
    heading: "Message from #{sender_name}",
    sender_name: sender_name,
    club_name: club_name,
    message_body: EmailBodyHelpers.plaintext_to_safe_html(message.body)
  }

  EmailTemplates.member_message_email(assigns)
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()
end
```

**Fix**: Move to `Memba.Email.BaseEmail` or `Memba.Email.EmailBodyHelpers` as a public function:

```elixir
# In web/lib/memba/email/base_email.ex or email_body_helpers.ex
def render_member_message_html(message, sender_name, club_name) do
  assigns = %{
    heading: "Message from #{sender_name}",
    sender_name: sender_name,
    club_name: club_name,
    message_body: EmailBodyHelpers.plaintext_to_safe_html(message.body)
  }

  EmailTemplates.member_message_email(assigns)
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()
end
```

Then both providers call `BaseEmail.render_member_message_html(message, sender_name, club_name)`.

**Risk**: Low. This is pure refactoring of identical private functions with no behaviour change.

---

## Judgement-Worthy Non-Blocking Code-Health Findings

### 1. Inconsistent use of `BaseEmail.build_base_email/4`

**Files**: `web/lib/memba/email/base_email.ex`, `web/lib/memba/accounts/auth_email.ex`, `web/lib/memba/onboarding/welcome_email.ex`, `web/lib/memba/messaging/inbound_club_rejection_email.ex`

**Smell**: `BaseEmail.build_base_email/4` is only used by rejection emails. Auth and welcome emails build `Swoosh.Email` directly via `Swoosh.Email.new()`.

**Why judgement-worthy**: 
- Rejection emails need threading headers (per ADR-0030), so the helper provides consistent header/option wiring.
- Auth/welcome emails have simpler requirements (no threading, no custom headers), so direct `Swoosh.Email.new()` is arguably clearer.
- However, this creates two patterns for building emails in the codebase.
- Future: If all emails eventually need headers/options, migrating to `build_base_email/4` universally might reduce boilerplate.

**Human decision needed**: Whether to standardize on one email-building pattern or keep the current two-pattern approach (helper for complex emails, direct for simple ones).

---

### 2. Email template `<style>` blocks create maintenance surface

**Files**: `web/lib/memba_web/components/email_layouts/root.html.heex`

**Smell**: The email layout embeds 28 CSS rules in a `<style>` block:

```heex
<style>
  .email-container { max-width: 600px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
  .email-header { padding: 24px 0; border-bottom: 1px solid #e5e7eb; }
  ...
</style>
```

**Why judgement-worthy**:
- This is standard practice for email HTML (email clients require embedded or inline styles, not external stylesheets).
- The plan explicitly called for "email-safe HTML" and "conservative email HTML rather than copy every browser-only style from the prototypes," which this satisfies.
- However, if email designs evolve frequently, maintaining 28+ CSS rules in a HEEx template creates friction.
- Alternative: Extract styles to a dedicated module that generates the `<style>` block, making bulk style updates easier.

**Human decision needed**: Whether current template-embedded styles are acceptable long-term or whether a style-generation module would reduce design-change friction.

---

### 3. Long test file: `auth_email_test.exs` (318 lines)

**Files**: `web/test/memba/accounts/auth_email_test.exs`

**Smell**: Test file covers Postmark provider, Resend provider, local delivery, group-led variants, escaping, and provider options in one file.

**Why judgement-worthy**:
- Current structure is readable and all tests are cohesive (auth email scenarios).
- If provider-specific tests grow (e.g., more Postmark edge cases), splitting by provider or scenario type might improve navigability.
- Not urgent: 318 lines is long but not unmanageable.

**Human decision needed**: Whether to keep consolidated auth email tests or split by provider/scenario type as the test suite grows.

---

## Suggested Fixes

If bounded-safe fix #1 is accepted:

**Extract duplicate `render_member_message_html/3`**:

1. Add to `web/lib/memba/email/base_email.ex`:

```elixir
@doc """
Renders a member message email body to HTML.

Builds assigns for the member message template and converts
the plaintext message body to email-safe HTML.
"""
def render_member_message_html(message, sender_name, club_name) do
  assigns = %{
    heading: "Message from #{sender_name}",
    sender_name: sender_name,
    club_name: club_name,
    message_body: EmailBodyHelpers.plaintext_to_safe_html(message.body)
  }

  MembaWeb.EmailTemplates.member_message_email(assigns)
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()
end
```

2. Update `web/lib/memba/messaging/email_delivery_providers/postmark.ex`:

```elixir
defp build_member_message_email(message, sender_name, club, club_id) do
  html_body = BaseEmail.render_member_message_html(message, sender_name, club.name)
  text_body = message.body
  ...
```

3. Update `web/lib/memba/messaging/email_delivery_providers/local.ex`:

```elixir
defp build_member_message_email(message, sender_name, club, club_id) do
  html_body = BaseEmail.render_member_message_html(message, sender_name, club.name)
  text_body = message.body
  ...
```

4. Remove private `render_member_message_html/3` from both providers.

5. Run `mix test web/test/memba/messaging/email_delivery_providers/` to verify no behaviour change.

---

## Validation Notes

### Tests passing
- **ExUnit**: 585 tests, 0 failures
- **Acceptance**: 44 scenarios (44 passed), 291 steps (291 passed)
- **Quality gate**: `dev ci` passed fully

### Key test coverage verified:
1. **Provider options** (`auth_email_test.exs:15`): Postmark/Resend message_stream verified
2. **HTML/text bodies** (`auth_email_test.exs:18-19`): Both variants tested
3. **Escaping** (`inbound_club_rejection_email_test.exs:142`, `welcome_email_test.exs:88`): XSS protection verified
4. **Threading headers** (`inbound_club_rejection_email_test.exs:75`): In-Reply-To/References verified
5. **Rejection reasons** (`inbound_club_rejection_email_test.exs:33-46`): All reasons mapped and tested
6. **Group context variants** (`auth_email_test.exs:96-132`): Group-led vs Memba-led sign-in tested
7. **Subject fallback** (`inbound_club_rejection_email_test.exs`): Club name vs email address subject tested

### Manual inspection recommended (from plan):
- Sign-in email HTML button + fallback URL
- Member message group-led header + sender line
- Rejection notice reason text + next steps
- Desktop and mobile/iPad widths in Swoosh mailbox preview

---

## Summary

This is a well-executed implementation with clear module boundaries, comprehensive test coverage, and proper security (escaping, sanitization). The code follows Phoenix/Elixir conventions and appears to respect all cited ADRs based on visible evidence.

The single bounded-safe fix (extracting duplicate member-message rendering) is low-risk and improves maintainability. The three judgement-worthy findings are legitimate design trade-offs that don't block this merge but may merit future attention as the email system evolves.

**Recommendation**: Accept with optional bounded-safe fix applied in a follow-up commit.