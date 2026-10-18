The trust-boundary repair is complete, and no further worthwhile cleanup remains.

`PersonCommands.prepare_rename/4` now keeps these responsibilities explicit:

- Authenticated actor context
- Target Person identity
- Server-held expected name
- Editable requested name

An injected posted `expected_name` cannot replace the server-held baseline. Authorization still occurs before editable attributes are read or a command is constructed. Aggregate conflict decisions, normalization, historical no-op behavior, event replay, projection updates, and live-query invalidation remain unchanged.

Verification on exact HEAD `318cf4b8480c61f222c19a20faf823ad4c88b767`:

- Focused preparation and dispatch tests: 11 tests, 0 failures
- Exact ordinary scenario: 132 generated tests, 131 excluded, 1 included, 0 failures
- Full `dev check`: passed, including 19 package tests and 7 browser scenarios with 113 passing steps
- Both base-to-HEAD and working-tree `git diff --check`: passed
- Exact scenario remains untagged with its wording unchanged
- Tracked worktree is clean; only `.fabro/tmp/` is untracked
- Nothing was published

{"preferred_next_label":"check"}