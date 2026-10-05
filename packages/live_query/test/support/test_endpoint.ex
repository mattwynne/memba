defmodule LiveQuery.TestEndpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :live_query

  @session_options [
    store: :cookie,
    key: "_live_query_test",
    signing_salt: "live-query-test"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
end
