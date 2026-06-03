# Production smoke tests

This directory contains Cucumber smoke tests for real production inbound club email wiring. They send real email to Memba, poll Fastmail for resulting emails, and use Playwright to check member/staff-visible UI.

## Required production fixture

- Club name: `Test`
- Club slug: `test`
- Inbound address: `test@clubs.memba.io`
- Known active member email: `test@memba.io`
- The `Test` club should not appear in public-facing UI or ordinary member discovery surfaces.

HTML-only email is intentionally not a production smoke case. Lower-level tests cover the `plain_text_required` business rule; these smoke tests focus on production wiring.

## Environment

Required:

```sh
export MEMBA_SMOKE_STAFF_EMAIL="..."
export MEMBA_SMOKE_FASTMAIL_PASSWORD="..."      # SMTP app password for test@memba.io
export MEMBA_SMOKE_FASTMAIL_JMAP_TOKEN="..."    # Fastmail API token that can read test@memba.io
export MEMBA_SMOKE_UNKNOWN_EMAIL="..."          # unregistered sender that can receive rejection email
```

Optional/defaulted:

```sh
export MEMBA_SMOKE_BASE_URL="https://memba.io"
export MEMBA_SMOKE_CLUB_NAME="Test"
export MEMBA_SMOKE_CLUB_SLUG="test"
export MEMBA_SMOKE_INBOUND_DOMAIN="clubs.memba.io"
export MEMBA_SMOKE_CLUB_SITE_BASE_DOMAIN="memba.io"
export MEMBA_SMOKE_MEMBER_EMAIL="test@memba.io"
export MEMBA_SMOKE_FASTMAIL_USER="test@memba.io"

# If the unknown sender is a separate Fastmail account or token:
export MEMBA_SMOKE_UNKNOWN_FASTMAIL_USER="$MEMBA_SMOKE_UNKNOWN_EMAIL"
export MEMBA_SMOKE_UNKNOWN_FASTMAIL_PASSWORD="..."
export MEMBA_SMOKE_UNKNOWN_FASTMAIL_JMAP_TOKEN="..."

# If the staff sign-in mailbox is separate from test@memba.io:
export MEMBA_SMOKE_STAFF_FASTMAIL_JMAP_TOKEN="..."

export MEMBA_SMOKE_POLL_TIMEOUT_MS="120000"
export MEMBA_SMOKE_POLL_INTERVAL_MS="5000"
export HEADLESS="false" # optional, for watching Playwright
```

## Run

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
