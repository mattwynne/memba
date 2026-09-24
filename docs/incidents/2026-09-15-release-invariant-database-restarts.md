# Incident: database restarted during release-command invariant checks

Date: 2026-09-15

Status: Resolved 2026-09-24 — database service restored and iteration 064 deployed; 4 follow-up actions remain open

## Summary

Two attempts to deploy the permanent Admin-history invariant gate failed while Fly's temporary release-command application was running the new read-only invariant. In both attempts, production PostgreSQL connections closed and the single database node entered automatic recovery. The second recovery lasted approximately 36 seconds.

The deployment gate failed closed: releases `v288` and `v289` did not replace the running application. We removed the invariant from the temporary release-command process and retained blocking pre-deploy and post-deploy checks against the running app. Release `v290` then deployed successfully with both external checks passing.

The exact PostgreSQL crash trigger is not confirmed. The timing repeated at the same release step, and removing that step stopped the failure, so the release-machine connection/query load remains a hypothesis rather than a proven root cause.

On September 23 and 24, later deployment attempts established that PostgreSQL was no longer accepting connections even though the Fly machine remained in the `started` state. On September 24, a user also observed an Internal Server Error on a database-backed production path. An operator-approved restart recovered PostgreSQL, whose startup log reported that the database had been interrupted and was last known up at `2026-09-15 04:39:38 UTC`. This explicitly corrects the earlier understanding that the database had remained recovered after the short September 15 windows. We cannot establish from retained evidence whether unavailability was continuous from that timestamp or precisely how many requests were affected.

Production is currently healthy. PostgreSQL recovered its WAL, all three database checks pass, the source-backed Admin invariant passed before and after deployment, iteration 064 deployed as Fly release `v293`, and `https://memba.io` reports commit `f14afcf90e739a45e682dfdef876c852662c9e20`.

## Impact

- Production database connections failed during two recovery windows.
- Application requests requiring the database may have failed or stalled during those windows; no customer report was received.
- Releases `v288` and `v289` failed before updating the production app, leaving the already healthy `v287` app release in place.
- PostgreSQL replayed WAL and returned healthy after each restart.
- A database-backed production path returned an Internal Server Error before recovery on September 24.
- Database-dependent requests could not complete while PostgreSQL was unavailable. The public root path can return `200` without proving database availability, so request scope and customer impact cannot be reconstructed from retained evidence.
- Deployment of iteration 064 was delayed by three failed pre-deploy checks across September 23 and 24. The gate failed closed and no unsafe release occurred.
- No data loss or corruption has been observed. PostgreSQL completed WAL recovery, and the repaired Admin invariant returned zero violations before and after release `v293`.

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

Follow-up events:

| Time | Event |
| --- | --- |
| 2026-09-23 16:04 | Continuous Delivery run `35886130219` began. Its pre-deploy invariant later failed because the running app could not obtain a database connection. Deployment did not begin. |
| 2026-09-23 20:19 | Run `35915140213` repeated the same fail-closed result. Deployment did not begin. |
| 2026-09-24 07:19 | Run `35969030433`, attempt 1, used the new isolated one-connection gate and failed with the same connection closure. This ruled out contention for the running application's Repo pool as the complete explanation. Deployment did not begin. |
| 2026-09-24 12:59 | Read-only production inspection showed repeated `tcp recv (idle): closed` errors from all application database clients. The `memba-db` machine was `started`, but its `pg` and `role` checks were critical and port 5433 refused connections. A user reported an Internal Server Error. |
| 2026-09-24 13:06 | With explicit operator approval, machine `8e7009f769616d` was restarted. PostgreSQL reported an interrupted database last known up at `2026-09-15 04:39:38 UTC`, performed WAL recovery, and became ready. |
| 2026-09-24 13:06 | All three database checks passed, production returned HTTP 200, and a manual isolated pre-deploy invariant returned zero violations. |
| 2026-09-24 13:06 | Continuous Delivery run `35969030433` was rerun from commit `f14afcf90e739a45e682dfdef876c852662c9e20`. |
| 2026-09-24 13:11 | Pre-deploy and post-deploy invariants passed, Fly release `v293` completed, iteration 064 was live, and the production footer reported the expected commit. |

## What happened

Fly's release command starts a second Memba application instance. That instance starts the endpoint, Repo pool, EventStore pools, notifications, projectors, and backfill services before running release work. Adding the invariant there introduced a repeatable-read query over projections and EventStore tables while both the production app and temporary release app were connected.

On two attempts, production PostgreSQL terminated a server process and entered recovery while this step was active. Application and release-machine logs reported `tcp recv: closed`, connection handshakes timing out, `FATAL 57P03` recovery responses, and unavailable Repo connections. The release gate correctly treated missing evidence as failure.

A manual invariant against the running app and each CI pre-deploy invariant passed quickly. After removing the release-machine check, the same migration/backfill release process and external invariant checks completed successfully.

Later evidence changed the incident understanding. By September 23, the external gate could not connect at all. On September 24, Fly reported the sole database machine as `started`, while its `pg` and `role` checks were critical, the local PostgreSQL port refused connections, and only the VM check passed. PostgreSQL was not listening while the machine's monitoring and replication-manager processes continued running and logging failed connection attempts. Because the machine itself had not exited, its machine-level `restart.policy = always` did not restore PostgreSQL.

The approved machine restart started PostgreSQL, triggered normal WAL recovery, and restored service without manual data changes. Why the PostgreSQL process stopped and did not restart inside the still-running machine remains unknown.

Evidence:

- Failed release-command runs: [34916857181](https://github.com/mattwynne/memba/actions/runs/34916857181) and [34918604051](https://github.com/mattwynne/memba/actions/runs/34918604051).
- Successful gate release: [34920034105](https://github.com/mattwynne/memba/actions/runs/34920034105).
- Retained successful evidence: [artifact 10378625528](https://github.com/mattwynne/memba/actions/runs/34920034105/artifacts/10378625528).
- Fly releases: `v288` and `v289` failed; `v290` completed; recovery release `v293` completed on September 24.
- Later failed deployment runs: [35886130219](https://github.com/mattwynne/memba/actions/runs/35886130219) and [35915140213](https://github.com/mattwynne/memba/actions/runs/35915140213).
- Successful recovery deployment: [35969030433](https://github.com/mattwynne/memba/actions/runs/35969030433), commit `f14afcf90e739a45e682dfdef876c852662c9e20`.
- September 24 database health evidence: machine `8e7009f769616d` was started; `vm` passed; `pg` timed out; and `role` reported port 5433 connection refused. After restart, all three checks passed.

Unknowns:

- What caused the PostgreSQL server process to stop, whether query memory, connection pressure, a PostgreSQL/Fly image defect, or another resource limit contributed, and why the image's process supervision did not restart it.
- Whether database unavailability was continuous from the `last known up` timestamp or began later.
- How many customer requests failed; a user observed at least one Internal Server Error, but no database-backed availability history was retained.

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

### Why the later outage persisted and was detected late

1. **Why did database-dependent production requests fail?**

   PostgreSQL was not accepting connections, although the database Fly machine was still `started`.

2. **Why did machine restart policy not recover PostgreSQL?**

   The machine itself had not exited. Its monitor and replication-manager processes remained alive while PostgreSQL was not listening, so the machine-level `always` restart policy did not activate.

3. **Why did this condition persist until operator intervention?**

   The critical `pg` and `role` checks did not trigger an automated replacement or an operator alert.

4. **Why was customer impact not detected directly?**

   There was no external database-backed availability check or alert. The public root path could still return `200`, and deployment gates only run when a deployment is attempted.

5. **Why did the first failed deployment not immediately identify a database outage?**

   The running-app RPC gate could report only that its Repo pool had no connection. That was initially consistent with pool contention as well as database unavailability. The isolated one-connection implementation ruled out the pool-contention explanation when it failed with the same connection closure.

The causal chain stops here: retained evidence does not establish why the PostgreSQL process originally exited.

### Why detection and containment worked

1. The release check treated every query/connection error as failure rather than silently passing.
2. Fly aborted each deployment before replacing the running app.
3. CI retained invariant output even on failure.
4. Database and app logs distinguished a started VM from an unavailable PostgreSQL process.
5. Explicit mutation approval and a machine restart restored service without bypassing the invariant.
6. The isolated gate then passed before and after deployment, allowing iteration 064 to ship safely.

## Contributing conditions

- The release task starts more application services and database pools than this read-only check needs.
- Production uses one PostgreSQL machine, so a restart has no failover node.
- The database is on `flyio/postgres-flex:17.2 (v0.1.0)` while Fly reports a newer `17.7 (v0.2.1)` image available.
- Initial retries handled transient client errors but could not help while the database process was absent.
- Machine state alone was misleading: Fly reported `started` while two database-specific checks were critical.
- The public root path does not prove database availability.
- Database health failures were neither externally alerted nor automatically remediated.
- The first artifact location was inside the Git checkout, which correctly triggered `bin/deploy`'s dirty-tree protection and added one failed attempt before the database issue appeared.

## Actions

| Type | Priority | Action | Owner | Status | Verification |
| --- | --- | --- | --- | --- | --- |
| Correct | P0 | Remove the invariant from the temporary release-command application while retaining external blocking checks. | Engineering | Completed | `v290` release command and pre/post checks all passed. |
| Correct | P0 | Restart the unavailable database machine, verify recovery, rerun the invariant, and deploy iteration 064 through CI/CD. | Matt + operator | Completed 2026-09-24 | All database checks passed; the manual invariant and CI pre/post checks passed; release `v293` serves commit `f14afcf90e739a45e682dfdef876c852662c9e20`. |
| Detect | P0 | Retain each pre/post attempt as a protected CI artifact and retry bounded transient check failures. | Engineering | Completed | CI artifact exists and failed attempts remain visible. |
| Prevent | P1 | Keep release-command work limited to services actually required by migrations/backfills, and isolate the external Admin gate from the live application Repo pool. | Engineering | Completed 2026-09-24 | Run `35969030433` passed the isolated gate before and after release `v293`; focused shell and Elixir tests cover minimal startup, pool bounds, cleanup, JSON evidence, timeout, and blocking failures. |
| Detect | P0 | Implement the [database-backed production availability monitoring plan](2026-09-15-database-availability-monitoring-plan.md), with independent email and Red Donkey Slack outage/recovery notifications. | Engineering | Planned; deferred by Matt on 2026-09-24 | Application failure tests plus provider test notifications prove that a database failure produces generic `503`, an operator email, and a Red Donkey Slack message while the non-database root may remain healthy. |
| Prevent | P1 | Investigate the PostgreSQL server-process failure using Fly diagnostics/support and available resource history. | Operator | In progress | A supported cause or explicitly bounded set of unknowns is recorded. |
| Prevent | P1 | Plan and explicitly approve upgrading the Fly Postgres image from 17.2/v0.1.0 to the supported current image. | Matt + operator | Proposed; production mutation requires approval of the exact plan | Backup/recovery plan reviewed; upgrade completes with database health, data checks, and the Admin invariant green. |
| Prevent | P1 | Decide whether single-node database risk is acceptable or add a tested failover/recovery mechanism. | Matt + operator | Proposed | The accepted risk or chosen topology is recorded; any implemented recovery path is exercised and timed. |

## Resolution

On September 24, an explicitly approved restart of `memba-db` restored PostgreSQL. Startup completed WAL recovery without a reported corruption error. All `pg`, `role`, and `vm` checks passed; production returned HTTP 200; and the source-backed Admin invariant returned zero violations in a manual check and in CI before and after deployment.

Continuous Delivery run `35969030433` deployed iteration 064 as Fly release `v293`. The production footer reported `f14afcf90e739a45e682dfdef876c852662c9e20`. Service and the affected production state were therefore restored and verified, so the incident is resolved. The server-process cause, detection gap, image upgrade, and single-node recovery decision remain open follow-ups.

## Follow-up — 2026-09-24

The source-backed Admin deployment gate has been changed in source so it no longer sends an RPC into the running application's `Memba.Repo` pool. Each shell attempt now invokes release `eval`, which creates a short-lived BEAM, loads only SSL/Postgrex/Ecto SQL support, starts a dedicated Repo with `pool_size: 1` and `pool_count: 1`, runs the existing repeatable-read/read-only invariant, emits JSON evidence, and stops the Repo. The shell retains bounded retries and now places an explicit timeout around every eval attempt.

Source and contract-test evidence is in `bin/verify-production-admin-invariant`, `Memba.ReleaseAdminInvariant`, `Memba.ReleaseAdminInvariantRepo`, and their focused shell/Elixir tests. Infrastructure/query failures and invariant violations both block but have distinct diagnostics.

Production verification completed in Continuous Delivery run `35969030433`: the isolated gate passed before and after release `v293`. This closes the gate-isolation action.

The same investigation established that the gate failures were accurately reporting a database outage rather than merely contention in the application Repo pool. With explicit approval, machine `8e7009f769616d` was restarted at 13:06 UTC. PostgreSQL performed WAL recovery and all database checks passed. No manual data mutation was performed.

## Follow-up — availability-monitoring decision, 2026-09-24

Matt approved the design direction but deferred implementation. The agreed design is an external monitor checking a bounded database-backed `/health/ready` endpoint, with both email and Red Donkey Slack outage and recovery notifications. It should start on a free plan if current provider features meet the requirements; any paid subscription requires separate approval. The endpoint, monitor policy, notification content, security constraints, response runbook, verification approach, and implementation checklist are recorded in the [availability monitoring plan](2026-09-15-database-availability-monitoring-plan.md).
