1. **Selected todo line**
   - `004 Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.`

2. **Changes made**
   - Added `onboarding_requests` migration with:
     - typed `request_id` primary key;
     - requester details, normalized email, optional signed-in person ID;
     - active/converted/rejected status and check constraint;
     - rejection/conversion audit fields;
     - active inbox and normalized email indexes.
   - Added `Memba.Onboarding.Request` Ecto schema and changesets.
   - Added `Memba.Onboarding` context API:
     - `create_request/2`
     - `list_active_requests/0`
     - `get_request/1`
     - `reject_request/3`
     - `convert_request/3`
   - Added `:onboarding_request` typed IDs with `req_` prefix.
   - Added context tests for creation, validation, listing active requests, fetching, rejection, conversion, typed ID validation, and not-active transitions.

3. **Focused validation commands run and results**
   - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix format ...` — passed.
   - `env -u PGHOST -u PGPORT PATH="$PWD/bin:$PATH" bin/mix compile --warnings-as-errors` — passed.
   - `PATH="$PWD/bin:$PATH" dev check --quick` — passed: `541 tests, 0 failures`.
   - `git diff --check` — passed.
   - `git diff --no-index --check` for newly added files — passed.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 004 Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.`
   - To:
     - `- [x] 004 Add migration/schema/context functions for creating, listing active, rejecting, and converting requests.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: uses Phoenix/Ecto/PostgreSQL for the application persistence slice.
   - ADR 0002: follows the prior documented exception by using an Ecto source-of-truth table only for operational onboarding triage, not for membership lifecycle.
   - ADR 0009: does not foreign-key to Membership projection tables; conversion IDs are audit references.
   - ADR 0011: uses caller/generated typed IDs, adding `req_` onboarding request IDs through `Memba.ID`.
   - ADR 0021/0022: no read-model publication or projection barrier behavior changed.