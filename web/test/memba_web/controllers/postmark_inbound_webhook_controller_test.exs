defmodule MembaWeb.PostmarkInboundWebhookControllerTest do
  use MembaWeb.ConnCase, async: false

  import Plug.Conn

  alias Memba.Membership
  alias Memba.Messaging
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

  test "translates parsed Postmark inbound payloads into the provider-neutral inbound email API",
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
             %{recipient_id: ^alice_id, recipient_address: "alice@example.com"},
             %{recipient_id: bob_id, recipient_address: "bob@example.com"}
           ] = Messaging.list_recipient_deliveries(message_id)

    assert bob_id == bob.person_id
    assert length(Fake.deliveries()) == 2
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

    assert_received {:email, %Swoosh.Email{} = rejection_email}
    assert rejection_email.to == [{"", "mystery@example.com"}]
    assert rejection_email.subject == "Your email was not posted"

    assert rejection_email.text_body =~
             "we could not find a member account for your sender address"
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
    club_id = Ecto.UUID.generate()

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
    person_id = Ecto.UUID.generate()

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
                 membership_id: Ecto.UUID.generate(),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
