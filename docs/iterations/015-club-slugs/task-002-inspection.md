# Task 002 inspection notes

## Current Membership club write model

- `web/lib/memba/membership/commands/create_club.ex`
  - `Memba.Membership.Commands.CreateClub` currently has enforced keys `[:club_id, :name]` and fields `[:club_id, :name]`.
- `web/lib/memba/membership/events/club_created.ex`
  - `Memba.Membership.Events.ClubCreated` currently has enforced keys `[:club_id, :name]`, fields `[:club_id, :name]`, and derives `Jason.Encoder`.
- `web/lib/memba/membership/club.ex`
  - `Memba.Membership.Club` aggregate state is `%Club{club_id, name}`.
  - `execute/2` for a new aggregate validates the caller-supplied UUID and trims the name, then emits `%ClubCreated{club_id, name}`.
  - `apply/2` copies `club_id` and `name` from `ClubCreated` into aggregate state.
  - Duplicate aggregate creation returns `{:error, :already_created}`.
- `web/lib/memba/membership/router.ex`
  - `Memba.Membership.Router` identifies `Memba.Membership.Club` by `:club_id` and dispatches `CreateClub` to the club aggregate.
- ADR impact:
  - ADR 0002 keeps club behaviour in Commanded commands/aggregates/events.
  - ADR 0011 keeps `club_id` as the caller-generated UUID aggregate identity; slug must be an addressable attribute, not the aggregate identity.

## Current Membership club read model and projection

- `web/lib/memba/membership/projections/club.ex`
  - `Memba.Membership.Projections.Club` maps table `membership_clubs`.
  - Primary key is `club_id`; only projected field is `name`.
- `web/lib/memba/membership/projectors/club.ex`
  - `Memba.Membership.Projectors.Club` uses `Commanded.Projections.Ecto` with `Memba.Membership.App`, `Memba.Repo`, name `"Memba.Membership.Projectors.Club"`, and `consistency: :strong`.
  - It inserts `%ClubProjection{club_id, name}` for `ClubCreated`.
- `web/priv/repo/migrations/20260528220214_create_membership_clubs_projection.exs`
  - Creates `membership_clubs(club_id uuid primary key, name text not null, inserted_at, updated_at)`.
  - There is no `slug` column or index yet.
- Test reset/config code that knows about `membership_clubs`:
  - `web/config/config.exs` includes `:membership_clubs` in `:event_sourced_projection_tables`.
  - `web/test/support/event_sourced_case.ex` truncates configured projection tables.
  - `web/test/event_sourced_setup_test.exs` asserts the table exists and inserts a raw `membership_clubs` row.
- ADR impact:
  - ADR 0009 says projections should continue using `commanded_ecto_projections`.
  - ADR 0008 says tests use the persistent EventStore and reset EventStore/projection tables rather than an in-memory adapter.

## Current Membership public query API

- `web/lib/memba/membership.ex`
  - `create_club/2` builds `%CreateClub{club_id, name}` from atom or string attrs and dispatches through `Memba.Membership.App`.
  - `get_club/1` casts UUID input and `Repo.get/2`s `Memba.Membership.Projections.Club`; invalid input returns `nil`.
  - `list_clubs/0` orders projected clubs by `name` then `club_id`.
  - `list_active_clubs_for_member_email/1` joins memberships, people, and clubs, and orders by `club.name` then `club.club_id`.
  - Active-member APIs and `Memba.Accounts` depend on this public Membership API rather than direct Membership internals.
- There is no `get_club_by_slug/1` or slug availability/validation API yet.
- ADR impact:
  - ADR 0007 requires other contexts such as Messaging to depend on Membership public query APIs, not Membership projection storage details.

## Current public club routing and host handling

- `web/lib/memba_web/router.ex`
  - `GET /` routes through `[:browser, :club_member_context]` to `MembaWeb.PageController.home/2`.
  - There is no host-based route or plug for `*.clubs.memba.io` yet.
  - Authenticated member routes remain query-string `club_id` routes under `/messages/new` and `/messages/:message_id`.
- `web/lib/memba_web/controllers/page_controller.ex`
  - Logged-out `GET /?club_id=...` checks `Membership.get_club/1` and `live_render`s `MembaWeb.ClubMarketingLive` with session `%{"club_id" => club_id}`.
  - Signed-in `GET /?club_id=...` live-renders `MembaWeb.MemberDashboardLive` with the `club_id` and identity email in the LiveView session.
  - Unknown `club_id` on the logged-out public path returns the normal 404 HTML.
- `web/lib/memba_web/live/club_marketing_live.ex`
  - Loads the club by `club_id` in `mount/3`.
  - Renders `#club-marketing-page[data-club-id]` and the existing public marketing page copy.
  - Missing clubs currently navigate to `/` rather than directly rendering a 404 inside the LiveView.
- `web/lib/memba_web/user_auth.ex`
  - `require_active_club_member_if_club_id_present/2` permits logged-out `GET /?club_id=...` public access.
  - Signed-in requests with `club_id` require active membership via `Accounts.active_member_of_club?/2`.
- `web/lib/memba_web/plugs/canonical_host_redirect.ex`
  - Redirects `memba.fly.dev` to `https://memba.io`.
  - It does not redirect `*.clubs.memba.io`.
- `web/config/runtime.exs`
  - Production `PHX_HOST` drives `Endpoint.url` and `check_origin: ["//#{host}", "//*.#{host}"]`.
  - Host-based club routes will need explicit tests because the iteration uses `slug.clubs.memba.io` while ADR 0014 originally mentioned future `*.memba.io` white-label hosts.

## Current staff/admin club UI

- `web/lib/memba_web/router.ex`
  - Staff routes are under `/admin` with `:staff_browser` and LiveView `:staff_admin`.
  - Current club routes are `/admin/clubs` and `/admin/clubs/:club_id`.
- `web/lib/memba_web/live/admin/clubs_live/index.ex`
  - The create form only has a club name field.
  - `handle_event("create_club", ...)` takes `name`, generates a `club_id`, and calls `Membership.create_club(attrs, consistency: :strong)`.
  - The club list displays `club.name` and `club.club_id`.
  - There is no slug field, suggested slug preview, duplicate feedback, or slug display.
- `web/lib/memba_web/live/admin/clubs_live/show.ex`
  - Loads a club by `club_id`.
  - Shows the club name and manages people, members, and messages.
  - There is no edit form for club name/slug yet.
- `web/test/memba_web/live/browser_acceptance_harness_test.exs`
  - Uses PhoenixTest feature-style coverage of the existing staff admin flow and stable selectors.
  - The helper `create_club/2` fills only "Name" and clicks "Create club".
- ADR impact:
  - ADR 0013 says future web tests should use PhoenixTest for feature-style web behaviour.
  - ADR 0015 applies LiveView by default to member application pages; the staff/admin UI is already LiveView.

## Current club creation call sites to update in later tasks

Application code:

- `web/lib/memba/membership.ex`
  - `create_club_command/1` constructs `%CreateClub{club_id, name}`.
- `web/lib/memba_web/live/admin/clubs_live/index.ex`
  - `handle_event("create_club", ...)` calls `Membership.create_club/2`.

Acceptance/domain step definitions:

- `web/test/features/step_definitions/membership_steps.exs`
  - `create_club/2` dispatches `%CreateClub{club_id, name}` directly and asserts `%ClubProjection{club_id, name}`.
- `web/test/features/step_definitions/authentication_steps.exs`
  - `ensure_club/2` calls `Membership.create_club(%{club_id, name}, consistency: :strong)`.

Membership tests:

- `web/test/memba/membership/club_test.exs`
  - Constructs `CreateClub`, `ClubCreated`, and `Club` structs directly.
- `web/test/memba/membership/create_club_dispatch_test.exs`
  - Dispatches `%CreateClub{club_id, name}` and asserts `ClubCreated`/aggregate state.
- `web/test/memba/membership/club_projection_test.exs`
  - Dispatches `%CreateClub{club_id, name}` and asserts projected club fields.
- `web/test/memba/membership/public_api_test.exs`
  - Calls `Membership.create_club/2` and asserts returned event/projection shape.
- `web/test/memba/membership/query_test.exs`
  - Helper `create_club/1` dispatches `%CreateClub{club_id, name}`.
  - One test directly inserts `%ClubProjection{club_id, name}` for an inactive club.
- `web/test/memba/accounts_test.exs`
  - Calls `Membership.create_club/2`.

Web tests and helper-style direct projection inserts:

- `web/test/memba_web/controllers/page_controller_test.exs`
  - Directly inserts `%Memba.Membership.Projections.Club{club_id, name}` in `create_club/1` and `create_active_member/1`.
- `web/test/memba_web/controllers/member_message_detail_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/controllers/auth_controller_test.exs`
  - Directly inserts a projected club in auth tests.
- `web/test/memba_web/member_dashboard_presentation_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/member_message_detail_loader_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/user_auth_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/auth_gates_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/live/member_dashboard_live_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/live/member_message_live/show_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/live/member_message_live/new_test.exs`
  - Directly inserts projected clubs in local helpers.
- `web/test/memba_web/live/member_message_live/new_send_test.exs`
  - Helper `create_active_member/2` calls `Membership.create_club/2` if the club is missing.

Browser acceptance harness:

- `web/test/memba_web/live/browser_acceptance_harness_test.exs`
  - `create_club/2` drives the staff form by filling only the name.

Other raw SQL:

- `web/test/event_sourced_setup_test.exs`
  - Inserts into `membership_clubs (club_id, name, inserted_at, updated_at)`.

## Acceptance feature state

- `acceptance-tests/features/staff_club_slugs.feature` already exists and remains tagged `@wip`.
- No acceptance feature files were edited for this inspection task.

## Validation commands used for this inspection

- `git log --oneline --decorate -20`
- `git status --short`
- `find web -maxdepth 5 -type f ...`
- `grep -RInE "CreateClub|ClubCreated|create_club|get_club|list_clubs|membership_clubs|club_id" ...`
- `grep -RInE "%ClubProjection\\{|Repo\\.insert!\\(%Club|alias Memba\\.Membership\\.Projections\\.Club" ...`
- Targeted `read_file` inspection of the files named above.
