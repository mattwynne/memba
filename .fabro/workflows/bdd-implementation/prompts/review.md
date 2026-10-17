Review the whole change in fresh context. Read `{{ inputs.plan }}`, its relevant links, project guidance, `.fabro/tmp/bdd/base` and the actual full-check output in `.fabro/tmp/bdd/check.log`. Inspect the code and cumulative diff from that base, including new files. Review the one selected scenario and its supporting changes, not delivery of the entire iteration. Its original `@wip` tag should be removed after passing; no agreed assertion or unrelated pending tag should be weakened. Do not rely on the implementation conversation or edit product code.

Make one review covering the applicable lenses: architecture and accepted ADRs; code design, readability and idiomatic Elixir; the agreed behaviour; UX where visible behaviour changes; and copy where wording changes, using `.pi/skills/talking-to-humans/SKILL.md`. Use real evidence. If necessary visual or behavioural evidence is missing, say so rather than assuming it passed.

Write one combined finding list to `.fabro/tmp/bdd/review.md`, with concrete locations, consequences and suggested repairs. On a later review, check the whole current change again and remove findings that are resolved. Do not publish.

End with `{"preferred_next_label":"fix"}` for actionable findings, `{"preferred_next_label":"done"}` when none remain, or `{"preferred_next_label":"stop"}` when a genuine unresolved decision prevents review.
