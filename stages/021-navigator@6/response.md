The server-owned-baseline repair is complete and matches the assignment:

- `prepare_rename/4` now separates actor context, target identity, server-held expected name, and editable requested name.
- Injected posted `expected_name` data cannot replace the server-held baseline.
- Authorization still occurs before editable input is read.
- All callers use the new contract.
- Focused preparation/dispatch suite: 11 tests, 0 failures.
- Ordinary focused scenario: exactly one included test, 0 failures.
- The feature file and `@iteration-068` tag remain unchanged.

No further implementation repair is currently indicated. The cumulative diff can return to refactoring and then receive a new exact-state full check and review.

{"preferred_next_label":"refactor"}