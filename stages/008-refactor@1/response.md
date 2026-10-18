Reviewed the full diff from base `42b0f051ba206f972120e2be110bf1ac4dd80c4e`, including new files, relevant ADRs/design guidance, prior handoffs, and raw test logs.

The ordinary untagged scenario is green. I assigned one bounded clarity cleanup in [.fabro/tmp/bdd/change.md](/workspace/memba/.fabro/tmp/bdd/change.md): correct `PersonCommands`’ stale module documentation so it reflects both command preparation and the trusted-actor self-rename boundary. The assignment preserves the scenario identity, specifies its ordinary focused command, covers the relevant command-preparation tests without duplicate selections, and requires final `dev check`.

No product code was changed or published.

{"preferred_next_label":"change"}