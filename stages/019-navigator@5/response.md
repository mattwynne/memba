The cleanup is complete and the exact-state full gate passed, but fresh review found one medium trust-boundary issue: `expected_name` is still accepted from editable attributes, even though the conflict baseline must remain server-owned.

I replaced [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one repair assignment:

- Change preparation to `prepare_rename(actor, target, expected_name, editable_attrs)`.
- Keep only the requested `name` in editable attributes.
- Update current callers and focused tests.
- Add coverage proving an injected posted `expected_name` cannot replace the separately supplied server baseline.
- Preserve all aggregate behavior, authorization, events, projections, and the unchanged ordinary scenario.

Existing tests are green, so the assignment explicitly avoids manufacturing a red run.

{"preferred_next_label":"change"}