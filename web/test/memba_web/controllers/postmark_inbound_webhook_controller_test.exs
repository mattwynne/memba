defmodule MembaWeb.PostmarkInboundWebhookControllerTest do
  use MembaWeb.ConnCase, async: false

  import Plug.Conn

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()

    previous_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, previous_provider)
      Fake.reset()
    end)

    :ok
  end

  test "translates accepted primary-address Postmark payloads into the provider-neutral inbound email API",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-accepted",
        "From" => "Alice Example <Alice@Example.COM>",
        "FromFull" => %{"Email" => "Alice@Example.COM", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night",
        "TextBody" => "Bring route ideas.",
        "HtmlBody" => "<p>Bring route ideas.</p>",
        "Headers" => [%{"Name" => "Message-ID", "Value" => "<postmark-controller@example.com>"}]
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-accepted",
             provider_event_id: nil,
             status: "accepted",
             club_id: kmc_id,
             sender_id: alice_id,
             message_id: message_id
           } = Messaging.get_inbound_email_source("postmark", "postmark-controller-accepted")

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

  test "accepts Postmark inbound email from an alternate sender address", %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice =
      create_person!(
        name: "Alice Example",
        email: "alice@example.com",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "Alice.Work@Example.COM", is_primary: false}
        ]
      )

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-alternate-sender",
        "From" => "Alice Work <Alice.Work@Example.COM>",
        "FromFull" => %{"Email" => "Alice.Work@Example.COM", "Name" => "Alice Work"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Alternate sender address",
        "TextBody" => "Posting from my work address."
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-alternate-sender",
             status: "accepted",
             from_address: "alice.work@example.com",
             to_address: "kmc@clubs.memba.io",
             club_id: kmc_id,
             sender_id: alice_id,
             message_id: message_id
           } =
             Messaging.get_inbound_email_source(
               "postmark",
               "postmark-controller-alternate-sender"
             )

    assert kmc_id == kmc.club_id
    assert alice_id == alice.person_id

    assert %{
             message_id: ^message_id,
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             subject: "Alternate sender address",
             body: "Posting from my work address."
           } = Messaging.get_message(message_id)

    assert [
             %{
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               status: "pending"
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert Fake.deliveries() == []

    assert [%{status: "sent"}] = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    assert [
             %{
               recipient_id: ^alice_id,
               recipient_address: "alice@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               subject: "Alternate sender address",
               body: "Posting from my work address."
             }
           ] = Fake.deliveries()
  end

  test "uses provider-neutral inbound handling for Postmark rejection outcomes", %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-unknown-sender",
        "From" => "Mystery Sender <mystery@example.com>",
        "FromFull" => %{"Email" => "mystery@example.com", "Name" => "Mystery Sender"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Can I post?",
        "TextBody" => "Please post this."
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-unknown-sender",
             provider_event_id: nil,
             from_address: "mystery@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "unknown_sender",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source("postmark", "postmark-controller-unknown-sender")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "mystery@example.com",
      reason: "We couldn't find a member account for this email address"
    )
  end

  test "rejects Postmark inbound emails with attachments and does not duplicate rejection emails on retry",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-attachment-rejected",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night",
        "TextBody" => "See the attached route.",
        "Attachments" => [
          %{
            "Name" => "route.gpx",
            "ContentType" => "application/gpx+xml",
            "ContentLength" => "1234",
            "ContentID" => "route-file"
          }
        ]
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-attachment-rejected",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source(
               "postmark",
               "postmark-controller-attachment-rejected"
             )

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "Emails with attachments can't be posted yet"
    )

    retry_payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-attachment-rejected",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Retry without attachment",
        "TextBody" => "This retry must not send another rejection email."
      })

    conn =
      conn
      |> recycle()
      |> post_postmark_inbound_event(retry_payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    refute_received {:email, %Swoosh.Email{}}

    assert %{
             status: "rejected",
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: ^rejection_email_delivery_reference
           } =
             Messaging.get_inbound_email_source(
               "postmark",
               "postmark-controller-attachment-rejected"
             )
  end

  test "rejects Postmark HTML-only inbound emails through the shared plain-text rule",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-html-only",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night",
        "HtmlBody" => "<p>This HTML must not be converted into a club message.</p>"
      })
      |> Map.delete("TextBody")

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-html-only",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("postmark", "postmark-controller-html-only")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't read a plain-text message body"
    )
  end

  test "rejects Postmark inbound emails whose plain text has no usable content",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-quoted-only",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night",
        "TextBody" => "  \n> quoted prior content only\n",
        "HtmlBody" => "<p>This HTML must not be converted into a club message.</p>"
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()

    assert %{
             provider: "postmark",
             provider_message_id: "postmark-controller-quoted-only",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: rejection_email_delivery_reference
           } = Messaging.get_inbound_email_source("postmark", "postmark-controller-quoted-only")

    assert is_binary(rejection_email_delivery_reference)

    assert_rejection_email_received(
      to: "alice@example.com",
      reason: "We couldn't read a plain-text message body"
    )
  end

  test "uses Postmark MessageID for retry idempotency without duplicate messages or deliveries",
       %{conn: conn} do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-duplicate",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night",
        "TextBody" => "Bring route ideas."
      })

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"status" => "accepted"} = json_response(conn, 202)
    assert Fake.deliveries() == []

    assert [%{status: "sent"}, %{status: "sent"}] =
             EmailDeliveryDispatcher.dispatch_pending_email_deliveries()

    first_deliveries = Fake.deliveries()
    assert length(first_deliveries) == 2

    retry_payload =
      valid_payload(%{
        "MessageID" => "postmark-controller-duplicate",
        "From" => "Alice Example <alice@example.com>",
        "FromFull" => %{"Email" => "alice@example.com", "Name" => "Alice Example"},
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "To" => "KMC <kmc@clubs.memba.io>",
        "Subject" => "Trip planning night retry",
        "TextBody" => "This retry must not create another message."
      })

    conn =
      conn
      |> recycle()
      |> post_postmark_inbound_event(retry_payload)

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
             provider: "postmark",
             provider_message_id: "postmark-controller-duplicate",
             provider_event_id: nil,
             status: "accepted"
           } = Messaging.get_inbound_email_source("postmark", "postmark-controller-duplicate")
  end

  test "returns unprocessable for malformed Postmark inbound payloads", %{conn: conn} do
    payload = Map.delete(valid_payload(), "MessageID")

    conn = post_postmark_inbound_event(conn, payload)

    assert %{"errors" => %{"detail" => detail}} = json_response(conn, 422)
    assert detail =~ "Missing required Postmark inbound webhook attribute: MessageID"
  end

  defp post_postmark_inbound_event(conn, payload) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(~p"/webhooks/postmark/inbound", Jason.encode!(payload))
  end

  defp valid_payload(overrides \\ %{}) do
    Map.merge(
      %{
        "MessageID" => "postmark-controller-message",
        "MessageStream" => "inbound",
        "From" => "Alice Example <alice@example.com>",
        "To" => "KMC <kmc@clubs.memba.io>",
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "Subject" => "Trip planning night",
        "TextBody" => "Bring route ideas."
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

    create_attrs =
      attrs
      |> Keyword.take([:email, :email_addresses])
      |> Map.new()
      |> Map.merge(%{
        person_id: person_id,
        name: Keyword.fetch!(attrs, :name)
      })

    assert :ok =
             Membership.create_person(create_attrs, consistency: :strong)

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

  defp assert_rejection_email_received(opts) do
    to_address = Keyword.fetch!(opts, :to)
    reason = Keyword.fetch!(opts, :reason)

    assert_received {:email, %Swoosh.Email{} = rejection_email}
    assert rejection_email.to == [{"", to_address}]

    assert rejection_email.subject in [
             "Your email wasn't posted",
             "Your email to Kootenay Mountaineering Club wasn't posted",
             "Re: Trip planning night"
           ]

    assert rejection_email.text_body =~ reason

    rejection_email
  end
end
