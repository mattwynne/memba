The latest failure is a step-pattern bug: `{word}` greedily consumes `Alice's`, so the possessive literal never matches. I prepared one focused driver assignment to replace only those two patterns with anchored regexes and rerun the supporting and WIP tests.

{"preferred_next_label":"change"}