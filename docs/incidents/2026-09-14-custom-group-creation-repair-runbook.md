# Repair runbook: legacy Admin event history

Incident: [Custom-group creation rejected for legacy clubs](2026-09-14-custom-group-creation-forbidden.md)

Status: Awaiting support-release validation and deployment

This runbook restores canonical Admin facts to legacy Club streams. It does not rewrite events or treat projections as authoritative. The operation is append-only, explicitly scoped, dry-run first, and designed to be safe to retry. Each Club aggregate command is atomic, but a multi-candidate or multi-club run is not globally transactional; it appends one candidate at a time and can be resumed from the retained report.

## Safety rules

- Run the support release through normal CI/CD before using this runbook.
- Capture every command, complete JSON result, UTC time, deployed Git SHA, and Fly release in the private operations log. Do not commit production output.
- Dry-run commands are read-only.
- Do not run the apply command without Matt's explicit approval of its exact club allow-list and expected event count.
- Never edit projection tables or EventStore rows directly.
- Never delete or rewrite repair events after an application rollback.
- Stop if a report contains `manual_review`, `post_apply_missing_candidate`, an unexpected club or membership, an unexpected grant count, a missing Git SHA, or any error.
- The apply runner performs all preflight checks before any dispatch and stops on the first dispatch error; do not expect an all-or-nothing cross-stream transaction.
- If an apply stops after one club, preserve its output and diagnose before retrying. A retry reconciles already-appended facts rather than duplicating them.

## Support release contents

Before deployment, confirm the candidate contains:

- exact-count, idempotent member-permission projection reconciliation;
- the append-only `ReconcileLegacyAdminHistory` aggregate command;
- the guarded `AdminHistoryReconciliation` planner/runner;
- the read-only source-backed Admin invariant command; and
- custom-group authorization-drift diagnostics and stable LiveView failure handling.

Run `./bin/dev check` on the exact committed candidate and retain the successful CI/CD result.

## 1. Verify the deployed support release

Record the intended full Git SHA, then use read-only Fly commands:

```sh
fly status --app memba
fly releases --app memba
```

Confirm the running release reports the intended embedded Git SHA. Stop if release identity is ambiguous.

## 2. Run the reconciliation dry-run

Run the release function with no apply mode or acknowledgement:

```sh
fly ssh console --app memba -C \
  "/app/bin/memba rpc 'Memba.Release.reconcile_legacy_admin_history!()'"
```

Use `rpc`, not `eval`, on a running app machine. `eval` starts another application instance and its HTTP endpoint conflicts with the live process on port 8080.

Expected incident-specific result:

- `mode` is `dry_run`;
- candidate Git SHA matches the deployed support release;
- exactly two clubs are `repairable`;
- the clubs correspond to `lean` and `wynne-family` when IDs are checked against the private operations record;
- each club has exactly one projected Admin candidate;
- each candidate has `current_grant_count = 1` and `expected_grant_count = 1`;
- each candidate is missing, in order:
  - `club_role_defined`;
  - `club_role_permission_granted`;
  - `club_role_assigned_to_member`;
- totals are 2 repairable candidates and 6 planned events;
- there are zero `manual_review` candidates; and
- `events_appended` is zero.

Copy the two exact club IDs from the reviewed report into the private operations log. Do not proceed merely because the totals match.

## 3. Obtain apply approval

Present the captured dry-run report and proposed values:

- explicit two-club allow-list;
- `operation_id`, suggested value `incident-2026-09-14-admin-history-01`;
- `approval_reference`, pointing to Matt's recorded approval; and
- expected append count: six canonical events, three per Club stream.

Obtain explicit approval before running the next command.

## 4. Apply to the approved allow-list

Replace `<CLUB_ID_1>`, `<CLUB_ID_2>`, and `<APPROVAL_REFERENCE>` with the approved values. Keep the acknowledgement exact.

```sh
fly ssh console --app memba -C "/app/bin/memba rpc '
  report = Memba.Membership.AdminHistoryReconciliation.run!(
    mode: :apply,
    club_ids: [\"<CLUB_ID_1>\", \"<CLUB_ID_2>\"],
    operation_id: \"incident-2026-09-14-admin-history-01\",
    approval_reference: \"<APPROVAL_REFERENCE>\",
    acknowledgement: \"YES_APPEND_MISSING_ADMIN_FACTS\"
  )
  IO.puts(Jason.encode!(report))
'"
```

Environment variables set on the short-lived `rpc` client are not inherited by the running BEAM node, so pass the reviewed values directly to the guarded runner.

Expected result:

- `mode` is `apply`;
- 6 events were planned and 6 were appended;
- both candidates finish as `already_reconciled`;
- both current and expected grant counts remain 1; and
- there are no errors, manual-review results, or `post_apply_missing_candidate` results.

Stop and preserve evidence if the observed report differs. Do not compensate by editing data.

## 5. Prove convergence

Rerun the scoped operation in dry-run mode:

```sh
fly ssh console --app memba -C "/app/bin/memba rpc '
  report = Memba.Membership.AdminHistoryReconciliation.run!(
    club_ids: [\"<CLUB_ID_1>\", \"<CLUB_ID_2>\"]
  )
  IO.puts(Jason.encode!(report))
'"
```

Both candidates must report `already_reconciled`, with zero planned/appended events and grant count 1.

Then run the full read-only invariant:

```sh
fly ssh console --app memba -C "/app/bin/memba rpc '
  report = Memba.Membership.SourceBackedAdminInvariant.check!(phase: \"post-repair\")
  IO.puts(Jason.encode!(report))
'"
```

Required result:

- `pass` is `true`;
- `transaction_read_only` is `on`;
- EventStore `data` and `metadata` columns are both `bytea`;
- active-membership source-fact violations are zero; and
- populated-club Admin-source violations are zero.

Use read-only event inspection to confirm that each repaired Club stream contains the three canonical events with:

- the deterministic Admin role ID;
- role key `admin` and name `Admin`;
- permission `club.manage_members`;
- assignment source `legacy_projection_reconciliation`; and
- metadata containing the approved operation ID, approval reference, and repair kind.

Confirm projection grant counts did not increase.

## 6. Verify the customer path

Ask Matt to retry the intended `Parents` creation in `wynne-family`.

Verify read-only that:

- exactly one custom group was created;
- its address slug and creator membership are correct;
- no `ForbiddenError` or authorization-state-mismatch log was emitted; and
- a retry with the same request identity would not create a duplicate.

## 7. Install the permanent gate

The follow-up change now wires `SourceBackedAdminInvariant.check!/1` into the release command and continuous-delivery pre/post-deploy checks, with retained pre/post evidence artifacts and no permanent bypass environment variable. This permanent gate is implemented in source pending deployment; it is not yet complete in production until the gate release itself has deployed and its post-deploy evidence is retained.

## 8. Close the incident

Update the incident record with:

- support and gate release SHAs/Fly releases;
- dry-run, apply, and verification timestamps;
- actual event counts;
- customer-path result;
- action statuses; and
- any remaining prevention work.

Mark the incident `Resolved` only after production state and custom-group creation have both been verified.
