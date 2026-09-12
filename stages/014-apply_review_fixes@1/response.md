Implemented the selected review repair. The silent projected-club fallback is gone; invitation LiveView tests now fail explicitly if the Club projection is unavailable or has the wrong identity.

### Issue-to-fix mapping

| Review issue | Fix | Coverage |
|---|---|---|
| `tighten-projected-club-test-helper` — fallback could conceal missing/stale projection state | `club_host/2` now asserts that `Membership.get_club/1` returns a `Club` projection with the expected pinned `club_id`, then derives the host exclusively from that projection | All tests in `MemberInvitationLive.SendTest` using `signed_in_club_host/3`; the fixture creates clubs with `consistency: :strong` |

### Files changed

- [send_test.exs](/workspace/memba/web/test/memba_web/live/member_invitation_live/send_test.exs:11)
  - Added the `Club` projection alias.
  - Replaced `get_club(...) || club` with the explicit projection assertion at [club_host/2](/workspace/memba/web/test/memba_web/live/member_invitation_live/send_test.exs:216).
  - Reused the alias in the fixture’s projection lookup.
  - No product code or acceptance feature files were changed.

### Validation

- `mix format --check-formatted test/memba_web/live/member_invitation_live/send_test.exs` — passed.
- `git diff --check` — passed.
- `dev check`:
  - The complete `mix precommit` phase passed, which includes warnings-as-errors compilation, unused-dependency checking, formatting, and the full ExUnit suite.
  - Browser acceptance then ran through passing scenarios until the command exceeded the terminal’s 10-minute execution limit. No test failure was reported before termination.
- A subsequent `dev check --quick` could not initialize the test database because the timed-out run left 24 database sessions connected. Per the sandbox/runtime boundary, I stopped rather than changing scripts, tests, or application code to compensate.

The repair itself has no remaining code gap. The remaining operational step is to clean up or restart the sandbox-managed PostgreSQL state and rerun full `dev check` for a conclusive final browser-acceptance result. The pipeline’s full pre-repair `dev ci` remains green at 134 scenarios and 951 steps, but I am not representing that as validation of this exact final diff.

No changes were committed.