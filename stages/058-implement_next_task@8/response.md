1. **Selected todo line**
   - `008 Re-run the baseline grep to confirm only the documented shim remains.`

2. **Changes made**
   - Re-ran the final `opened`/`Opened` inventory across tracked `web/lib/`, `web/test/`, and `acceptance-tests/` files.
   - Confirmed remaining `lib` hits are the documented replay shim:
     - `EmailDeliveryOpened` tombstone event module.
     - No-op aggregate `apply/2`.
     - No-op member/staff projector clauses.
   - Confirmed removed live-behaviour patterns are absent:
     - `ReportEmailDeliveryOpened`
     - `status: "opened"`
     - `"opened" -> "delivered"`
     - literal `"opened"` status strings
   - Confirmed acceptance test source has no relevant remaining tracked references.
   - Checked off only todo `008`.

3. **Focused validation commands run**
   - `git ls-files 'web/lib/*' 'web/test/*' 'acceptance-tests/*' | grep -v '^acceptance-tests/node_modules/' | xargs grep -nE '\b(opened|Opened)\b' || true`
     - Passed/classified: only replay-safety test wording plus shim-related exact token hits.
   - `git ls-files 'web/lib/*' 'web/test/*' 'acceptance-tests/*' | grep -v '^acceptance-tests/node_modules/' | xargs grep -nE 'opened|Opened' || true`
     - Passed/classified: only documented shim/test coverage plus one unrelated `reopened` word in membership docs.
   - Removed-live-behaviour checks for:
     - `ReportEmailDeliveryOpened`
     - `status: "opened"`
     - `"opened" -> "delivered"`
     - `"opened"`
     - All returned no matches.
   - `git diff --check`
     - Passed.
   - `git diff -- docs/iterations/035-obliterate-opened-delivery-status/todo.md`
     - Confirmed only task `008` was checked off.

4. **Exact todo check-off**
   - Changed:
     - `- [ ] 008 Re-run the baseline grep to confirm only the documented shim remains.`
   - To:
     - `- [x] 008 Re-run the baseline grep to confirm only the documented shim remains.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - The plan does not explicitly reference ADR numbers for this task.
   - This was validation-only and preserves the accepted event-sourcing strategy: `EmailDeliveryOpened` remains only as a documented replay/deserialization shim, with no live product status behaviour reintroduced.