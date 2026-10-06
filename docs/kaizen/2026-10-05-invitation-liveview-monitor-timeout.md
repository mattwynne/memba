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
