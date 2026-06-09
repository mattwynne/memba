Implemented the selected review repair: `fix-get-started-request-param-polish`.

## Issue-to-fix mapping

| Review issue | Fixes applied | Files |
|---|---|---|
| `fix-get-started-request-param-polish` — Make Get Started request params nil-safe and clarify trusted requester name selection | Added a guarded `request_param/2` path so malformed/non-map request params safely fall through to validation instead of raising. Extracted trusted existing-person requester attrs into `verified_requester_details/1` so the signed-in Person name/email selection is explicit. Added a regression controller test proving a signed-in malformed request returns validation errors, creates no request, and sends no email. | `web/lib/memba_web/controllers/page_controller.ex`, `web/test/memba_web/controllers/page_controller_test.exs` |

## Concrete changes made

### `web/lib/memba_web/controllers/page_controller.ex`

- Replaced inline existing-Person requester map construction with:

  ```elixir
  verified_requester_details(requester)
  ```

  This makes it clearer that existing Person name/email are the trusted requester details.

- Hardened request param access:

  ```elixir
  defp request_param(request_params, key) when is_map(request_params) do
    ...
  end

  defp request_param(_request_params, _key), do: nil
  ```

  Malformed request params now flow into existing changeset validation instead of risking a controller exception.

### `web/test/memba_web/controllers/page_controller_test.exs`

- Added regression test:

  - signed-in requester submits malformed request details missing club name;
  - response is `422`;
  - request form shows validation error;
  - no onboarding request is created;
  - no Staff notification email is sent.

## Tests run

- Attempted targeted direct test:

  ```sh
  cd web && mix test test/memba_web/controllers/page_controller_test.exs
  ```

  Result: failed before tests due local Postgres socket unavailable at `/tmp/devenv/postgres/.s.PGSQL.15432`. This was an environment/service availability issue, not an app/test failure.

- Required project validation:

  ```sh
  PATH="$PWD/bin:$PATH" dev check
  ```

  Result: passed.

  - ExUnit: `755 tests, 0 failures`
  - Acceptance: `73 scenarios, 489 steps`, all passed

## Remaining gaps / human questions

None for the selected gate issue. No acceptance feature files were edited.