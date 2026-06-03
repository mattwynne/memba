defmodule MembaWeb.ResendInboundWebhookControllerTest do
  use MembaWeb.ConnCase, async: false

  import Plug.Conn

  setup do
    previous_config = Application.get_env(:memba, MembaWeb.ResendWebhookSignature, :unset)
    Application.delete_env(:memba, MembaWeb.ResendWebhookSignature)

    on_exit(fn ->
      case previous_config do
        :unset -> Application.delete_env(:memba, MembaWeb.ResendWebhookSignature)
        config -> Application.put_env(:memba, MembaWeb.ResendWebhookSignature, config)
      end
    end)

    :ok
  end

  test "accepts unsigned parseable Resend inbound webhook payloads when no signing secret is configured",
       %{conn: conn} do
    conn = post_resend_inbound_event(conn, valid_payload())

    assert %{"status" => "accepted"} = json_response(conn, 202)
  end

  test "accepts signed Resend inbound webhooks when a signing secret is configured", %{conn: conn} do
    configure_resend_webhook_signing_secret()

    conn = post_signed_resend_inbound_event(conn, valid_payload())

    assert %{"status" => "accepted"} = json_response(conn, 202)
  end

  test "rejects unsigned Resend inbound webhooks when a signing secret is configured", %{
    conn: conn
  } do
    configure_resend_webhook_signing_secret()

    conn = post_resend_inbound_event(conn, valid_payload())

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 401)
    assert detail =~ "Missing Resend webhook signature header"
  end

  test "rejects incorrectly signed Resend inbound webhooks", %{conn: conn} do
    configure_resend_webhook_signing_secret()

    conn =
      post_signed_resend_inbound_event(conn, valid_payload(), signature: "v1,not-the-signature")

    assert %{"errors" => %{"detail" => "Invalid Resend webhook signature"}} =
             json_response(conn, 401)
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

  defp post_signed_resend_inbound_event(conn, payload, opts \\ []) do
    body = Jason.encode!(payload)
    svix_id = Keyword.get(opts, :svix_id, "msg_123")

    svix_timestamp =
      Keyword.get(opts, :svix_timestamp, System.system_time(:second) |> to_string())

    signature =
      Keyword.get_lazy(opts, :signature, fn -> signature(svix_id, svix_timestamp, body) end)

    conn
    |> put_req_header("content-type", "application/json")
    |> put_req_header("svix-id", svix_id)
    |> put_req_header("svix-timestamp", svix_timestamp)
    |> put_req_header("svix-signature", signature)
    |> post(~p"/webhooks/resend/inbound", body)
  end

  defp configure_resend_webhook_signing_secret do
    Application.put_env(:memba, MembaWeb.ResendWebhookSignature,
      signing_secret: test_signing_secret()
    )
  end

  defp signature(svix_id, svix_timestamp, body) do
    secret = test_signing_secret() |> String.replace_prefix("whsec_", "") |> Base.decode64!()
    signed_content = [svix_id, svix_timestamp, body] |> Enum.join(".")
    "v1," <> Base.encode64(:crypto.mac(:hmac, :sha256, secret, signed_content))
  end

  defp test_signing_secret do
    "whsec_" <> Base.encode64("test-signing-secret")
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
