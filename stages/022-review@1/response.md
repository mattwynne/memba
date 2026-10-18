Review written to [review.md](/workspace/memba/.fabro/tmp/bdd/review.md).

Two actionable findings remain:

- `PersonRenamed` is missing from the live-query adapter, so rename notifications can terminate connected member LiveViews instead of refreshing the affected Person.
- An unchanged historical name longer than 100 graphemes is rejected, contrary to the agreed eventless no-op and historical compatibility rules.

The selected scenario’s `@wip` was correctly removed, unrelated pending tags and assertions remain unchanged, and the recorded full check passed on the same tree as `HEAD`. No product code was edited or published.

{"preferred_next_label":"fix"}