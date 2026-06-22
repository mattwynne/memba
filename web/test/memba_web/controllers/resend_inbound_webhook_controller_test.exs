defmodule MembaWeb.ResendInboundWebhookControllerTest do
  use MembaWeb.ConnCase, async: false

  import Plug.Conn

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()

    previous_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    previous_config = Application.get_env(:memba, MembaWeb.ResendWebhookSignature, :unset)

    previous_received_email_config =
      Application.get_env(:memba, MembaWeb.ResendReceivedEmail, :unset)

    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Application.delete_env(:memba, MembaWeb.ResendWebhookSignature)

    Application.put_env(:memba, MembaWeb.ResendReceivedEmail,
      client: MembaWeb.Support.ResendReceivedEmailClient
    )

    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, previous_provider)

      case previous_config do
        :unset -> Application.delete_env(:memba, MembaWeb.ResendWebhookSignature)
        config -> Application.put_env(:memba, MembaWeb.ResendWebhookSignature, config)
      end

      case previous_received_email_config do
        :unset -> Application.delete_env(:memba, MembaWeb.ResendReceivedEmail)
        config -> Application.put_env(:memba, MembaWeb.ResendReceivedEmail, config)
      end

      Fake.reset()
    end)

    :ok
  end

  test "accepts unsigned parseable Resend inbound webhook payloads when no signing secret is configured",
       %{conn: conn} do
    conn = post_resend_inbound_event(conn, valid_payload())

    assert %{"status" => "accepted"} = json_response(conn, 202)
  end

  test "translates parsed Resend payloads into the provider-neutral inbound email API",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    payload =
      valid_payload(%{
        "id" => "evt_controller_accepted",
        "data" => %{
          "email_id" => "email_controller_accepted",
          "from" => "Alice Example <Alice@Example.COM>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night",
          "text" => "Bring route ideas."
        }
      })

    conn = post_resend_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %{
             provider: "resend",
             provider_message_id: "email_controller_accepted",
             provider_event_id: "evt_controller_accepted",
             status: "accepted",
             club_id: kmc_id,
             sender_id: alice_id,
             message_id: message_id
           } = Messaging.get_inbound_email_source("resend", "email_controller_accepted")

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id

    assert %{
             message_id: ^message_id,
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             subject: "Trip planning night",
             body: "Bring route ideas."
           } = Messaging.get_message(message_id)

    assert [
             %{
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               status: "pending"
             },
             %{recipient_id: bob_id, recipient_address: "bob@example.com", status: "pending"}
           ] = Messaging.list_recipient_deliveries(message_id)

    assert bob_id == bob.person_id
    assert Fake.deliveries() == []

    assert [%{status: "sent"}, %{status: "sent"}] =
             EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert length(Fake.deliveries()) == 2
  end

  test "handles provider retries without duplicate accepted messages or outbound deliveries", %{
    conn: conn
  } do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    payload =
      valid_payload(%{
        "id" => "evt_controller_duplicate_first",
        "data" => %{
          "email_id" => "email_controller_duplicate",
          "from" => "Alice Example <alice@example.com>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night",
          "text" => "Bring route ideas."
        }
      })

    conn = post_resend_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert Fake.deliveries() == []

    assert [%{status: "sent"}, %{status: "sent"}] =
             EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    first_deliveries = Fake.deliveries()
    assert length(first_deliveries) == 2

    retry_payload =
      valid_payload(%{
        "id" => "evt_controller_duplicate_retry",
        "data" => %{
          "email_id" => "email_controller_duplicate",
          "from" => "Alice Example <alice@example.com>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night retry",
          "text" => "This retry must not create another message."
        }
      })

    conn =
      conn
      |> recycle()
      |> post_resend_inbound_event(retry_payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert [
             %{
               club_id: kmc_id,
               sender_id: alice_id,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] = Messaging.list_messages_for_club(kmc.club_id)

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id
    assert [] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    assert Fake.deliveries() == first_deliveries

    assert %{
             provider: "resend",
             provider_message_id: "email_controller_duplicate",
             provider_event_id: "evt_controller_duplicate_first",
             status: "accepted"
           } = Messaging.get_inbound_email_source("resend", "email_controller_duplicate")
  end

  test "records rejection paths and does not send duplicate rejection emails on provider retries",
       %{
         conn: conn
       } do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "id" => "evt_controller_attachment_rejected",
        "data" => %{
          "email_id" => "email_controller_attachment_rejected",
          "from" => "Alice Example <alice@example.com>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night",
          "text" => "See the attached route.",
          "attachments" => [
            %{
              "filename" => "route.gpx",
              "content_type" => "application/gpx+xml",
              "size" => "1234"
            }
          ]
        }
      })

    conn = post_resend_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()

    assert %{
             provider: "resend",
             provider_message_id: "email_controller_attachment_rejected",
             provider_event_id: "evt_controller_attachment_rejected",
             from_address: "alice@example.com",
             to_address: "everyone@kmc.clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source(
               "resend",
               "email_controller_attachment_rejected"
             )

    assert is_binary(rejection_email_delivery_reference)

    assert_received {:email, %Swoosh.Email{} = rejection_email}
    assert rejection_email.to == [{"", "alice@example.com"}]

    assert rejection_email.subject in [
             "Your email wasn't posted",
             "Your email to Kootenay Mountaineering Club wasn't posted",
             "Re: Trip planning night"
           ]

    assert rejection_email.text_body =~ "Emails with attachments can't be posted yet"

    retry_payload =
      valid_payload(%{
        "id" => "evt_controller_attachment_rejected_retry",
        "data" => %{
          "email_id" => "email_controller_attachment_rejected",
          "from" => "Alice Example <alice@example.com>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Retry without attachment",
          "text" => "This retry must not send another rejection."
        }
      })

    conn =
      conn
      |> recycle()
      |> post_resend_inbound_event(retry_payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    refute_received {:email, %Swoosh.Email{}}

    assert %{
             provider_event_id: "evt_controller_attachment_rejected",
             status: "rejected",
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: ^rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source(
               "resend",
               "email_controller_attachment_rejected"
             )
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

  test "fetches received email content when real Resend inbound webhooks omit the body", %{
    conn: conn
  } do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    payload =
      valid_payload(%{
        "id" => "evt_controller_fetched_content",
        "data" => %{
          "email_id" => "email_fetched_content",
          "from" => "Alice Example <Alice@Example.COM>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night"
        }
      })
      |> update_in(["data"], &Map.delete(&1, "text"))

    conn = post_resend_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %{message_id: message_id} =
             Messaging.get_inbound_email_source("resend", "email_fetched_content")

    assert %{body: "Bring route ideas from fetched content."} = Messaging.get_message(message_id)
  end

  test "accepts valid received email webhooks with no body and records a domain rejection", %{
    conn: conn
  } do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "id" => "evt_controller_no_body",
        "data" => %{
          "email_id" => "email_no_body",
          "from" => "Alice Example <Alice@Example.COM>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night"
        }
      })
      |> update_in(["data"], &Map.delete(&1, "text"))

    conn = post_resend_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %{
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("resend", "email_no_body")

    assert is_binary(rejection_email_delivery_reference)
  end

  test "returns unprocessable when received email content lookup fails", %{conn: conn} do
    payload =
      valid_payload(%{
        "data" => %{
          "email_id" => "api_error",
          "text" => nil
        }
      })

    conn = post_resend_inbound_event(conn, payload)

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Could not retrieve Resend received email content: HTTP 404"
  end

  defp post_resend_inbound_event(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(~p"/webhooks/resend", Jason.encode!(payload))
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
    |> post(~p"/webhooks/resend", body)
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

  defp valid_payload(overrides \\ %{}) do
    deep_merge(
      %{
        "id" => "evt_123",
        "type" => "email.received",
        "data" => %{
          "email_id" => "email_123",
          "from" => "Alice Example <alice@example.com>",
          "to" => ["KMC <everyone@kmc.clubs.memba.io>"],
          "subject" => "Trip planning night",
          "text" => "Bring route ideas."
        }
      },
      overrides
    )
  end

  defp create_club!(attrs) do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{
                 club_id: club_id,
                 name: Keyword.fetch!(attrs, :name),
                 slug: Keyword.fetch!(attrs, :slug)
               },
               consistency: :strong
             )

    Membership.get_club(club_id)
  end

  defp create_person!(attrs) do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.fetch!(attrs, :name),
                 email: Keyword.fetch!(attrs, :email)
               },
               consistency: :strong
             )

    Membership.get_person(person_id)
  end

  defp add_member!(club_id, person_id) do
    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right
end
