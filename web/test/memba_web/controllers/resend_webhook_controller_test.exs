defmodule MembaWeb.ResendWebhookControllerTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  import Plug.Conn

  test "maps realistic Resend delivery events with outbound tags", %{conn: conn} do
    %{message_id: message_id, recipients: [bob]} = message = send_message_to(["Bob"])

    conn = post_resend_event(conn, realistic_resend_payload(:delivered, message, bob))

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"
      assert Messaging.get_memba_staff_email_delivery(bob.delivery_id).status == "delivered"
    end)
  end

  test "maps realistic Resend delayed, bounced, and complaint events with reasons", %{conn: conn} do
    %{message_id: message_id, recipients: [bob, carol, dana]} =
      message = send_message_to(["Bob", "Carol", "Dana"])

    conn =
      post_resend_event(
        conn,
        realistic_resend_payload(:delayed, message, bob,
          reason: "recipient server is temporarily unavailable"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, bob.person_id).status ==
               "delayed"

      assert Messaging.get_memba_staff_email_delivery(message_id, bob.person_id).reason ==
               "recipient server is temporarily unavailable"
    end)

    conn =
      conn
      |> recycle()
      |> post_resend_event(
        realistic_resend_payload(:bounced, message, carol, reason: "mailbox does not exist")
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, carol.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).status ==
               "bounced"

      assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).reason ==
               "mailbox does not exist"
    end)

    conn =
      conn
      |> recycle()
      |> post_resend_event(
        realistic_resend_payload(:spam_complaint, message, dana,
          reason: "recipient marked the message as spam"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, dana.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, dana.person_id).status ==
               "spam complaint"

      assert Messaging.get_memba_staff_email_delivery(message_id, dana.person_id).reason ==
               "recipient marked the message as spam"
    end)
  end

  test "maps Resend events with tag maps", %{conn: conn} do
    %{message_id: message_id, recipients: [bob]} = message = send_message_to(["Bob"])

    payload =
      :delivered
      |> realistic_resend_payload(message, bob)
      |> put_in(["data", "tags"], %{
        "memba_message_id" => message.message_id,
        "memba_delivery_id" => bob.delivery_id,
        "memba_club_id" => message.club_id,
        "memba_email_kind" => "member_message"
      })

    conn = post_resend_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"
    end)
  end

  test "returns an unprocessable response for unsupported Resend events", %{conn: conn} do
    conn =
      post_resend_event(conn, %{
        "type" => "email.clicked",
        "data" => %{
          "tags" =>
            correlation_tags(Ecto.UUID.generate(), Ecto.UUID.generate(), Ecto.UUID.generate())
        }
      })

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Unsupported Resend webhook event type"
  end

  test "accepts signed Resend webhooks when a signing secret is configured", %{conn: conn} do
    configure_resend_webhook_signing_secret()
    %{message_id: message_id, recipients: [bob]} = message = send_message_to(["Bob"])
    payload = realistic_resend_payload(:delivered, message, bob)

    conn = post_signed_resend_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"
    end)
  end

  test "rejects unsigned Resend webhooks when a signing secret is configured", %{conn: conn} do
    configure_resend_webhook_signing_secret()
    %{recipients: [bob]} = message = send_message_to(["Bob"])

    conn = post_resend_event(conn, realistic_resend_payload(:delivered, message, bob))

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 401)
    assert detail =~ "Missing Resend webhook signature header"
  end

  test "rejects incorrectly signed Resend webhooks", %{conn: conn} do
    configure_resend_webhook_signing_secret()
    %{recipients: [bob]} = message = send_message_to(["Bob"])
    payload = realistic_resend_payload(:delivered, message, bob)

    conn = post_signed_resend_event(conn, payload, signature: "v1,not-the-signature")

    assert %{"errors" => %{"detail" => "Invalid Resend webhook signature"}} =
             json_response(conn, 401)
  end

  defp post_resend_event(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(~p"/webhooks/resend", Jason.encode!(payload))
  end

  defp post_signed_resend_event(conn, payload, opts \\ []) do
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
    |> post(~p"/webhooks/resend", body)
  end

  defp send_message_to(names) do
    [sender | _rest] =
      recipients =
      Enum.map(names, fn name ->
        %Recipient{
          delivery_id: Memba.ID.generate(:delivery),
          person_id: Memba.ID.generate(:person),
          name: name,
          email: email_for(name)
        }
      end)

    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    %{club_id: club_id, message_id: message_id, recipients: recipients}
  end

  defp realistic_resend_payload(event_type, message, recipient, opts \\ []) do
    %{
      "created_at" => "2026-06-01T19:12:34Z",
      "data" => Map.merge(resend_data(message, recipient), event_data(event_type, opts)),
      "type" => resend_event_type(event_type)
    }
  end

  defp resend_data(message, recipient) do
    %{
      "created_at" => "2026-06-01T19:12:00Z",
      "email_id" => "re_123",
      "from" => "messages@mail.memba.io",
      "headers" => [
        %{"name" => "X-Memba-Message-ID", "value" => message.message_id},
        %{"name" => "X-Memba-Delivery-ID", "value" => recipient.delivery_id},
        %{"name" => "X-Memba-Club-ID", "value" => message.club_id}
      ],
      "subject" => "Trip planning night",
      "tags" => correlation_tags(message.message_id, recipient.delivery_id, message.club_id),
      "to" => [recipient.email]
    }
  end

  defp event_data(:delivered, _opts), do: %{}
  defp event_data(_event_type, opts), do: %{"reason" => Keyword.fetch!(opts, :reason)}

  defp resend_event_type(:delivered), do: "email.delivered"
  defp resend_event_type(:delayed), do: "email.delivery_delayed"
  defp resend_event_type(:bounced), do: "email.bounced"
  defp resend_event_type(:spam_complaint), do: "email.complained"

  defp correlation_tags(message_id, delivery_id, club_id) do
    [
      %{"name" => "memba_message_id", "value" => message_id},
      %{"name" => "memba_delivery_id", "value" => delivery_id},
      %{"name" => "memba_club_id", "value" => club_id},
      %{"name" => "memba_email_kind", "value" => "member_message"}
    ]
  end

  defp configure_resend_webhook_signing_secret do
    Application.put_env(:memba, MembaWeb.ResendWebhookSignature,
      signing_secret: test_signing_secret()
    )

    on_exit(fn -> Application.delete_env(:memba, MembaWeb.ResendWebhookSignature) end)
  end

  defp signature(svix_id, svix_timestamp, body) do
    secret = test_signing_secret() |> String.replace_prefix("whsec_", "") |> Base.decode64!()
    signed_content = [svix_id, svix_timestamp, body] |> Enum.join(".")
    "v1," <> Base.encode64(:crypto.mac(:hmac, :sha256, secret, signed_content))
  end

  defp test_signing_secret do
    "whsec_" <> Base.encode64("test-signing-secret")
  end

  defp email_for(name) do
    name
    |> String.downcase()
    |> then(&"#{&1}@example.com")
  end
end
