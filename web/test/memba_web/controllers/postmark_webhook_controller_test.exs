defmodule MembaWeb.PostmarkWebhookControllerTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  import Plug.Conn

  test "maps realistic Postmark delivery and open events with outbound metadata", %{conn: conn} do
    %{message_id: message_id, recipients: [bob]} = message = send_message_to(["Bob"])

    conn =
      post_postmark_event(conn, realistic_postmark_payload(:delivered, message, bob))

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status == "delivered"
      assert Messaging.get_operator_deliverability(bob.delivery_id).status == "delivered"
    end)

    conn =
      conn
      |> recycle()
      |> post_postmark_event(realistic_postmark_payload(:opened, message, bob))

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status == "opened"
      assert Messaging.get_operator_deliverability(message_id, bob.person_id).status == "opened"
    end)
  end

  test "maps realistic Postmark delayed, bounced, and spam complaint events with reasons", %{
    conn: conn
  } do
    %{message_id: message_id, recipients: [bob, carol, dana]} =
      message = send_message_to(["Bob", "Carol", "Dana"])

    conn =
      post_postmark_event(
        conn,
        realistic_postmark_payload(:delayed, message, bob,
          reason: "recipient server is temporarily unavailable"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status ==
               "delivery problem"

      assert Messaging.get_operator_deliverability(message_id, bob.person_id).status == "delayed"

      assert Messaging.get_operator_deliverability(message_id, bob.person_id).reason ==
               "recipient server is temporarily unavailable"

      assert Messaging.get_operator_deliverability(bob.delivery_id).status == "delayed"
    end)

    conn =
      conn
      |> recycle()
      |> post_postmark_event(
        realistic_postmark_payload(:bounced, message, carol, reason: "mailbox does not exist")
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_receipt(message_id, carol.person_id).receipt_status ==
               "delivery problem"

      assert Messaging.get_operator_deliverability(message_id, carol.person_id).status ==
               "bounced"

      assert Messaging.get_operator_deliverability(message_id, carol.person_id).reason ==
               "mailbox does not exist"

      assert Messaging.get_operator_deliverability(carol.delivery_id).status == "bounced"
    end)

    conn =
      conn
      |> recycle()
      |> post_postmark_event(
        realistic_postmark_payload(:spam_complaint, message, dana,
          reason: "recipient marked the message as spam"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_receipt(message_id, dana.person_id).receipt_status ==
               "delivery problem"

      assert Messaging.get_operator_deliverability(message_id, dana.person_id).status ==
               "spam complaint"

      assert Messaging.get_operator_deliverability(message_id, dana.person_id).reason ==
               "recipient marked the message as spam"

      assert Messaging.get_operator_deliverability(dana.delivery_id).status == "spam complaint"
    end)
  end

  test "returns an unprocessable response for unsupported Postmark events", %{conn: conn} do
    conn =
      post_postmark_event(conn, %{
        "RecordType" => "SubscriptionChange",
        "Metadata" => %{
          "message_id" => Ecto.UUID.generate(),
          "delivery_id" => Ecto.UUID.generate()
        }
      })

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Unsupported Postmark webhook RecordType"
  end

  defp post_postmark_event(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(~p"/webhooks/postmark", Jason.encode!(payload))
  end

  defp send_message_to(names) do
    [sender | _rest] =
      recipients =
      Enum.map(names, fn name ->
        %Recipient{
          delivery_id: Ecto.UUID.generate(),
          person_id: Ecto.UUID.generate(),
          name: name,
          email: email_for(name)
        }
      end)

    message_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()

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

  defp realistic_postmark_payload(event_type, message, recipient, opts \\ []) do
    base =
      %{
        "MessageID" => Ecto.UUID.generate(),
        "MessageStream" => "outbound",
        "Metadata" => %{
          "memba_club_id" => message.club_id,
          "memba_delivery_id" => recipient.delivery_id,
          "memba_message_id" => message.message_id
        },
        "Recipient" => recipient.email,
        "ServerID" => 12_345,
        "Tag" => "member-message"
      }

    Map.merge(base, realistic_postmark_event_fields(event_type, recipient, opts))
  end

  defp realistic_postmark_event_fields(:delivered, _recipient, _opts) do
    %{
      "DeliveredAt" => "2026-05-30T19:12:34Z",
      "Details" => "smtp; 250 2.0.0 Ok: queued as 12345",
      "RecordType" => "Delivery"
    }
  end

  defp realistic_postmark_event_fields(:opened, _recipient, _opts) do
    %{
      "Client" => %{"Company" => "Apple", "Family" => "Apple Mail", "Name" => "Apple Mail"},
      "FirstOpen" => true,
      "Geo" => %{
        "City" => "Nelson",
        "CountryISOCode" => "CA",
        "CountryName" => "Canada",
        "Region" => "British Columbia"
      },
      "OS" => %{"Company" => "Apple", "Family" => "iOS", "Name" => "iOS"},
      "Platform" => "Mobile",
      "ReadSeconds" => 7,
      "ReceivedAt" => "2026-05-30T19:13:45Z",
      "RecordType" => "Open",
      "UserAgent" => "Mozilla/5.0"
    }
  end

  defp realistic_postmark_event_fields(:delayed, recipient, opts) do
    bounce_fields(recipient, opts,
      description: "Temporary delivery issue",
      name: "Delivery delayed",
      type: "Transient",
      type_code: 4
    )
  end

  defp realistic_postmark_event_fields(:bounced, recipient, opts) do
    bounce_fields(recipient, opts,
      description: Keyword.fetch!(opts, :reason),
      name: "Hard bounce",
      type: "HardBounce",
      type_code: 1
    )
  end

  defp realistic_postmark_event_fields(:spam_complaint, recipient, opts) do
    %{
      "BouncedAt" => "2026-05-30T19:14:56Z",
      "Description" => "The recipient marked this message as spam.",
      "Details" => Keyword.fetch!(opts, :reason),
      "Email" => recipient.email,
      "From" => "messages@mail.memba.io",
      "ID" => 3_456_789,
      "Name" => "Spam notification",
      "RecordType" => "SpamComplaint",
      "Subject" => "Trip planning night",
      "Type" => "SpamNotification",
      "TypeCode" => 512
    }
  end

  defp bounce_fields(recipient, opts, event_opts) do
    %{
      "BouncedAt" => "2026-05-30T19:14:56Z",
      "CanActivate" => false,
      "Description" => Keyword.fetch!(event_opts, :description),
      "Details" => Keyword.fetch!(opts, :reason),
      "DumpAvailable" => false,
      "Email" => recipient.email,
      "From" => "messages@mail.memba.io",
      "ID" => 2_345_678,
      "Inactive" => true,
      "Name" => Keyword.fetch!(event_opts, :name),
      "RecordType" => "Bounce",
      "Subject" => "Trip planning night",
      "Type" => Keyword.fetch!(event_opts, :type),
      "TypeCode" => Keyword.fetch!(event_opts, :type_code)
    }
  end

  defp email_for(name) do
    normalized_name =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}@example.test"
  end
end
