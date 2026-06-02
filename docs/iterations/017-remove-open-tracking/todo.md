# Implementation TODO

- [ ] 001 Inspect current opened references in `web/lib`, `web/test`, `acceptance-tests/features`, active docs, and Postmark delivery code. Exclude old `docs/iterations/**` design/prototype artifacts from cleanup unless they are active validation inputs.
- [ ] 002 Update shared acceptance feature expectations to remove opened receipts.
- [ ] 003 Remove or deprecate the Messaging opened-report command/API/event path from current behaviour:
- [ ] 004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.
- [ ] 005 Update Postmark outbound delivery so it does not set `track_opens: true` or any equivalent open-tracking option.
- [ ] 006 Update Postmark webhook handling so open events are treated as unsupported and do not mutate delivery status.
- [ ] 007 Update member LiveViews/presentation modules/tests to remove opened receipt segments, groups, toggles, counts, data attributes, and copy.
- [ ] 008 Update Memba staff delivery views/tests to remove opened status expectations while preserving delivered/problem visibility.
- [ ] 009 Update active operational/current-app documentation, especially Postmark email docs, to remove open-tracking instructions or claims.
- [ ] 010 Run targeted tests while changing each layer, then run `dev check` and fix regressions.
