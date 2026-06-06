1. **Selected todo line**
   - `003 Design the request persistence model:`

2. **Changes made**
   - Added `docs/iterations/022-request-to-club-onboarding/request-persistence-model.md`.
   - Documented:
     - new `Memba.Onboarding` context;
     - `onboarding_requests` table shape;
     - typed `req_` request IDs;
     - requester, status, rejection, conversion, audit, and timestamp fields;
     - indexes/constraints;
     - schema/changeset rules;
     - context API shape for task 004;
     - conversion/person reuse rules;
     - signed-in requester persistence rules.
   - Checked off only todo `003`.

3. **Focused validation run**
   - `git diff --check` — passed.
   - `git diff --no-index --check -- /dev/null docs/iterations/022-request-to-club-onboarding/request-persistence-model.md || test $? -eq 1` — passed.
   - I did **not** run `dev check` because this was a docs-only design slice, and project guidance says not to run it for docs-only changes unless explicitly requested.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 003 Design the request persistence model:`
   - To:
     - `- [x] 003 Design the request persistence model:`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - ADR 0001: design stays within Phoenix/PostgreSQL application architecture.
   - ADR 0002: explicitly documents why onboarding requests are an Ecto source-of-truth exception rather than a new event-sourced aggregate.
   - ADR 0009: avoids treating Membership projection tables as foreign-key targets.
   - ADR 0011: uses caller/generated typed IDs for the request model.
   - ADR 0021/0022: no read-model publication or projection barrier behaviour changed.