# Incident: custom-group creation rejected for legacy clubs

Date: 2026-09-14

Status: Resolved — production repaired, permanent deployment gate active, and customer path verified; 3 follow-up actions remain open

Resolved: 2026-09-15 02:49 UTC

Current production state: All populated clubs have complete source-backed Admin state. The intended `Parents` group was created successfully in `wynne-family`.

Incident release: Fly release `v283`, deployed at 2026-09-14 17:53 UTC from Git commit `03978b3a4d2d6d32966b33a36d92fe8ef75f0f7b`

Resolution release: Fly release `v290`, deployed at 2026-09-15 02:29 UTC from Git commit `cf39b4582368157934d7ec703bca69a4b7787074`

Related work:

- [Completed repair runbook](2026-09-14-custom-group-creation-repair-runbook.md)
- [Projection-only migration compatibility audit](2026-09-14-projection-only-migration-audit.md)
- [Follow-up incident: database restarted during release-command invariant checks](2026-09-15-release-invariant-database-restarts.md)
- [Iteration 027: Membership Administrator role foundation](../iterations/027-membership-administrator-role/plan.md)
- [Iteration 059: Populated clubs always have an Admin](../iterations/059-populated-clubs-always-have-an-admin/plan.md)
- [Iteration 059 production cutover check](../iterations/059-populated-clubs-always-have-an-admin/cutover-check.md)
- [Iteration 062: Admins create usable custom groups](../iterations/062-create-custom-groups/plan.md)
- [ADR 0017: Treat release state as a first-class production artifact](../adr/0017-treat-release-state-as-a-first-class-production-artifact.md)
- [CQRS/event-sourcing drift problem](../problems/2026-06-17-cqrs-event-sourcing-design-drift.md)

## Summary

Shortly after iteration 062 reached production, an active member shown as an Admin by the `wynne-family` read model tried twice to create a custom group named `Parents`. The New group page and live preview were available, but submission terminated the LiveView with `MembaWeb.ForbiddenError`.

The page and preview authorize against the `membership_member_permissions` read model. The authoritative create command authorizes against state reconstructed from the Club event stream. For two older production clubs, those sources disagree: the read model says an active member has `club.manage_members`, while the Club stream contains no Admin role-assignment fact. The aggregate therefore reconstructs zero active Admins and correctly rejects the command according to the history it owns.

This was a production-history compatibility failure, not expected iteration-062 behaviour. Iteration 062 explicitly promises that an active club Admin can create a custom group. We restored the missing source facts through an approved append-only repair, verified the invariant, installed a blocking deployment gate, and confirmed the original customer path.

## Impact

- Admin custom-group creation was unavailable to the projected Admins in 2 of 5 populated production clubs: `lean` and `wynne-family`.
- The two failed attempts appended no partial group, membership, or email-address facts.
- The other 3 populated clubs had event-backed active Admin state and were not affected by this mismatch.
- No data loss, unauthorized access, email delivery, or privacy breach was observed.
- The user experience was poor: a form that appeared authorized crashed into reconnection/error behaviour rather than explaining that creation failed.
- There was no automated alert. Detection depended on a user noticing the failed action and asking for log inspection.

## Detection

Matt reported that adding a group appeared to fail. Read-only Fly log inspection showed two exceptions with the submitted group name:

```text
2026-09-14T18:20:24Z [error] GenServer terminating
** (MembaWeb.ForbiddenError) Forbidden
    lib/memba_web/live/member_group_live/new.ex:399
Last message: ... event: "create_group" ... "group%5Bname%5D=Parents"

2026-09-14T18:20:43Z [error] GenServer terminating
** (MembaWeb.ForbiddenError) Forbidden
    lib/memba_web/live/member_group_live/new.ex:399
Last message: ... event: "create_group" ... "group%5Bname%5D=Parents"
```

The logs identified the symptom but did not include structured club, actor, aggregate-state, or command-result context. Diagnosis required manual production queries and source-history inspection.

## Timeline

All times are UTC on 2026-09-14 unless stated otherwise.

| Time | Event |
| --- | --- |
| 2026-06-08 | Iteration 027 introduced a migration that populated role, role-assignment, and member-permission projection tables for existing clubs. It did not append equivalent domain facts to Club streams. |
| 2026-09-12 | Iteration 059 was published. Its plan required a one-time, read-only production cutover check immediately before and after deployment. The check was designed to block deployment when a populated club lacked a source-backed active Admin. |
| 17:53 | Fly release `v283` deployed iteration 062 commit `03978b3a4`; the release migration completed and the app started normally. |
| 18:20:24 | First `Parents` submission was rejected as unauthorized; the LiveView terminated with `ForbiddenError`. |
| 18:20:43 | A retry failed in the same way. |
| approx. 18:25 | Matt reported the production failure and requested log investigation. |
| approx. 18:28 | Read-only inspection confirmed that `wynne-family` had one projected Admin but zero aggregate active Admins and no aggregate role assignments. |
| approx. 18:39 | A production-wide read-only comparison found the same mismatch in 2 of 5 populated clubs. No custom-group events from either failed attempt were found. |
| 18:40 | The documented iteration-059 cutover transaction was run read-only against production. Membership-history check 1 returned zero violations; source-backed Admin check 2 returned two violations. |
| 2026-09-15 00:18 | Release `v287` dry-run found exactly two repairable clubs, six missing source facts, three already-reconciled clubs, and zero manual-review candidates. |
| 2026-09-15 00:34 | Matt approved the exact two-club allow-list. Operation `incident-2026-09-14-admin-history-01` appended six canonical events with approval metadata. |
| 2026-09-15 00:34 | Scoped dry-run returned zero planned events; the full read-only invariant returned zero violations. Both repaired grants remained at count 1. |
| 2026-09-15 02:29 | Release `v290` deployed the permanent CI/CD gate. Pre-deploy and post-deploy checks passed and evidence was retained in [CI artifact 10378625528](https://github.com/mattwynne/memba/actions/runs/34920034105/artifacts/10378625528). |
| 2026-09-15 02:49 | Matt created `Parents` successfully. Read-only verification found one group, slug `parents`, its creator membership, and exactly three atomic group-creation events with no related error log. |
| 2026-09-15 03:25 | Release `v291` deployed the late safety-review extension that checks every projected deterministic Admin assignment. Its post-deploy report returned zero violations for all three invariant checks. |

## Technical analysis

Confirmed facts in this section come from the linked source, tests, docs, captured CI evidence, and production inspection recorded above. Hypotheses and unknowns are labelled explicitly. Production mutations were limited to the explicitly approved append-only repair described in the resolution.

Evidence checked for this review:

- The LiveView, Membership API, authorization query, and Club aggregate confirm that mount/preview use projected permissions while submit checks event-reconstructed Admin state.
- Migration `20260607233402_backfill_membership_administrator_roles.exs` writes the legacy Admin state directly to projection tables.
- UI access/preview tests can grant projected permission directly, while submit-path tests create event-backed Admin history.
- `bin/deploy`, the continuous-delivery workflow, and `Memba.Release` do not run the iteration-059 Admin-source cutover SQL.

### The two authorization paths disagree

`MembaWeb.MemberGroupLive.New` uses projection-backed authorization when mounting and previewing:

- `group_context/3` calls `Authorization.authorize_manage_members/2`;
- `preview_custom_group/1` calls the same function; and
- `Authorization` reads `membership_member_permissions`.

Submission calls `Membership.create_custom_group/2`. `Memba.Membership.Club.execute/2` then calls `active_admin_membership_id/2`, which uses `active_admin_membership_ids` reconstructed from Club-stream membership and role-assignment facts.

For the affected club, the confirmed production state was:

- 3 active memberships in both projection and aggregate state;
- 1 projected `club.manage_members` grant;
- 0 aggregate active Admin membership IDs;
- 0 aggregate roles, role permissions, or role assignments; and
- no `ClubRoleAssignedToMember` or historic `MemberRoleAssigned` fact in that Club stream.

The projection let the user enter and validate the form. The aggregate rejected the write with `{:error, :unauthorized}`. The LiveView deliberately translated that result into `ForbiddenError`, which made the failure appear as a crash.

### How the state diverged

Migration `20260607233402_backfill_membership_administrator_roles.exs` inserted deterministic Admin roles, permissions, assignments, and flattened permission grants directly into projection tables for clubs that already existed. This made the then-current read-side authorization work, but it did not create corresponding event history.

Later iterations moved membership and Admin invariants into the Club aggregate. Newer clubs receive source facts through commands and reconstruct correctly. Older clubs can still look valid in projections while the aggregate has no role facts to replay.

### Blast radius

A read-only production-wide aggregate/projection comparison produced:

| Club | Active members | Projected Admins | Aggregate active Admins | Affected |
| --- | ---: | ---: | ---: | --- |
| `fish` | 1 | 1 | 1 | No |
| `lean` | 2 | 1 | 0 | Yes |
| `nclt` | 1 | 1 | 1 | No |
| `test` | 1 | 1 | 1 | No |
| `wynne-family` | 3 | 1 | 0 | Yes |

The exact iteration-059 cutover SQL independently returned `violation_count = 2` for its source-backed Admin check.

### Why the planned safeguard did not protect production

The iteration-059 plan correctly anticipated this class of failure and supplied a query that detects it exactly. The check remained a manual procedure in a Markdown file. It was not connected to `bin/deploy`, the CI deployment job, the release command, or a workflow gate that required captured evidence.

Session-history inspection found no execution of the cutover command before or after iteration 059 was published. The delivery session moved from publishing iteration 059 directly into code review and iteration 060. No separate private operations-log evidence was found in the repository or the searched local notes. Absence of captured evidence does not prove that nobody ran a similar check elsewhere, but production's current result proves that the required zero-violation condition was not established and retained.

### Repair hazard discovered during diagnosis

A naive repair must not simply dispatch the existing define-role, grant-permission, and assign-role commands in production.

The projection rows already exist. In the current projector:

- projecting `ClubRolePermissionGranted` increments permissions for every existing active assignment; and
- projecting `ClubRoleAssignedToMember` increments the member permission again.

For a legacy projected grant at `grant_count = 1`, a naive three-command repair could over-count the permission instead of remaining at one. Before repair, the projector was changed to derive the exact count from distinct active normalized role grants. The production repair then left both affected grants at 1. Directly editing the projection alone would not have repaired the authoritative history.

### Remaining unknowns

- The production mismatch fits the iteration-027 projection backfill and observed stream/projection shape, but the exact original production migration timestamp was not reconstructed.
- We found no captured iteration-059 cutover execution in the searched session history, repository, or local notes. We cannot prove that no similar check ran elsewhere.
- The separate audit still needs a focused compatibility proof for historic bare-UUID event identities.

## Five Whys

### Failure chain

1. **Why could the Admin not create `Parents`?**

   The authoritative Club aggregate returned `:unauthorized` because it reconstructed no active Admin membership for the actor.

2. **Why did the aggregate reconstruct no Admin while the UI showed Admin capability?**

   The UI used projection-backed permission data, while the aggregate used Club-stream facts; those sources disagreed for the legacy club.

3. **Why did those sources disagree?**

   Iteration 027 backfilled role and permission projection tables directly for existing clubs without appending equivalent event-sourced facts.

4. **Why was the historical gap still present when aggregate-owned custom-group authorization shipped?**

   Iteration 059 identified the compatibility requirement but deliberately left production mutation manual. Its one-time cutover check was documented rather than enforced, and no captured successful execution or repair accompanied deployment.

5. **Why could a required production condition remain a manual, uncaptured step?**

   Our delivery system treats code, tests, and migrations as automated gates but still treats some live production invariants as prose handoffs. Despite ADR 0017, the workflow has no general mechanism to require, retain, and verify production-state evidence before a history-dependent feature is declared live.

### Escape and late-detection chain

1. Projection-only UI fixtures covered access and preview, but submit-path tests used event-backed Admin history.
2. Replay tests covered historical events when those events exist; they did not model a projection-only migration followed by an aggregate-authorized command.
3. Iteration 062 therefore did not test submission against the production-history shape created by iteration 027.
4. Deployment health was based on successful migration, app boot, and test status; it did not exercise or assert aggregate/read-model authorization parity for existing clubs.
5. With no exception alerting or post-deploy changed-path check, the first production user action became the monitoring system.

## Root cause and contributing conditions

### Root cause

Legacy Admin authority was written only to read-model projections, while later write-side authorization requires the same authority to exist as reconstructible Club-stream facts.

### Systemic root cause

A known live-data compatibility condition was expressed as a manual, one-time cutover instruction without an enforced gate or durable evidence handoff.

### Contributing conditions

- Different stages of one UI flow used different authority sources.
- Test data represented current creation paths rather than production history.
- The cutover check and its stop condition were correct but operationally optional.
- The implementation review validated repository state, not live production state.
- Unauthorized submit was raised as an exception, making an invariant mismatch look like an ordinary forbidden action and terminating the LiveView.
- Logs lacked structured context needed to distinguish a real permissions denial from projection/write-model drift.
- There is no automated exception tracking or alerting for this production path.

## What went well

- The aggregate failed closed: it did not create a group or expose private data on ambiguous authority.
- Group creation is atomic, so no orphan group, slug, or creator membership was left behind.
- The logs preserved the exact exception, handler, event name, timestamp, and submitted group name.
- The existing iteration-059 SQL check diagnosed the production invariant precisely.
- Read-only Fly and database access allowed the blast radius to be established without mutating evidence.
- The failure was noticed within about half an hour of the new release.

## What could be improved

- Production-state prerequisites must be executable gates, not only prose.
- Delivery evidence must include the output of required pre/post-deploy checks.
- Tests need representative long-lived production histories when features change aggregate ownership or consistency boundaries.
- Equivalent permission checks within one flow should not disagree silently.
- Expected authorization denial and impossible state divergence need distinct handling and observability.
- Production exceptions need proactive alerting.

## Where we were fortunate

- No partial data was written.
- No privacy or authorization boundary was weakened to make the feature appear to work.
- Only two small production clubs have the legacy mismatch.
- The intended `Parents` group can be retried after repair without reconciling a partial creation.

## Actions

Production mutations below were performed only after Matt approved the exact repair scope and expected event count.

| Type | Priority | Action | Owner | Status | Verification |
| --- | --- | --- | --- | --- | --- |
| Correct | P0 | Keep iteration 063 planning and implementation isolated in its branch/worktree; do not merge it to `main` or deploy it to production until the Admin-history invariant is repaired and custom-group creation is verified. | Matt | Completed; hold lifted | Iteration 063 remained off `main` until repair and customer-path verification completed. |
| Correct | P0 | Implement an auditable, retry-safe reconciliation command/runbook for legacy projection-only Admins: include regression and partial-state fixtures, preserve legitimate distinct-role `grant_count` semantics, support dry-run scope, append only missing deterministic event facts, and prove event/projection convergence. | Engineering + operator | Completed and deployed | Dry-run identified exactly `lean` and `wynne-family`; repeated execution is a no-op; grants remained 1; event history and projections now agree. |
| Correct | P0 | Deploy the tested repair support through CI, obtain explicit approval for the production mutation, execute it with captured output, then rerun the iteration-059 check. | Operator | Completed | Check 1 remains zero; check 2 changed from two violations to zero. |
| Correct | P0 | Retry the intended `Parents` creation in `wynne-family` and inspect logs/events/projections. | Matt + operator | Completed | One group, stable slug, and creator membership exist; no exception was logged. |
| Detect | P1 | Turn the source-backed Admin invariant into executable deployment preflight and post-deploy checks with a blocking exit status and retained evidence; include both the populated-club floor and every projected deterministic Admin assignment. | Engineering | Completed and active | Release `v291` passed the membership-source, populated-club floor, and per-projected-Admin-assignment checks; [CI artifact 10379221758](https://github.com/mattwynne/memba/actions/runs/34923684890/artifacts/10379221758) retains the evidence. |
| Detect | P1 | Make custom-group submit handle an unexpected projection/aggregate authority disagreement as an observable technical failure, with structured club/actor/command context, without weakening aggregate authorization. | Engineering | Completed and deployed | Authorization drift now returns a stable technical failure and structured log rather than terminating the LiveView. |
| Prevent | P1 | Add a production-history compatibility test for projection-only migrations followed by aggregate-owned commands, and require this analysis when moving a consistency boundary. | Engineering | Completed | Iteration-027-shaped history fails before repair and passes afterward; the compatibility standard is documented. |
| Prevent | P1 | Audit other direct projection/data migrations and flows that authorize reads from projections but writes from aggregates. | Engineering | Initial audit complete; bare-UUID replay proof in progress | Findings list each mismatch risk, production blast radius, and required repair or proof of safety. |
| Detect | P2 | Add exception tracking/alerting for production LiveView and command failures. | Engineering | In progress | A controlled error generates an operator notification with release and request context. |
| Prevent | P2 | Decide whether a general aggregate/read-model parity framework should supersede the Admin-specific invariant as more write-side decisions move into aggregates. | Engineering | In progress | The decision and rationale are recorded; any accepted implementation is delivered or separately tracked. |
| Prevent | P2 | Add a standard incident template and incident-review skill. Keep incident-action follow-up explicit until mitigations and prevention work are closed. | Engineering | Completed | Template and skill exist in `docs/incidents/` and `.pi/skills/incident-review/`; incident index and action statuses still need to remain current through resolution. |

## Actions not recommended

- Do not change custom-group authorization to trust the projection merely to bypass the aggregate rejection; that would hide the data defect and weaken the consistency boundary.
- Do not edit or delete historical events.
- Do not consider a direct projection update sufficient; projections already report the desired authority.
- Do not dispatch the current role commands naively before proving projector idempotence; doing so can inflate permission grant counts.
- Do not mark the incident resolved after a code deploy alone. Production history must be repaired and verified.

## Open questions

- Should a future general aggregate/read-model parity framework replace this specific permanent invariant?
- What does the remaining legacy bare-UUID replay audit reveal?
- What exception-alerting service is proportionate for the current production scale?

## Resolution

Resolved at 2026-09-15 02:49 UTC.

- Release `v287` supplied idempotent exact-count projection handling, the guarded reconciliation command, production-history tests, invariant tooling, and stable authorization-drift diagnostics.
- Matt approved operation `incident-2026-09-14-admin-history-01` for the exact `lean` and `wynne-family` Club IDs and six expected events.
- The operation appended `ClubRoleDefined`, `ClubRolePermissionGranted`, and `ClubRoleAssignedToMember` to each affected Club stream with operation and approval metadata.
- Post-repair dry-run planned zero events. Both aggregates reconstructed one active Admin and both projected grants remained 1.
- The read-only invariant reported zero membership-source and complete-Admin-source violations.
- Release `v290` activated blocking pre-deploy and post-deploy invariant checks. Both passed, and CI retained their output. A later safety review identified that the club-level floor could let one backed Admin mask another unbacked projected Admin in the same club. Release `v291` added the per-assignment check; its post-deploy report returned zero violations for all three checks.
- Matt then created `Parents` successfully. Projection and aggregate state contain one group with slug `parents`, the intended creator membership, and exactly three atomic creation events. No related production error was logged.

## Follow-up

Remaining non-blocking work:

- Complete the legacy bare-UUID replay compatibility proof recorded in the projection-migration audit.
- Choose and install proportionate production exception alerting.
- Revisit whether a general aggregate/read-model parity framework should supersede the specific Admin invariant as more write-side decisions move into aggregates.
