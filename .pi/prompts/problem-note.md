---
description: Capture a user-facing product problem in docs/problems and commit it
argument-hint: "<problem>"
---

Capture this product problem as a short problem note in `docs/problems/` and commit the note.

Problem supplied with the command:

```
$@
```

Before creating a new file, search the existing problem backlog for duplicates or closely related notes:

- Inspect `docs/problems/README.md` when it exists.
- Search `docs/problems/*.md` for related terms, actors, workflows, and expected outcomes from the supplied problem.
- If an existing note already captures the same underlying user-facing problem, amend/update that existing note instead of creating a duplicate. Add the new observation date/context to the existing note only when it adds useful facts.
- If the supplied problem is related but materially different, create a new note and make the distinction clear.

If no existing note captures the same underlying problem, write a new Markdown file named `docs/problems/YYYY-MM-DD-short-problem-slug.md`.

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
- When updating an existing note, commit only the touched problem note/index files and prompt changes that are part of this task. Leave unrelated working-tree changes untouched.
- When creating a new note, commit only the new problem note and any intentional problem index update. Leave unrelated working-tree changes untouched.
