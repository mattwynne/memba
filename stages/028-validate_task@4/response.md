### Decision

**VALID**

### Evidence

- Completed todo/check-off evidence found:
  - Live working tree is clean.
  - Latest commit is an empty `pre_validate_snapshot` checkpoint (`08a3b85`); the recent implementation checkpoint is `b23ea99`.
  - `b23ea99` changes exactly one ordinary todo line:
    - `004 Update projections/read models and loaders so current status lists, summaries, and grouping functions do not include opened.`
    - from `- [ ]` to `- [x]`.
  - The parent todo state shows task `004` was the first unchecked task when implementation began.

- Implementation artifacts found:
  - Member and Memba-staff projectors no longer project `EmailDeliveryOpened` into `"opened"` read-model rows.
  - `Memba.Messaging` query APIs normalize legacy `"opened"` projection rows to `"delivered"` for member and staff read models, clearing staff `reason`.
  - Projection module docs now describe current status vocabularies without opened.
  - Member receipt presentation removes opened from ordering/summary, normalizes legacy opened to delivered, and changes copy from “arrived, not opened yet” to “arrived”.
  - Dashboard receipt glance now reports delivered counts instead of opened counts.
  - Tests were updated/added for projection normalization, presentation grouping/summary behavior, controller/LiveView absence of opened groups/segments, and dashboard delivered summaries.
  - No acceptance `.feature` files were edited in this checkpoint.

- Tests run/results found:
  - I ran live validation: `PATH="$PWD/bin:$PATH" dev check`
  - Result: passed — `357 tests, 0 failures`.

- ADR/plan conformance notes:
  - Work matches task `004` and stays within the approved remove-open-tracking plan.
  - Commanded/Ecto projection architecture from ADR 0009 is preserved.
  - Messaging bounded-context/query boundary from ADR 0007 is preserved.
  - Message aggregate/read-model shape from ADR 0004 is preserved.
  - ADR 0012’s old opened behavior is superseded by this validated iteration policy; legacy opened compatibility is handled by normalization rather than migration/backfill, consistent with the plan.
  - Remaining active opened/open-tracking references are in future scoped tasks such as Postmark outbound/webhook and staff/member view cleanup; those todo items remain unchecked.

{"context_updates":{"task_valid":true,"task_retry_available":false}}