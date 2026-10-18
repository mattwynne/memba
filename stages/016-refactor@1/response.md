Recorded one focused refactoring assignment in [.fabro/tmp/bdd/change.md](/workspace/memba/.fabro/tmp/bdd/change.md): clarify that `PersonCommands.prepare_rename/2` receives a caller-established trusted actor identity and validates self-targeting, rather than authenticating the caller itself.

The assignment preserves:

- The same now-untagged stale-edit scenario and its ordinary focused command.
- A mandatory green starting run; red means stop for implementation repair.
- CQRS preparation/dispatch separation and trusted identity boundaries.
- Atom/string target validation, no-op authorization, conditional confirmation, projection readback, and historical replay behavior.
- Unique focused command-preparation and dispatch test selections.
- Final full `bin/dev check` for the navigator after the driver returns.

No product code or acceptance scenarios were changed, and nothing was published.

{"preferred_next_label":"implement"}