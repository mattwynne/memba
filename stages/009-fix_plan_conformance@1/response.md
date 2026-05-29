Implemented the plan-conformance repair and validated it.

Note: the provided Plan Conformance Gate output only exposed `plan_conformant=false` / `plan_rework_available=true`; it did not include a textual repair brief. I repaired the concrete gaps identifiable from the plan text, relevant ADR 0011, and current implementation.

## 1. Plan requirement gaps addressed

| Gap | Requirement source | Fix |
|---|---|---|
| `AddMember` could be dispatched without proving the person and club already existed. | Plan: Membership aggregate attaches an existing person to an existing club. | Added a public Membership command boundary that checks projected club/person existence before dispatching `AddMember`. |
| Duplicate active memberships for the same `{club_id, person_id}` pair were not prevented at the application/query boundary. | ADR 0011, cited by the plan. | Added duplicate-active-membership rejection before dispatching `AddMember`. |
| Cucumber step definitions used lower-level `Memba.Membership.App.dispatch/2` directly instead of the public Membership API boundary. | Plan implementation step 4: step definitions use public Membership API. | Updated step definitions to use `Memba.Membership.dispatch/2`. |
| Query tests proved `list_active_members_of_club/1` using direct dispatch against arbitrary club IDs rather than created clubs through the Membership boundary. | Acceptance criteria: person created independently can be added via domain commands; active member query excludes other clubs. | Updated query tests to create clubs, people, and memberships through the public Membership command boundary. |

## 2. Concrete changes made

### Public Membership command boundary

Updated `web/lib/memba/membership.ex`:

- Added `Memba.Membership.dispatch/2`.
- Supports:
  - `%CreateClub{}`
  - `%CreatePerson{}`
  - `%AddMember{}`
- Defaults dispatch to `consistency: :strong`.
- For `AddMember`, validates:
  - club exists via `get_club/1`
  - person exists via `get_person/1`
  - no existing active membership via `active_member_of_club?/2`
- Returns:
  - `{:error, :club_not_found}`
  - `{:error, :person_not_found}`
  - `{:error, :already_active_member}`

### Cucumber step definitions

Updated `web/test/features/step_definitions/membership_steps.exs`:

- Replaced direct `Memba.Membership.App.dispatch/2` usage with `Memba.Membership.dispatch/2`.
- Kept caller-generated UUIDs in the steps.

### Tests

Added `web/test/memba/membership/application_service_test.exs`:

- Proves a person can be created independently and added to an existing club.
- Proves missing club rejection.
- Proves missing person rejection.
- Proves duplicate active membership rejection.

Updated `web/test/memba/membership/query_test.exs`:

- Query API tests now create clubs/people/memberships through `Memba.Membership.dispatch/2`.
- Still verifies `list_active_members_of_club/1` returns only active members of the requested club.

Updated `web/test/memba/membership/no_crud_spike_test.exs`:

- Adjusted wording/assertion to allow the public command boundary while still preventing CRUD-style helpers.

## 3. Files changed by requirement

### Existing club/person and duplicate membership enforcement

- `web/lib/memba/membership.ex`
- `web/test/memba/membership/application_service_test.exs`

### Cucumber Background steps use public Membership API

- `web/test/features/step_definitions/membership_steps.exs`

### Query API proven through domain command boundary

- `web/test/memba/membership/query_test.exs`

### Guard against CRUD spike while allowing command boundary

- `web/test/memba/membership/no_crud_spike_test.exs`

## 4. Automated tests added or updated

Added:

- `Memba.Membership.ApplicationServiceTest`

Updated:

- `Memba.Membership.QueryTest`
- `Memba.Cucumber.MembershipSteps`
- `Memba.Membership.NoCrudSpikeTest`

## 5. Tests run

All final validations passed:

- `devenv shell bin/mix format --check-formatted` — passed
- `devenv shell bin/mix test test/memba/membership/application_service_test.exs test/memba/membership/query_test.exs test/features/cucumber_configuration_test.exs test/memba/membership/no_crud_spike_test.exs` — passed, 13 tests, 0 failures
- `PATH="$PWD/bin:$PATH" dev check` — passed, 57 tests, 0 failures
- `devenv shell bin/mix precommit` — passed, 57 tests, 0 failures

## 6. Remaining gaps or human questions

No remaining plan gaps identified from the available gate context, plan text, and repository state. No acceptance feature files were modified.