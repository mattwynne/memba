The review’s high-severity finding is confirmed. `PersonRenamed` is published after projection commit but is absent from the live-query adapter, so connected member views would raise an unsupported-event contract error.

I replaced [change.md](/workspace/memba/.fabro/tmp/bdd/change.md) with one repair assignment:

- Classify `PersonRenamed` as exactly `{:person, person_id}`.
- Add focused adapter event-family coverage.
- Preserve the selected scenario and all existing email invalidations.
- Leave the separate historical overlength no-op finding queued for the next navigator visit.

The existing full check is green because its Person event-family test omits this event; the assignment records that evidence mismatch and the expected focused regression failure.

{"preferred_next_label":"change"}