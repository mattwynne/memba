---
description: Capture a user-facing product problem in docs/problems and commit it
argument-hint: "<problem>"
---

Capture this product problem as a short problem note in `docs/problems/` and commit the note.

Problem supplied with the command:

```
$@
```

Write a new Markdown file named `docs/problems/YYYY-MM-DD-short-problem-slug.md`.

Use this shape unless the facts call for something simpler:

```markdown
# Problems

## <short problem statement>

Observed: YYYY-MM-DD

<plain-language description of what was observed>

Expected:

- <expected behaviour or standard>
- <expected user outcome>
```

Guidelines:

- Keep the note factual and user-facing.
- Do not design the full solution unless the supplied problem already includes obvious expected outcomes.
- If the supplied context is enough, write the note without asking follow-up questions.
- If the supplied problem is unclear, ambiguous, or lacks enough user-facing context to write a factual note, ask for clarification before creating the file.
- Ask only for essential missing facts or context; do not invent details.
- Do not edit application code.
- Do not run `dev check` for this docs-only note.
- Commit only the new problem note. Leave unrelated working-tree changes untouched.
