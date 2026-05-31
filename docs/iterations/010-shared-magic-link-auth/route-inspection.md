# Route/admin inspection

Selected todo: `001 Inspect the post-iteration-009 route structure and admin pipeline.`

## Findings

- Current Phoenix routes still expose the browser harness at public paths:
  - `GET /clubs` -> `MembaWeb.ClubsLive.Index`
  - `GET /clubs/:club_id` -> `MembaWeb.ClubsLive.Show`
  - `GET /deliveries` -> `MembaWeb.DeliveriesLive.Index`
  - `GET /messages/:message_id` -> `MembaWeb.MessagesLive.Show`
- There is no `/admin` scope, no `:staff_browser` pipeline, and no `MembaWeb.Admin.*` LiveView namespace in the current codebase.
- The public controller routes are `GET /`, `/about`, `/terms`, and `/privacy` through the `:browser` pipeline.
- `POST /webhooks/postmark` remains routed through the `:api` pipeline to `MembaWeb.PostmarkWebhookController.create/2`.
- The dev-only dashboard/mailbox routes are conditionally mounted under `/dev` when `:dev_routes` is enabled.

## Implication for iteration 010

Iteration 010 assumes the iteration-009 route split already exists so auth gates can protect `/admin/*`. On this branch that prerequisite is absent. Before implementing staff authorization or `/admin/*` gates, the existing harness routes need to be reconciled into an admin surface with a `:staff_browser` seam while preserving the Postmark webhook route.

## Evidence inspected

- `web/lib/memba_web/router.ex`
- `web/lib/memba_web/live/clubs_live/index.ex`
- `web/lib/memba_web/live/clubs_live/show.ex`
- `web/lib/memba_web/live/deliveries_live/index.ex`
- `web/lib/memba_web/live/messages_live/show.ex`
- `web/test/memba_web/router_test.exs`
- `mix phx.routes`
