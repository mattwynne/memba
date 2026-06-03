defmodule MembaWeb.ResendInboundWebhookControllerTest do
  use MembaWeb.ConnCase, async: true

  import Plug.Conn

  test "accepts parseable Resend inbound webhook payloads", %{conn: conn} do
    conn = post_resend_inbound_event(conn, valid_payload())

    assert %{"status" => "accepted"} = json_response(conn, 202)
  end

  test "returns unprocessable for malformed Resend inbound payloads", %{conn: conn} do
    payload = update_in(valid_payload(), ["data"], &Map.delete(&1, "text"))

    conn = post_resend_inbound_event(conn, payload)

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Missing required Resend inbound webhook attribute: data.text"
  end

  defp post_resend_inbound_event(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(~p"/webhooks/resend/inbound", Jason.encode!(payload))
  end

  defp valid_payload do
    %{
      "id" => "evt_123",
      "type" => "email.received",
      "data" => %{
        "email_id" => "email_123",
        "from" => "Alice Example <alice@example.com>",
        "to" => ["KMC <kmc@clubs.memba.io>"],
        "subject" => "Trip planning night",
        "text" => "Bring route ideas."
      }
    }
  end
end
