defmodule MembaWeb.PostmarkWebhookControllerTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailRequest
  alias Memba.Messaging
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Recipient

  import Plug.Conn

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
    end)

    :ok
  end

  test "Postmark outbound member-message payload metadata correlates delivery-status webhooks",
       %{conn: conn} do
    body = "Hello <Alice> & Bob\nBring route ideas."

    %{sender: sender, recipients: [_bob, alice]} =
      message = send_message_to(["Bob Barker", "Alice Adams"], body: body)

    assert :ok = Postmark.deliver(email_delivery_request(message, alice, sender))
    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Bob Barker", "bob.barker@example.test"}
    assert email.to == [{"Alice Adams", "alice.adams@example.test"}]
    assert email.subject == "Trip planning night"
    assert email.text_body == body

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "Members message"
    assert email.html_body =~ "Bob Barker"
    assert email.html_body =~ "Trip planning night"
    assert email.html_body =~ "Hello &lt;Alice&gt; &amp; Bob<br>\nBring route ideas."
    assert email.html_body =~ "Reply to this email and it goes straight to"
    assert email.html_body =~ "Delivered for Your group by"
    refute email.html_body =~ "<Alice>"

    assert metadata = email.provider_options[:metadata]

    assert metadata == %{
             "memba_club_id" => message.club_id,
             "memba_delivery_id" => alice.delivery_id,
             "memba_message_id" => message.message_id
           }

    conn =
      conn
      |> post_postmark_event(
        :delivered
        |> realistic_postmark_payload(message, alice)
        |> Map.put("Metadata", metadata)
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message.message_id, alice.person_id).status ==
               "delivered"

      assert Messaging.get_memba_staff_email_delivery(alice.delivery_id).status == "delivered"
    end)
  end

  test "maps realistic Postmark delivery events with outbound metadata and rejects opens", %{
    conn: conn
  } do
    %{message_id: message_id, recipients: [bob]} = message = send_message_to(["Bob"])

    conn =
      post_postmark_event(conn, realistic_postmark_payload(:delivered, message, bob))

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"
      assert Messaging.get_memba_staff_email_delivery(bob.delivery_id).status == "delivered"
    end)

    conn =
      conn
      |> recycle()
      |> post_postmark_event(realistic_postmark_payload(:opened, message, bob))

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Unsupported Postmark webhook RecordType"

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "delivered"

      assert Messaging.get_memba_staff_email_delivery(message_id, bob.person_id).status ==
               "delivered"
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
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, bob.person_id).status ==
               "delayed"

      assert Messaging.get_memba_staff_email_delivery(message_id, bob.person_id).reason ==
               "recipient server is temporarily unavailable"

      assert Messaging.get_memba_staff_email_delivery(bob.delivery_id).status == "delayed"
    end)

    conn =
      conn
      |> recycle()
      |> post_postmark_event(
        realistic_postmark_payload(:bounced, message, carol, reason: "mailbox does not exist")
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, carol.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).status ==
               "bounced"

      assert Messaging.get_memba_staff_email_delivery(message_id, carol.person_id).reason ==
               "mailbox does not exist"

      assert Messaging.get_memba_staff_email_delivery(carol.delivery_id).status == "bounced"
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
      assert Messaging.get_member_email_delivery(message_id, dana.person_id).status ==
               "delivery problem"

      assert Messaging.get_memba_staff_email_delivery(message_id, dana.person_id).status ==
               "spam complaint"

      assert Messaging.get_memba_staff_email_delivery(message_id, dana.person_id).reason ==
               "recipient marked the message as spam"

      assert Messaging.get_memba_staff_email_delivery(dana.delivery_id).status == "spam complaint"
    end)
  end

  test "routes auth-stream delivered events to auth-email progress", %{conn: conn} do
    {:ok, %AuthEmailRequest{} = request} = sent_auth_email_request()

    conn = post_postmark_event(conn, realistic_auth_postmark_payload(:delivered, request))

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %AuthEmailRequest{} =
             updated_request =
             Accounts.get_auth_email_request(request.request_id)

    assert updated_request.status == "provider_accepted"
    assert updated_request.provider == "postmark"
    assert updated_request.provider_message_stream == "outbound-authentication"
    assert updated_request.provider_message_id == "postmark-auth-message-123"
    assert updated_request.provider_event_id == "postmark-auth-message-123"
    assert updated_request.provider_event_type == "Delivery"
  end

  test "routes auth-stream delayed, bounced, and spam complaint events to auth-email progress",
       %{conn: conn} do
    {:ok, delayed_request} = sent_auth_email_request()
    {:ok, bounced_request} = sent_auth_email_request()
    {:ok, spam_request} = sent_auth_email_request()

    conn =
      post_postmark_event(
        conn,
        realistic_auth_postmark_payload(:delayed, delayed_request,
          reason: "recipient server is temporarily unavailable"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %AuthEmailRequest{} =
             updated_delayed_request =
             Accounts.get_auth_email_request(delayed_request.request_id)

    assert updated_delayed_request.status == "provider_delayed"
    assert updated_delayed_request.provider_event_type == "Bounce"

    assert updated_delayed_request.provider_reason ==
             "recipient server is temporarily unavailable"

    conn =
      conn
      |> recycle()
      |> post_postmark_event(
        realistic_auth_postmark_payload(:bounced, bounced_request,
          reason: "mailbox does not exist"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %AuthEmailRequest{} =
             updated_bounced_request =
             Accounts.get_auth_email_request(bounced_request.request_id)

    assert updated_bounced_request.status == "provider_failed"
    assert updated_bounced_request.provider_event_type == "Bounce"
    assert updated_bounced_request.provider_reason == "mailbox does not exist"

    conn =
      conn
      |> recycle()
      |> post_postmark_event(
        realistic_auth_postmark_payload(:spam_complaint, spam_request,
          reason: "recipient marked the message as spam"
        )
      )

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %AuthEmailRequest{} =
             updated_spam_request =
             Accounts.get_auth_email_request(spam_request.request_id)

    assert updated_spam_request.status == "provider_failed"
    assert updated_spam_request.provider_event_type == "SpamComplaint"
    assert updated_spam_request.provider_reason == "recipient marked the message as spam"
  end

  test "ignores auth-stream events with missing request correlation", %{conn: conn} do
    {:ok, %AuthEmailRequest{} = request} = sent_auth_email_request()

    payload =
      :delivered
      |> realistic_auth_postmark_payload(request)
      |> put_in(["Metadata"], %{})

    conn = post_postmark_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %AuthEmailRequest{} =
             unchanged_request =
             Accounts.get_auth_email_request(request.request_id)

    assert unchanged_request.status == "sent"
    refute unchanged_request.provider_reported_at
  end

  test "rejects Postmark open events before delivered events", %{conn: conn} do
    %{message_id: message_id, recipients: [bob, carol]} =
      message = send_message_to(["Bob", "Carol"])

    conn = post_postmark_event(conn, realistic_postmark_payload(:opened, message, bob))

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Unsupported Postmark webhook RecordType"

    opened_payload =
      :opened
      |> realistic_postmark_payload(message, carol)
      |> Map.put("RecordType", "Opened")

    conn =
      conn
      |> recycle()
      |> post_postmark_event(opened_payload)

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Unsupported Postmark webhook RecordType"

    assert_eventually(fn ->
      assert Messaging.get_member_email_delivery(message_id, bob.person_id).status == "sent"
      assert Messaging.get_memba_staff_email_delivery(bob.delivery_id).status == "sent"

      assert Messaging.get_member_email_delivery(message_id, carol.person_id).status == "sent"
      assert Messaging.get_memba_staff_email_delivery(carol.delivery_id).status == "sent"
    end)
  end

  test "returns an unprocessable response for unsupported Postmark events", %{conn: conn} do
    conn =
      post_postmark_event(conn, %{
        "RecordType" => "SubscriptionChange",
        "Metadata" => %{
          "message_id" => Memba.ID.generate(:message),
          "delivery_id" => Memba.ID.generate(:delivery)
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

  defp sent_auth_email_request do
    {:ok, request} =
      Accounts.create_auth_email_request(%{
        recipient_email: "alice@example.test"
      })

    Accounts.mark_auth_email_sent(request.request_id, %{
      provider: "postmark",
      provider_message_id: "postmark-auth-message-123",
      provider_message_stream: "outbound-authentication"
    })
  end

  defp send_message_to(names, opts \\ []) do
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
    subject = Keyword.get(opts, :subject, "Trip planning night")
    body = Keyword.get(opts, :body, "Bring route ideas.")

    assert :ok =
             MessagingApp.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender.person_id,
                 subject: subject,
                 body: body,
                 recipients: recipients
               },
               consistency: :strong
             )

    %{
      body: body,
      club_id: club_id,
      message_id: message_id,
      recipients: recipients,
      sender: sender,
      subject: subject
    }
  end

  defp email_delivery_request(message, recipient, sender) do
    %EmailDeliveryRequest{
      message_id: message.message_id,
      club_id: message.club_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_address: recipient.email,
      sender_name: sender.name,
      sender_address: sender.email,
      channel: :email,
      subject: message.subject,
      body: message.body
    }
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

  defp realistic_auth_postmark_payload(event_type, request, opts \\ []) do
    recipient = %{
      email: request.recipient_email || "alice@example.test"
    }

    base =
      %{
        "MessageID" => "postmark-auth-message-123",
        "MessageStream" => "outbound-authentication",
        "Metadata" => %{
          "memba_auth_email_request_id" => request.request_id
        },
        "Recipient" => recipient.email,
        "ServerID" => 12_345,
        "Tag" => "auth-email"
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

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
