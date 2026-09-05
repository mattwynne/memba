Completed both selected review repairs without changing product behaviour or acceptance features. The three changes are staged but not committed.

| Review issue | Fix | Evidence |
|---|---|---|
| Document projection fixture contract and test Repo pool rationale | Clarified that the fixture directly creates read-model rows, roots create access grants, and replies require an existing root/grant. Expanded the test-pool comment to explain single-scheduler starvation and why 16 is the tested minimum. | [messaging_fixtures.ex](/workspace/memba/web/test/support/messaging_fixtures.ex:2), [test.exs](/workspace/memba/web/config/test.exs:17) |
| Verify and align the Groups vision with `club_members_only` | Updated the vision to distinguish new-conversation posting policy from reply authorization: any active destination-club member may start a group email conversation, while replies still require group write access. It also records deferred policy configuration. | [groups-and-conversation-access-vision.md](/workspace/memba/docs/specs/2026-09-02-groups-and-conversation-access-vision.md:77) |

Files changed by issue:

- Test infrastructure contracts:
  - `web/test/support/messaging_fixtures.ex`
  - `web/config/test.exs`
- Groups policy alignment:
  - `docs/specs/2026-09-02-groups-and-conversation-access-vision.md`

No automated tests were added because both findings concerned documentation of already-tested contracts; no executable behaviour changed.

Validation:

- `dev check --quick`: passed — 1,129 tests, 0 failures.
- `dev acceptance`: passed — exit code 0; 122 scenarios and 877 steps.
- Combined `dev check`: reached successful final acceptance cleanup, but the terminal wrapper hit its 600-second limit before returning an exit status. I therefore do not label that combined invocation itself as passing; its quick and acceptance components passed independently on the exact staged diff.
- `git diff --cached --check`: passed.
- No `*.feature` files were changed.

There are no remaining gaps or human questions for the two selected review issues. Existing dependency-security advisories and occasional SQL Sandbox ownership logs during test teardown remain outside this bounded repair. The pre-existing untracked `.fabro/tmp/` directory was untouched.