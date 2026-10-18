No further worthwhile refactoring remains. The latest documentation cleanup started and ended green:

- Ordinary scenario: `132 tests, 0 failures, 131 excluded`
- `person_commands_test.exs`: `7 tests, 0 failures`
- Corrected formatter and `git diff --check`: passed

I re-inspected the complete 16-file diff from the recorded base, including all new files. The aggregate, trusted-actor preparation, dispatch, event, projection, and live-query responsibilities are appropriately separated; further changes would be cosmetic or risk weakening historical compatibility.

I ran a fresh `bin/dev check` on tracked commit `03f4d86b4b06726426e0a894cc60498d4b9e02c8`; it exited 0. The tracked worktree is clean, with only `.fabro/tmp/` untracked. The final checkpoint is recorded in [.fabro/tmp/bdd/change.md](/workspace/memba/.fabro/tmp/bdd/change.md).

{"preferred_next_label":"check"}