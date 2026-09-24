# Database-backed production availability monitoring plan

Status: Planned — not yet implemented

Related incident: [Database restarted during release-command invariant checks](2026-09-15-release-invariant-database-restarts.md)

## Decision

Memba will use an external HTTP uptime monitor to check a database-backed readiness endpoint. An outage and its recovery must notify both:

- an operator email address; and
- a dedicated alert channel in the new **Red Donkey** Slack workspace.

The initial setup should use a free plan if one currently supports one production monitor plus email and Slack notifications. No paid plan should be started without Matt's explicit approval.

The monitoring provider, destination email address, and Slack channel remain setup-time decisions. The proposed Slack channel is `#memba-alerts`; create or choose the final channel before enabling notifications.

## Why an external monitor

The September 2026 incident demonstrated that these signals are insufficient by themselves:

- a Fly machine can remain `started` while PostgreSQL is not listening;
- the public root page can return HTTP `200` without using the database;
- Fly database checks can remain critical without notifying an operator; and
- a deployment gate only runs when a deployment is attempted.

The monitor must therefore run outside Memba and Fly's database machine. Its notification path must not depend on Memba, PostgreSQL, or Memba's email-delivery workers.

## Readiness endpoint

Add a small controller endpoint:

```text
GET /health/ready
```

Expected behaviour:

| Condition | Response |
| --- | --- |
| The Phoenix endpoint can check out a Repo connection and execute `SELECT 1` within the bounded deadline | `200` with `{"status":"ok"}` |
| Connection checkout, network communication, or the query fails or times out | `503` with `{"status":"unavailable"}` |

Requirements:

- Use the production application Repo so the check covers the same app-to-database path used by customers.
- Bound checkout and query execution so the endpoint returns within a few seconds rather than joining a long Repo queue.
- Do not start another application, Repo, EventStore, projector, or dispatcher.
- Return only generic status; never return connection strings, SQL errors, hostnames, stack traces, or other diagnostics.
- Add `Cache-Control: no-store` so a proxy cannot hide a failure with a cached success.
- Log failures with enough classification to distinguish checkout timeout, connection failure, query timeout, and unexpected application failure, without logging credentials.
- Keep the check read-only and inexpensive. One `SELECT 1` every few minutes is sufficient.
- The endpoint may be public because its response contains no sensitive state. Do not place a Slack webhook or monitoring token in its URL.

This endpoint detects customer-relevant database unavailability and severe Repo exhaustion. It intentionally does not attempt to identify the root cause.

## External monitor configuration

At implementation time, compare the current free plans of services such as Better Stack and UptimeRobot. Select a provider that supports the required email and Slack destinations, or stop and obtain approval before accepting a charge.

Configure one production monitor:

| Setting | Planned value |
| --- | --- |
| Name | `Memba production database readiness` |
| URL | `https://memba.io/health/ready` |
| Method | `GET` |
| Expected status | `200` |
| Interval | Five minutes or faster if included in the free plan |
| Request timeout | Shorter than the interval; approximately 10 seconds |
| Failure confirmation | Two consecutive failures or the provider's equivalent multi-location confirmation |
| Recovery confirmation | A successful check after an alert, preferably two if configurable |
| Email destination | Matt's chosen operational email address |
| Slack destination | Red Donkey workspace, proposed `#memba-alerts` |

A five-minute free-plan interval is acceptable initially. It is materially better than discovering an outage through a customer or a later deployment. A faster interval or SMS/telephone escalation can be considered later if production needs justify a paid plan.

## Notification behaviour

### Outage email

Suggested subject:

```text
[Memba production] Database readiness check failed
```

The notification should include:

- detection time in UTC;
- monitor name and failing URL;
- last successful check, when available;
- number or duration of failures;
- a link to the provider incident; and
- a link to this repository's incident response instructions.

### Slack outage message

Send the same incident to the selected Red Donkey Slack channel. Suggested leading text:

```text
🔴 Memba production database readiness is DOWN
```

Include UTC time, failure duration, monitor link, and the first read-only diagnostic commands. Do not include database credentials, environment values, or full production logs.

Do not use `@channel` initially. Add an explicit mention or stronger escalation only if ordinary channel notifications prove too easy to miss.

### Recovery notifications

Both email and Slack must receive recovery notifications:

```text
🟢 Memba production database readiness has RECOVERED
```

Include outage start, recovery time, total duration, and a reminder to inspect whether customer or data follow-up is required. Recovery does not by itself establish root cause or close an incident.

## Slack security

Prefer the monitoring provider's native Slack integration. Authorize only the Red Donkey workspace and selected alert channel where the provider permits that scope.

If a Slack incoming webhook is required:

- create it specifically for production monitoring;
- store it only in the monitoring provider's secret configuration;
- never commit it to this repository or expose it in endpoint configuration;
- do not print it in CI logs; and
- revoke and replace it if disclosed.

## Initial response runbook

When an alert arrives:

1. Confirm whether a database-backed customer path fails. Do not rely only on `/`.
2. Inspect production read-only:

   ```sh
   flyctl status --app memba
   flyctl status --app memba-db
   flyctl checks list --app memba-db
   flyctl logs --app memba-db --no-tail
   flyctl logs --app memba --no-tail
   ```

3. Distinguish these states:
   - app unavailable;
   - app running but Repo checkout exhausted;
   - database machine stopped;
   - database machine started but `pg` or `role` critical;
   - PostgreSQL recovering; or
   - network/DNS failure.
4. Preserve relevant UTC timestamps, machine IDs, releases, check output, and bounded logs.
5. Treat production inspection as read-only by default.
6. Obtain explicit approval before restarting a machine, changing scale, upgrading an image, modifying secrets, or changing data.
7. After approved recovery, verify:
   - all database checks pass;
   - `/health/ready` returns `200`;
   - a representative database-backed customer path works;
   - the external monitor reports recovery; and
   - any required invariant or post-recovery data check passes.
8. Create or update the matching incident record. Do not mark it resolved from the recovery notification alone.

## Verification without causing a production outage

Implementation is complete only when all of the following are demonstrated:

1. Controller tests prove `200` on a successful database check.
2. Tests prove a database error or bounded timeout returns generic `503` without leaking diagnostics.
3. Tests prove the response is not cacheable.
4. The production endpoint returns `200` after deployment.
5. The provider's notification-test facility sends a test email to the chosen address.
6. The provider's notification-test facility posts a test message in the selected Red Donkey Slack channel.
7. The live monitor records a successful check and its recovery path is configured.

Do not stop production PostgreSQL merely to test alerting. Provider notification tests plus controlled application-level failure tests are the initial equivalent. A future recovery drill should use an explicitly approved safe method and plan.

## Cost and service decision

No new paid service is required by this plan. Start with a free external monitor if its current plan includes:

- at least one HTTP monitor;
- email alerts;
- Slack alerts or a safe Slack integration; and
- recovery notifications.

Free-plan features and intervals can change, so verify them at implementation time rather than treating this document as a pricing promise. If no free provider meets the requirements, present the smallest suitable paid option, price, cancellation terms, and alternatives for approval before subscribing.

A scheduled GitHub Actions check is an available no-new-provider fallback, but it is not preferred: scheduled runs can be delayed, failure emails depend on personal GitHub settings, and deduplicated outage/recovery notifications are awkward.

## Deferred scope

This plan does not yet add:

- SMS, telephone, or pager escalation;
- a general exception tracker such as AppSignal, Sentry, or Honeybadger;
- metrics retention or dashboards;
- automatic database restarts;
- Fly Postgres image upgrades;
- a second database node or tested failover; or
- automated incident creation.

Those are separate decisions. This monitor's first job is to ensure that a customer-relevant database outage produces a prompt independent email and Red Donkey Slack notification.

## Implementation checklist

- [ ] Choose the provider after verifying current free-plan capabilities.
- [ ] Confirm the operational email destination.
- [ ] Create or select the Red Donkey Slack alert channel.
- [ ] Implement and test `/health/ready`.
- [ ] Deploy through CI/CD.
- [ ] Configure the external monitor.
- [ ] Configure email outage and recovery notifications.
- [ ] Configure Red Donkey Slack outage and recovery notifications.
- [ ] Send test notifications to both destinations.
- [ ] Verify the live monitor sees production as healthy.
- [ ] Update the related incident action with provider, destinations, evidence, and completion date.
