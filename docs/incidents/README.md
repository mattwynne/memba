# Production incidents

This directory records customer-visible production failures and serious production risks so that Memba can restore service, learn without blame, and prevent recurrence.

Incidents differ from:

- [`docs/problems/`](../problems/README.md), which captures product problems and opportunities;
- [`docs/kaizen/`](../kaizen/), which captures friction and defects in the delivery system; and
- iteration plans, which define a bounded change to deliver.

An incident may link to all three. The incident record remains the chronological account of what production did, how we responded, and which follow-up actions were agreed.

## Lifecycle

- **Active** — customer or production impact is continuing and response work is under way.
- **Mitigated** — immediate impact has stopped, but the underlying condition is not yet permanently resolved or sufficiently understood.
- **Resolved** — service and the incident condition have been repaired and verified in production. Agreed follow-up actions may still be open.
- **Closed** — the incident is resolved and every agreed follow-up action is completed or explicitly deferred with a recorded rationale.

The index is the incident-status ledger. Its open-follow-up count must agree with the action table in each incident record. Closing an incident requires updating both the record and the index.

## Working agreement

- Protect people and data first; preserve evidence before changing production.
- Use UTC for timelines.
- Separate confirmed facts, hypotheses, and unknowns.
- Be blameless: examine the conditions and safeguards that shaped actions rather than attributing fault to a person.
- Record impact, detection, response, contributing factors, a Five Whys analysis, what went well, and follow-up actions.
- Give actions an owner, priority, status, and verification condition.
- Do not mark an incident resolved until service is restored and the restoration has been verified in production.
- Do not mark an incident closed while an agreed action remains proposed or in progress; an intentionally deferred action must record the decision and rationale.
- Production mutations require explicit operator approval and an auditable runbook.

## Incident index

| Date | Incident | Impact | Status | Open follow-ups |
| --- | --- | --- | --- | ---: |
| 2026-09-15 | [Database restarted during release-command invariant checks](2026-09-15-release-invariant-database-restarts.md) | Database process later remained unavailable inside a started machine; at least one Internal Server Error observed; three deployments safely blocked; no data loss observed. | Resolved 2026-09-24 — database restarted, health and iteration 064 deployment verified; follow-ups open | 4 |
| 2026-09-14 | [Custom-group creation rejected for legacy clubs](2026-09-14-custom-group-creation-forbidden.md) | Projected Admins in 2 of 5 populated production clubs could not create custom groups; no data loss or privacy breach observed. | Resolved 2026-09-15 — repaired and customer path verified; follow-ups open | 3 |
