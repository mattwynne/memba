The focused run selected exactly one scenario: “Alice's older edit requires confirmation of the newer name.” It failed as predicted at the first undefined step:

`Given Alice began changing their name when it was "Alice Smith"`

The canonical `bin/dev test:wip` run exited 2 with one test and one failure. Its output and status are preserved in `.fabro/tmp/bdd/`. I also recorded that bare `dev test:wip` initially exited 127 because this shell lacks the repository’s `bin/` PATH entry.

The next single change is documented in [change.md](/workspace/memba/.fabro/tmp/bdd/change.md): add only the scenario setup step that creates Alice with the authoritative starting name and retains the stale edit baseline. The predicted next failure is the still-undefined intervening rename step.

{"preferred_next_label":"change"}