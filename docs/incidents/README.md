# Production incidents

This directory records customer-visible production failures and serious production risks so that Memba can restore service, learn without blame, and prevent recurrence.

Incidents differ from:

- [`docs/problems/`](../problems/README.md), which captures product problems and opportunities;
- [`docs/kaizen/`](../kaizen/), which captures friction and defects in the delivery system; and
- iteration plans, which define a bounded change to deliver.

An incident may link to all three. The incident record remains the chronological account of what production did, how we responded, and which follow-up actions were agreed.

## Working agreement

- Protect people and data first; preserve evidence before changing production.
- Use UTC for timelines.
- Separate confirmed facts, hypotheses, and unknowns.
- Be blameless: examine the conditions and safeguards that shaped actions rather than attributing fault to a person.
- Record impact, detection, response, contributing factors, a Five Whys analysis, what went well, and follow-up actions.
- Give actions an owner, priority, status, and verification condition.
- Do not mark an incident resolved until service is restored and the restoration has been verified in production.
- Production mutations require explicit operator approval and an auditable runbook.

## Incident index

| Date | Incident | Impact | Status |
| --- | --- | --- | --- |
| 2026-09-15 | [Database restarted during release-command invariant checks](2026-09-15-release-invariant-database-restarts.md) | Two short database recovery windows; two deployments safely aborted; no data loss observed. | Mitigated — unsafe gate placement removed; infrastructure cause open |
| 2026-09-14 | [Custom-group creation rejected for legacy clubs](2026-09-14-custom-group-creation-forbidden.md) | Projected Admins in 2 of 5 populated production clubs could not create custom groups; no data loss or privacy breach observed. | Resolved 2026-09-15 — repaired and customer path verified |
