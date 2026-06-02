I’m implementing the next unchecked task:

`016 Update staff/operator person displays to show primary and alternate addresses distinctly.`

Current status:

- I updated the admin club show page:
  - People list now shows:
    - `Primary: ...`
    - a distinct “Alternate email addresses” section/list
  - Members list now also shows:
    - `Primary: ...`
    - distinct alternate email addresses
- I updated the related LiveView test to verify both person rows and member rows display primary/alternate addresses separately.
- I checked off only task `016` in `todo.md`.

Validation so far:

- `mix format --check-formatted ...` passed.
- Focused admin club LiveView test passed: `5 tests, 0 failures`.
- Related admin people/club LiveView tests passed: `10 tests, 0 failures`.
- Full required `dev check` passed: `343 tests, 0 failures`.

One environment note: Postgres was stuck in a stale “shutting down” state, which had also happened in earlier checkpoints. I cleared the stale repo-managed Postgres lock/socket/process and restarted it before running tests. The code validation is green now.

I’m at final sanity-check stage with three modified files:

- `docs/iterations/016-person-email-addresses/todo.md`
- `web/lib/memba_web/live/admin/clubs_live/show.ex`
- `web/test/memba_web/live/admin/clubs_live/show_test.exs`