# Route and admin pipeline inspection

Task: `001 Inspect the post-iteration-009 route structure and admin pipeline.`

## Current route shape

- Public browser routes live in `scope "/", MembaWeb` through `:browser`:
  - `GET /`
  - `GET /about`
  - `GET /terms`
  - `GET /privacy`
- Staff/admin LiveView routes live in `scope "/admin", MembaWeb.Admin` through `:staff_browser`:
  - `GET /admin/clubs` -> `MembaWeb.Admin.ClubsLive.Index`
  - `GET /admin/clubs/:club_id` -> `MembaWeb.Admin.ClubsLive.Show`
  - `GET /admin/deliveries` -> `MembaWeb.Admin.DeliveriesLive.Index`
  - `GET /admin/messages/:message_id` -> `MembaWeb.Admin.MessagesLive.Show`
- Webhook routes live in `scope "/webhooks", MembaWeb` through `:api`:
  - `POST /webhooks/postmark` -> `MembaWeb.PostmarkWebhookController.create/2`

`mix phx.routes` confirms the same route table after iteration 009.

## Current admin pipeline

`MembaWeb.Router` defines `:staff_browser` separately from `:browser`, but today it contains the same plugs:

- `:accepts, ["html"]`
- `:fetch_session`
- `:fetch_live_flash`
- `:put_root_layout, html: {MembaWeb.Layouts, :root}`
- `:protect_from_forgery`
- `:put_secure_browser_headers`

There is no existing auth plug, current-user assign, staff-domain check, or LiveView `on_mount` hook. The separate pipeline is therefore the seam for the iteration 010 staff gate: later tasks can add shared session fetching and a staff requirement to `:staff_browser` without moving the `/admin/*` routes.

## Current admin surface

- Admin LiveViews render with `Layouts.admin`.
- Admin modules already live under the `MembaWeb.Admin.*` namespace.
- The public marketing home page currently links directly to `/admin/clubs`; later home-page work should replace that always-visible internal staff link with signed-in/staff-aware navigation.

## Constraints for later tasks

- Keep `POST /webhooks/postmark` on the `:api` pipeline unchanged.
- Add `/auth` routes under the public browser surface, not under `/admin`.
- When protecting `/admin/*`, preserve the existing `scope "/admin", MembaWeb.Admin` aliasing so route modules remain `MembaWeb.Admin.*`.
- Browser sessions are already cookie-backed via `MembaWeb.Endpoint` and fetched in both browser pipelines.
