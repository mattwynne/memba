# 20. Use Fastmail for production email smoke tests

Date: 2026-06-04

## Status

accepted

## Context

Inbound club email crosses several production boundaries: the sender mailbox, public MX records, Postmark inbound receiving, the Memba webhook, Memba business rules, outbound delivery, and the member/staff UI. Unit, controller, and acceptance tests can prove the business rules while still missing real production wiring failures.

During the Postmark inbound-email cutover we therefore added production smoke tests that send real email to `test@clubs.memba.io` and assert the observable outcomes:

- an unknown sender receives a rejection email and no club message is created;
- a known active member's email becomes a visible club message and is distributed;
- a known active member's email with an attachment is rejected.

We tried to make the unknown-sender case use external consumer mailboxes such as Hotmail or Yahoo, hoping this would better exercise delivery from outside the `memba.io` Fastmail account. That added provider-specific SMTP/IMAP configuration to the smoke runner.

This proved to be a distraction from the core smoke-test goal. The Hotmail account could connect to Microsoft's IMAP and SMTP servers, but basic username/password authentication failed. IMAP reported `BasicAuthBlocked`, and SMTP returned `535 5.7.3 Authentication unsuccessful`. Supporting that account would require OAuth2/XOAUTH2 or further provider-specific setup. Yahoo was also not working reliably enough to use now. Continuing down this path would turn a production wiring smoke test into a general mail-provider compatibility project.

The smoke tests need a controlled sender/receiver that is boring, scriptable, and quick to diagnose. Their purpose is to protect Memba's deployed inbound email path, not to prove that arbitrary consumer email providers can be automated.

## Decision

Keep the production email smoke tests Fastmail-only.

Use the controlled `test@memba.io` Fastmail mailbox for:

- member sign-in emails;
- known-member SMTP sending;
- distributed-copy polling;
- staff sign-in polling by default;
- unknown-sender SMTP sending and rejection polling, using an unregistered Fastmail alias such as `test+unknown@memba.io` as the message `From` address.

Keep optional Postmark inbound-history diagnostics in the runner because they identify whether a failure is before or after the provider receiving boundary.

Do not support Hotmail, Yahoo, Outlook, or arbitrary SMTP/IMAP providers in the smoke-test code for now. Do not add XOAUTH2/OAuth support unless a future need justifies making external mailbox automation part of the product's test infrastructure.

## Consequences

The smoke runner becomes smaller and easier to operate. It has one SMTP/IMAP/JMAP provider model, fewer secrets, fewer provider-specific environment variables, and fewer misleading failure modes.

The tests still exercise the important production path from a real mailbox through public DNS/MX, Postmark inbound receiving, the production webhook, Memba's inbound-email rules, outbound email delivery, and browser-visible results.

The unknown-sender smoke no longer proves behaviour for a completely independent external mailbox provider. That is acceptable because the business rule depends on the sender address not being a known active member, not on the sender's mailbox provider.

There remains a small risk that Fastmail-specific sending behaviour differs from other providers. If that matters later, add a separate provider-compatibility investigation or manual smoke checklist rather than expanding the deployment smoke runner by default.

If we later need automated external-provider smoke tests, revisit this ADR and design that work explicitly around OAuth2/XOAUTH2, provider account policy, secret rotation, and diagnostics.
