# Production smoke tests

This directory contains Cucumber smoke tests for real production inbound club email wiring. They send real email to Memba through a controlled Fastmail mailbox, poll Fastmail for resulting emails, and use Playwright to check member/staff-visible UI.

## Required production fixture

- Club name: `Smoke Test Club`
- Club slug: `test`
- Inbound address: `everyone@test.clubs.memba.io`
- Known active member email: `test@memba.io`
- Unknown-sender address: an unregistered Fastmail alias such as `test+unknown@memba.io`
- The smoke-test club should not appear as a public club page or in ordinary public discovery surfaces.

HTML-only email is intentionally not a production smoke case. Lower-level tests cover the `plain_text_required` business rule; these smoke tests focus on production wiring.

## Environment

Required:

```sh
export MEMBA_SMOKE_STAFF_EMAIL="..."
export MEMBA_SMOKE_FASTMAIL_PASSWORD="..."      # Fastmail app password for SMTP and IMAP access to test@memba.io
export MEMBA_SMOKE_UNKNOWN_EMAIL="test+unknown@memba.io" # unregistered Fastmail alias that receives rejection email

# Optional: use JMAP instead of IMAP polling. The runner listens to JMAP EventSource changes when available.
export SMOKE_TEST_EMAIL_API_KEY="..."           # or MEMBA_SMOKE_FASTMAIL_JMAP_TOKEN / FASTMAIL_API_KEY

# Optional but recommended while diagnosing provider receiving/webhook boundaries:
export MEMBA_SMOKE_POSTMARK_SERVER_TOKEN="..."  # Postmark server token for /messages/inbound history
```

Optional/defaulted:

```sh
export MEMBA_SMOKE_BASE_URL="https://memba.io"
export MEMBA_SMOKE_CLUB_NAME="Smoke Test Club"
export MEMBA_SMOKE_CLUB_SLUG="test"
export MEMBA_SMOKE_INBOUND_DOMAIN="clubs.memba.io"
export MEMBA_SMOKE_CLUB_SITE_BASE_DOMAIN="clubs.memba.io"
export MEMBA_SMOKE_MEMBER_EMAIL="test@memba.io"
export MEMBA_SMOKE_FASTMAIL_USER="test@memba.io"

# If the staff sign-in mailbox is separate from test@memba.io:
export MEMBA_SMOKE_STAFF_FASTMAIL_USER="..."
export MEMBA_SMOKE_STAFF_FASTMAIL_PASSWORD="..."
export MEMBA_SMOKE_STAFF_FASTMAIL_JMAP_TOKEN="..." # optional; otherwise IMAP uses the Fastmail app password

export MEMBA_SMOKE_POSTMARK_INBOUND_MESSAGE_STREAM="..." # optional, if the inbound stream must be filtered explicitly

export MEMBA_SMOKE_POLL_TIMEOUT_MS="120000"
export MEMBA_SMOKE_POLL_INTERVAL_MS="5000"
export HEADLESS="false" # optional, for watching Playwright
```

The smoke runner intentionally does not support Hotmail, Yahoo, or arbitrary SMTP/IMAP providers. See `docs/adr/0020-use-fastmail-for-production-email-smoke-tests.md` for the decision record.

## Run

When `MEMBA_SMOKE_POSTMARK_SERVER_TOKEN` is set, each scenario checks Postmark inbound message history immediately after SMTP acceptance for the configured smoke recipient, which defaults to `everyone@test.clubs.memba.io`. That narrows failures before the mailbox/UI waits: no Postmark inbound message means the problem is still at DNS/provider receiving; a Postmark inbound message with no Memba-visible outcome points to webhook delivery or application processing.

The script reuses the Cucumber and Playwright dependencies already installed for `acceptance-tests`:

```sh
cd smoke-tests
npm test
```

Run headed:

```sh
cd smoke-tests
npm run test:headed
```
