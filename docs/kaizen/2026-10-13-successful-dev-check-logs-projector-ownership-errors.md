# Problem: Successful dev checks log projector sandbox ownership errors

Date: 2026-10-13

## Context

Exact-commit `./bin/dev check` validation during facade delivery produced passing suites. Local evidence is retained in `/tmp/memba-facade-merged-main-check.log`, `/tmp/memba-facade-manual-retry-check.log`, and `/tmp/memba-facade-rebased-full-check.log` on this host.

## Expected standard

A passing quality gate should provide legible feedback: expected test cleanup should not look like an unhandled database failure, and real subscription failures should not be obscured by a green summary.

## What happened

All three logs include `DBConnection.OwnershipError` for `Memba.Repo` in `:manual` mode and projector/subscription errors or warnings during ExUnit; all three report zero ExUnit failures (1807, 1807, and 1808 tests respectively) and passing browser scenarios. The merged-main log shows ownership errors around lines 114–225 and a later `source_backed_admin_invariant` retry warning with `tcp recv: closed` at line 277. Similar TCP warnings occur in the other logs. The temporal and causal relation between the TCP warnings and ownership errors is not established.

## Impact

Repeated alarming errors in green validation logs cost diagnostic attention and make it harder to distinguish benign teardown noise from a real validation failure. This is delivery/test feedback friction, not evidence that application behavior is incorrect.

## What allowed it to happen

The check's summary tolerates these process logs while the test suites pass; the underlying test-process ownership/lifecycle boundary and whether these are expected cleanup or a test isolation defect remain to be investigated.

## Observations

- The 2026-09-28 publish-timeout note mentions incidental sandbox and TCP warnings from a passing cold check, but its investigated failure was a 300-second publication deadline, not these repeated ownership errors.
- Do not attribute the ownership errors to PostgreSQL missing-file errors from that separate timed-out publish run without evidence.

## Why this matters

Green checks with noisy crash reports undermine trust in the signal and can hide a later genuine projector regression.

## Open questions

- Which test lifecycle starts and releases the projector subscriptions and sandbox owner at the error sites?
- Are any projector results silently lost, or is this confined to test teardown?
- Is the TCP retry warning related or a separate transient connection event?

## Investigation: 2026-10-13

**Current and target conditions.** Three passing exact-commit checks contain actual projector event-handling failures, not just harmless-looking warning text. The target is a green check with no unexpected projector ownership errors; if a projector fails while a test is active, the relevant test should fail with actionable context. The observed frequency is three sampled check logs, not a measured rate across all runs.

**Evidence and causal boundary.** In merged-main log lines 97–225, `Membership` and `GroupMembership` fail to project `ClubMemberRemoved` and `GroupMemberRemoved` events from one stream (versions 18–19, event numbers 26–27) at 02:52:08.589. The stack enters `commanded_ecto_projections`' Ecto transaction and `DBConnection.rollback_or_raise/1`; `Memba.Repo` is in sandbox `:manual` mode and reports no ownership process for the handler PIDs. The handlers and their EventStore subscription processes then terminate; at 02:52:13 a system-group policy handling the same removal reports a consistency timeout. The rebased check has the same paired event types, ownership errors, and timeout at 14:18:03–08. The manual retry has one earlier membership failure and a later paired failure with timeout at 23:54:28–33. These are real failed background handlers, even though ExUnit finishes 1807/1808 tests with zero failures. The affected stream IDs differ between runs; no log identifies the owning ExUnit test.

`web/test/test_helper.exs` sets sandbox mode to `:manual`; `web/test/support/data_case.ex` starts a shared owner for non-async tests and registers its stop in `on_exit`. `web/test/support/event_sourced_case.ex` stops/restarts globally supervised projectors and policies around a database reset, *before* starting the sandbox owner for a test; its subscribers are persistent application children, not children started and joined by each test. The error establishes that the particular handlers did not have a usable sandbox owner **at the instant they tried to project**. A likely timing route is queued events reaching a persistent subscriber after its test's owner has been stopped or around the next test's reset/restart; alternatively an active test may not have installed an appropriate shared owner. The logs do not prove which test or exact owner-stop ordering. The ensuing timeout is consistent with the handlers failing to acknowledge the event; do not assume successful ExUnit assertions prove those particular projections were eventually processed. Compare `web/test/memba/membership/system_group_membership_policy_dispatch_test.exs`, which explicitly asserts group membership after strong dispatch, as a working synchronization pattern, but the noisy event cannot yet be mapped to that test.

The `source_backed_admin_invariant` retry warning (`tcp recv: closed`) is at 02:52:49 in merged-main, roughly 41 seconds after the paired errors; in manual retry it *precedes* both ownership episodes (23:53:55 versus 23:54:04 and 23:54:28). `web/lib/memba/membership/source_backed_admin_invariant.ex` emits this when retrying a `DBConnection.ConnectionError`. The ordering rules out a consistent immediate downstream sequence, but does not identify the TCP close cause. The 2026-09-28 publish note investigated a separate timeout and PostgreSQL missing-file errors; neither that mechanism nor a connection warning explains these ownership failures on current evidence.

**Why this escapes.** The test harness treats ExUnit assertions and process logger output separately. A supervised event handler can die and log while a test ends without observing the failure; the global subscription reset at the next setup may clean up the visible state. Whether the specific failures occur during teardown or while a test is running, and whether any assertion missed a necessary event, remain open. The full check's passing summary is therefore not a reliable negative test for this class of background errors.

**Challenge the work, then options.** Keep strong-consistency assertions and a functioning projection lifecycle: dropping projector tests, disabling subscribers, suppressing logger output, or globally sharing the sandbox would hide failures or weaken isolation. No extra standing artifact, database, or full-suite gate is needed to diagnose this. The smallest candidate prevention is to make each test's subscriber lifetime/acknowledgement boundary explicit before releasing its owner (or ensure dispatch awaits the relevant projector and policy), once the offending test is identified. Containment is a focused regression that captures unexpected ownership failures and checks a completed projection before owner cleanup; a broad log-string failure gate alone risks misclassifying deliberate error-path tests. Doing nothing keeps green checks noisy and potentially misses work. A wholesale replacement of sandbox/reset orchestration may solve a wider class of races but is unjustified without tracing the actual producer and owner lifecycle. Treat the TCP warning as separate investigation until a shared mechanism is demonstrated.

**Recommendation and validation plan (not implemented).** First identify the originating ExUnit test with a *single serial focused* run (line/test-name logging or an instrumented test boundary), recording event stream ID, test PID, sandbox owner PID and owner-stop time, subscriber PID/start/stop, dispatch/ack time, and error time. A targeted test under a reserved database/port is appropriate only when no other DB-backed run shares that resource; no full check or parallel database run is needed now. Confirm the hypothesis by reproducing the failure at a known owner/subscriber boundary; if it does not recur, retain instrumentation rather than asserting a cause. Then add a failing regression for that boundary, choose the smallest lifecycle/synchronization correction, verify with repeated focused runs and subsequently representative serial exact-commit checks. Compare ownership-error counts (three sampled logs with errors) and regression outcomes without hiding expected failures; review whether the independent TCP retries persist. Preserve a distinct test for policy consistency after member removal. No correction is authorized by this investigation.

**Decision pending:** Should `kaizen-fix` prioritize identifying and correcting the sandbox/subscriber boundary, with the TCP retry tracked separately unless evidence joins them? Recommended: yes. Owner/review date for effectiveness should be agreed when implementing, not invented here.
