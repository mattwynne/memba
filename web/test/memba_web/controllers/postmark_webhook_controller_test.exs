defmodule MembaWeb.PostmarkWebhookControllerTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Recipient

  import Plug.Conn

  test "maps Postmark delivery and open events to member receipt status reports", %{conn: conn} do
    %{message_id: message_id, recipients: [bob]} = send_message_to(["Bob"])

    conn =
      post_postmark_event(conn, %{
        "RecordType" => "Delivery",
        "MessageID" => Ecto.UUID.generate(),
        "Recipient" => bob.email,
        "Metadata" => %{
          "message_id" => message_id,
          "delivery_id" => bob.delivery_id
        }
      })

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status == "delivered"

    conn =
      conn
      |> recycle()
      |> post_postmark_event(%{
        "RecordType" => "Open",
        "MessageID" => Ecto.UUID.generate(),
        "Recipient" => bob.email,
        "Metadata" => %{
          "message_id" => message_id,
          "delivery_id" => bob.delivery_id
        }
      })

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status == "opened"
    assert Messaging.get_operator_deliverability(message_id, bob.person_id).status == "opened"
  end

  test "maps Postmark delayed, bounced, and spam complaint events with reasons", %{conn: conn} do
    %{message_id: message_id, recipients: [bob, carol, dana]} =
      send_message_to(["Bob", "Carol", "Dana"])

    conn =
      post_postmark_event(conn, %{
        "RecordType" => "Bounce",
        "Type" => "Transient",
        "Details" => "recipient server is temporarily unavailable",
        "Metadata" => %{
          "message_id" => message_id,
          "delivery_id" => bob.delivery_id
        }
      })

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert Messaging.get_member_receipt(message_id, bob.person_id).receipt_status ==
             "delivery problem"

    assert Messaging.get_operator_deliverability(message_id, bob.person_id).status == "delayed"

    assert Messaging.get_operator_deliverability(message_id, bob.person_id).reason ==
             "recipient server is temporarily unavailable"

    conn =
      conn
      |> recycle()
      |> post_postmark_event(%{
        "RecordType" => "Bounce",
        "Type" => "HardBounce",
        "Description" => "mailbox does not exist",
        "Metadata" => %{
          "message_id" => message_id,
          "delivery_id" => carol.delivery_id
        }
      })

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert Messaging.get_member_receipt(message_id, carol.person_id).receipt_status ==
             "delivery problem"

    assert Messaging.get_operator_deliverability(message_id, carol.person_id).status == "bounced"

    assert Messaging.get_operator_deliverability(message_id, carol.person_id).reason ==
             "mailbox does not exist"

    conn =
      conn
      |> recycle()
      |> post_postmark_event(%{
        "RecordType" => "SpamComplaint",
        "Details" => "recipient marked the message as spam",
        "Metadata" => %{
          "message_id" => message_id,
          "delivery_id" => dana.delivery_id
        }
      })

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert Messaging.get_member_receipt(message_id, dana.person_id).receipt_status ==
             "delivery problem"

    assert Messaging.get_operator_deliverability(message_id, dana.person_id).status ==
             "spam complaint"

    assert Messaging.get_operator_deliverability(message_id, dana.person_id).reason ==
             "recipient marked the message as spam"
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

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: Ecto.UUID.generate(),
                 sender_id: sender.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: recipients
               },
               consistency: :strong
             )

    %{message_id: message_id, recipients: recipients}
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
