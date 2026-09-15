# Incident: database restarted during release-command invariant checks

Date: 2026-09-15

Status: Mitigated — unsafe gate placement removed; infrastructure cause remains under investigation

## Summary

Two attempts to deploy the permanent Admin-history invariant gate failed while Fly's temporary release-command application was running the new read-only invariant. In both attempts, production PostgreSQL connections closed and the single database node entered automatic recovery. The second recovery lasted approximately 36 seconds.

The deployment gate failed closed: releases `v288` and `v289` did not replace the running application. We removed the invariant from the temporary release-command process and retained blocking pre-deploy and post-deploy checks against the running app. Release `v290` then deployed successfully with both external checks passing.

The exact PostgreSQL crash trigger is not confirmed. The timing repeated at the same release step, and removing that step stopped the failure, so the release-machine connection/query load is the leading hypothesis rather than a proven root cause.

## Impact

- Production database connections failed during two recovery windows.
- Application requests requiring the database may have failed or stalled during those windows; no customer report was received.
- Releases `v288` and `v289` failed before updating the production app, leaving the already healthy `v287` app release in place.
- PostgreSQL replayed WAL and returned healthy after each restart.
- No data loss or corruption has been observed. The repaired Admin invariant and the later `v290` pre/post checks both returned zero violations.

## Timeline

All times UTC on 2026-09-15.

| Time | Event |
| --- | --- |
| 01:19 | An external pre-deploy invariant passed. Deployment then stopped safely because its retained artifact had made the Git checkout dirty; no release command ran. |
| 01:41 | A corrected deployment passed preflight and started the `v288` release-command machine. |
| 01:42 | The release-command invariant lost its database connection. PostgreSQL entered automatic recovery, the release command exited non-zero, and deployment was aborted. |
| 02:03 | A second deployment passed preflight and started the `v289` release-command machine with longer query timeouts and bounded execution retries. |
| 02:04 | PostgreSQL again entered recovery while that invariant was running. All retries failed; deployment was aborted. |
| 02:05 | PostgreSQL reported ready and repmgr reconnected after approximately 36 seconds. |
| 02:08 | The invariant was removed from the temporary release-command application. External CI pre/post checks remained blocking. |
| 02:24 | The `v290` pre-deploy invariant passed with both violation counts zero. |
| 02:29 | The ordinary release command completed without the invariant. `v290` started successfully, and the post-deploy invariant passed. |

## What happened

Fly's release command starts a second Memba application instance. That instance starts the endpoint, Repo pool, EventStore pools, notifications, projectors, and backfill services before running release work. Adding the invariant there introduced a repeatable-read query over projections and EventStore tables while both the production app and temporary release app were connected.

On two attempts, production PostgreSQL terminated a server process and entered recovery while this step was active. Application and release-machine logs reported `tcp recv: closed`, connection handshakes timing out, `FATAL 57P03` recovery responses, and unavailable Repo connections. The release gate correctly treated missing evidence as failure.

A manual invariant against the running app and each CI pre-deploy invariant passed quickly. After removing the release-machine check, the same migration/backfill release process and external invariant checks completed successfully.

Evidence:

- Failed release-command runs: [34916857181](https://github.com/mattwynne/memba/actions/runs/34916857181) and [34918604051](https://github.com/mattwynne/memba/actions/runs/34918604051).
- Successful gate release: [34920034105](https://github.com/mattwynne/memba/actions/runs/34920034105).
- Retained successful evidence: [artifact 10378625528](https://github.com/mattwynne/memba/actions/runs/34920034105/artifacts/10378625528).
- Fly releases: `v288` and `v289` failed; `v290` completed.

Unknowns:

- Which PostgreSQL server process failed first and why.
- Whether query memory, connection pressure, a PostgreSQL/Fly image defect, or another resource limit triggered the restart.
- Whether any customer request failed during the recovery windows.

## Five Whys

### Why it happened

1. **Why did the two deployments fail?**

   Their temporary release-command processes could not complete the invariant and exited non-zero.

2. **Why could the invariant not complete?**

   Its database connection closed while the production PostgreSQL node was restarting and recovering.

3. **Why did PostgreSQL restart?**

   The exact server-process failure is unknown. Both restarts occurred while a second full application instance was running the invariant; removing that placement stopped the recurrence.

4. **Why was the invariant running inside a second full application instance?**

   We initially sought defense in depth by checking before backfill work inside `Memba.Release.migrate/0`, whose existing pattern starts the complete application.

5. **Why was that production-resource interaction not caught earlier?**

   Local and CI tests verify sequencing and SQL semantics, but they do not reproduce the capacity, network, Fly release-machine, and single-node database behavior of production.

### Why detection and containment worked

1. The release check treated every query/connection error as failure rather than silently passing.
2. Fly aborted each deployment before replacing the healthy running app.
3. CI retained invariant output even on failure.
4. Database and app logs exposed recovery rather than only a generic deploy error.
5. Removing the release-machine check while keeping external gates allowed a safe deployment without weakening the production invariant.

## Contributing conditions

- The release task starts more application services and database pools than this read-only check needs.
- Production uses one PostgreSQL machine, so a restart has no failover node.
- The database is on `flyio/postgres-flex:17.2 (v0.1.0)` while Fly reports a newer `17.7 (v0.2.1)` image available.
- Initial retries handled transient client errors but could not help while the database itself remained in recovery.
- The first artifact location was inside the Git checkout, which correctly triggered `bin/deploy`'s dirty-tree protection and added one failed attempt before the database issue appeared.

## Actions

| Type | Priority | Action | Owner | Status | Verification |
| --- | --- | --- | --- | --- | --- |
| Correct | P0 | Remove the invariant from the temporary release-command application while retaining external blocking checks. | Engineering | Completed | `v290` release command and pre/post checks all passed. |
| Detect | P0 | Retain each pre/post attempt as a protected CI artifact and retry bounded transient check failures. | Engineering | Completed | CI artifact exists and failed attempts remain visible. |
| Prevent | P1 | Keep release-command work limited to services actually required by migrations/backfills. | Engineering | Proposed | A release-task design shows which pools/processes can be omitted and passes deployment tests. |
| Prevent | P1 | Investigate the PostgreSQL server-process failure using Fly diagnostics/support and resource history. | Operator | Proposed | A supported cause or bounded set of causes is recorded. |
| Prevent | P1 | Plan and explicitly approve upgrading the Fly Postgres image from 17.2/v0.1.0 to the supported current image. | Matt + operator | Proposed | Backup/recovery plan reviewed; upgrade completes with health and invariant checks green. |
| Detect | P2 | Add database restart/recovery alerting. | Engineering | Proposed | A controlled signal produces an operator notification. |

## Resolution

Customer-facing database availability recovered automatically after each restart. The risky release-machine gate placement was removed, and release `v290` deployed successfully with blocking pre-deploy and post-deploy invariant checks and retained evidence.

This incident remains `Mitigated`, not `Resolved`, until the database-process failure is better understood or an approved infrastructure countermeasure is completed.
