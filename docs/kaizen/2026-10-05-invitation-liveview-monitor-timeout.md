# Problem: Invitation LiveView test intermittently times out waiting for process termination

Date: 2026-10-05

## Context

During sequential `./bin/dev check` gates for the Membership/Messaging facade refactor, independent worktrees repeatedly encountered a failure in `MembaWeb.MemberInvitationLive.NewTest` while their focused tests passed. This note concerns test feedback reliability, not the invitation product behaviour.

## Expected standard

A full gate should reliably distinguish a behavioural regression from a test synchronization failure. The test in `web/test/memba_web/live/member_invitation_live/new_test.exs` should establish that an already-open invitation surface closes with `MembaWeb.ForbiddenError` after projected manage-members permission is revoked.

## What happened

At least two full-gate runs failed at `test/memba_web/live/member_invitation_live/new_test.exs:422`, in `fresh manage-members loss leaves an already-open private surface`. One retained failure (`/tmp/messaging-follow-access-dev-check.log`) says `Assertion failed, no matching message after 100ms` for `assert_receive {:DOWN, ^monitor, :process, _pid, {%MembaWeb.ForbiddenError{}, _stacktrace}}`. A separate person-email gate encountered the same 100 ms assertion timeout; that test passed in isolation, and the full gate passed on rerun. The conversation-follow/access gate also passed on rerun without a change to this test or its product code.

The test directly deletes projected permission rows, monitors `view.pid`, sends a synthetic `:read_model_changed` message to that process, and immediately uses `assert_receive` with its 100 ms default. The evidence does **not** establish whether the LiveView is slow to process the notification, terminates differently in some runs, or fails to terminate; that remains to be investigated.

## Impact

Repeated full-gate reruns and diagnosis delayed otherwise unrelated slices. A short timing failure at the final gate can be mistaken for a product regression, while automatically treating it as a flake risks hiding one. The gates were not reported as passing until a full rerun passed on the exact tested state.

## What allowed it to happen

The assertion uses an implicit, short wall-clock wait for asynchronous LiveView process termination, without a synchronization point or diagnostic showing the LiveView's state when the wait expires. This is a suspected test-feedback weakness, not a proven root cause.

## Observations

- The failing test is an ExUnit LiveView test, distinct from the browser-acceptance projection waits recorded in [the existing acceptance timing note](2026-06-04-acceptance-projection-timing-flake.md).
- The test helper `notify_read_model_change/3` uses `send(view.pid, ...)`; the assertion observes a process-monitor `:DOWN` message rather than checking the rendered UI.
- The subsequent isolated test and full-gate reruns passed without a change targeted at this failure.

## Why this matters

Unreliable final-gate feedback increases validation cost and makes it harder to tell whether a refactor preserved authorization behaviour.

## Open questions

- Does the LiveView process eventually terminate with `ForbiddenError` after the 100 ms window in failing runs?
- Is notification handling, database checkout, or scheduler load involved, or is there a real intermittent authorization defect?
- Which deterministic signal or additional failure diagnostics would establish the expected state without relying only on elapsed time?

## Possible prevention ideas

Investigate the event/monitor ordering and capture useful process or LiveView state at timeout before changing the wait. Prefer a deterministic synchronization assertion if one exists; do not simply increase the timeout or classify future failures as harmless without evidence.

## Investigation

Date: 2026-10-06 (worktree at `a8046f020`). **Assessment: Open.** The target is a reliable, bounded assertion that revocation closes the already-open private surface with `ForbiddenError`, without turning a genuine failure to revoke into a pass. The observed condition is two retained full-gate failures at the same 100 ms monitor assertion, followed by successful reruns; the actual delay and frequency are not measured.

### Evidence and causal path

- In `/tmp/messaging-follow-access-dev-check.log` (seed `144157`, `max_cases: 8`, around lines 113–155) and `/tmp/memba-reply-dev-check.log` (seed `222464`, `max_cases: 8`, around lines 57–99), the LiveView channel logs `ForbiddenError` with **Last message** the synthetic `ClubRoleRemovedFromMember` `:read_model_changed` notification, yet ExUnit reports no matching `:DOWN` in its mailbox after 100 ms. The mailbox shown contains only the Plug response messages, not a mismatched `:DOWN`. The log establishes that the notification reached a channel and the forbidden branch raised in those runs; it does *not* timestamp process exit or prove that the monitored PID subsequently delivered its `:DOWN`. The error line's position before the failure output is not a sub-100-ms timing measurement.
- `web/test/memba_web/live/member_invitation_live/new_test.exs:422-451` deletes the matching projected `MemberPermission` row, monitors `view.pid`, sends a notification directly to that PID, then immediately uses `assert_receive` with ExUnit's implicit 100 ms default. The adjacent membership-loss test uses the same pattern. It does not wait for the server's handling or check the process status after the assertion expires. This bypasses real projection delivery, so these results do not measure projection publication latency.
- `MembaReadModelSource.classify/1` maps that role event to `{:member_permissions, club_id, membership_id, person_id}`; `MemberInvitationQuery.interests/1` includes that exact tuple. `LiveQuery.Binding.handle_notification/2` matches and reloads the query; `MemberInvitationQuery.load/2` resolves fresh authority through `Authorization.authorize_manage_members/2`, returning `:forbidden` when permission is absent. `MemberInvitationLive.New.handle_info/2` raises `ForbiddenError` on that binding error. The logged stack at `new.ex:406` is consistent with this path. It reads several DB-backed projections in the LiveView process, so processing and termination need not fit a 100 ms wall-clock budget under a parallel full gate.
- History: `e16727a58` introduced both this binding/refresh path and the monitor assertion; the current test and LiveView have no later path-specific changes. Nearby `member_group_live/new_test.exs` also uses an implicit 100 ms monitor assertion, so this is a reusable test pattern, not evidence that the invitation query alone is defective. In this worktree `./bin/dev test test/memba_web/live/member_invitation_live/new_test.exs:422` passed once; 20 additional targeted runs with seeds 1–20 all passed (one selected test per run). These runs do not recreate full-gate scheduler/DB contention and do not refute the two retained failures.

**Occurrence versus escape:** the immediate gate failure is a strict 100 ms bound on asynchronous notification processing, DB reread, exception reporting and monitor delivery; that bound is a confirmed test mechanism, but which portion consumed the window remains unknown. Logs strongly weaken the hypothesis of *never* reauthorizing in the two retained runs, while leaving late termination, a different monitored process, or delayed monitor delivery unresolved. A plausible contributing branch is scheduler/DB contention in `max_cases: 8` gates; another is exception/crash-reporting time between the log and the `:DOWN`. Neither is established by these logs. The assertion correctly detects lack of the required `:DOWN` *within the window*, but its failure message provides no PID/state/timing evidence to distinguish slow closure from permanently open access. Gate reruns correct the immediate handoff only when the full gate actually passes; labeling failures as flaky would allow a real defect to escape.

### Options and recommendation (not implemented)

Keep the authorization outcome check: removing this test or accepting any termination would lose the original safeguard. The smallest supported countermeasure is to replace the *implicit* 100 ms with a deliberately bounded, longer monitor wait **while retaining the exact `ForbiddenError` reason**, and on expiry report the monitored PID's status/mailbox or a lightweight trace of notification receipt, query result and exit timing. This removes an unjustified short timing threshold rather than moving the authorization requirement. A larger timeout alone reduces false alarms but obscures a slow path; diagnostics make recurrence actionable. A synchronous `:sys.get_state/1` after send is **not** a safe general substitute here: successful revocation deliberately crashes the LiveView, so a state call can itself exit instead of acknowledging completion. An instrumented one-off run or opt-in diagnostic helper could instead measure send→handler→exit→DOWN boundaries before choosing a specific bound. Optimizing the query, adding arbitrary retries, or changing product reauthorization is not justified without evidence of where time is spent. Doing nothing remains viable only if the extra gate rerun cost is accepted and all failed gates remain blocking; the repeated friction argues for addressing it.

**Validation for `kaizen-fix`:** first capture PID/ref and monotonic timestamps at send, handler entry/exit or crash, and monitor delivery in a temporary diagnostic under representative full-suite contention (without relaxing authorization). Check the same PID and failure reason; if no `:DOWN` ever arrives or the process remains alive, investigate product/binding/sandbox behavior instead of raising the timeout. If only late matching `:DOWN`s occur, choose a measured bounded wait, retain reason matching, add failure diagnostics, run targeted repeated tests and several representative full gates on the exact candidate state, then track recurrence and time-to-diagnose in later gates. Those future full gates are validation of a fix, not evidence from this docs-only investigation. No product or test change was made here.
