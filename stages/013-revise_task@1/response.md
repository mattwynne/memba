Implemented packet `004-951d743-04` and recorded `ready_for_review` in [latest-worker-result.json](/workspace/memba/docs/iterations/064-leave-and-remove-group-members/.delivery/latest-worker-result.json).

Key changes:

- Shared-access conversations now record a durable removal cutoff while retaining the valid follow.
- Explicit retention works even when the follow and cleanup generations are equal.
- Ordinary unfollow preserves cleanup generations, preventing delayed manual or reply-auto work from restoring stale follows.
- Cleanup enumeration now waits through a durable checkpoint at or after `MemberFollowCleanupRecorded`, including event-free exact retries.
- Added deterministic coverage for a stale root committed between Membership removal and Messaging cleanup while projectors are suspended.
- Unrelated conversations remain untouched, newer post-re-add follows remain valid, and task-001/system-group behavior is preserved.
- `todo.md` remains unchanged and task 004 remains unchecked.

Validation passed:

- Membership/removal policy suite: 39 tests, 0 failures.
- Messaging/follower suite: 80 tests, 0 failures.
- Changed-file formatting check passed.
- `git diff --check` passed.

Per the packet’s explicit exclusion, I did not run `dev check`; the workflow’s later deterministic gate owns that full-suite validation.