defmodule Memba.Messaging.InboundClubMessageAcceptanceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      Fake.reset()
    end)

    :ok
  end

  test "accepted inbound email posts through the same club message and delivery flow as web compose" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    npc = create_club!(name: "Nelson Paddling Club", slug: "npc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")
    pat = create_person!(name: "Pat Example", email: "pat@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)
    add_member!(npc.club_id, pat.person_id)

    assert {:ok,
            %{
              inbound_email_id: "inbound-email:resend:task-011-email",
              message_id: message_id,
              club_id: kmc_id,
              sender_id: alice_id,
              from_address: "alice@example.com",
              to_address: "kmc@clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-011-email",
                 provider_event_id: "task-011-event",
                 from_address: "alice@example.com",
                 recipient_addresses: ["kmc@clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Bring route ideas."
               },
               consistency: :strong
             )

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
               message_id: ^message_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice Example",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "sent"
             },
             %{
               message_id: ^message_id,
               recipient_id: bob_id,
               recipient_name: "Bob Example",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "sent"
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert bob_id == bob.person_id

    assert [
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice Example",
               recipient_address: "alice@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %EmailDeliveryRequest{
               message_id: ^message_id,
               club_id: ^kmc_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob Example",
               recipient_address: "bob@example.com",
               sender_name: "Alice Example",
               sender_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] = Fake.deliveries()

    delivered_recipient_ids = Enum.map(Fake.deliveries(), & &1.recipient_id)
    refute pat.person_id in delivered_recipient_ids

    assert %InboundEmailSourceProjection{
             inbound_email_id: "inbound-email:resend:task-011-email",
             provider: "resend",
             provider_message_id: "task-011-email",
             provider_event_id: "task-011-event",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "accepted",
             club_id: ^kmc_id,
             sender_id: ^alice_id,
             message_id: ^message_id,
             rejection_reason: nil,
             rejection_email_delivery_reference: nil
           } = Messaging.get_inbound_email_source("resend", "task-011-email")
  end

  test "duplicate provider message ids return accepted without creating duplicate messages or outbound deliveries" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")

    alice = create_person!(name: "Alice Example", email: "alice@example.com")
    bob = create_person!(name: "Bob Example", email: "bob@example.com")

    add_member!(kmc.club_id, alice.person_id)
    add_member!(kmc.club_id, bob.person_id)

    inbound_attrs = %{
      provider: "resend",
      provider_message_id: "task-012-duplicate-email",
      provider_event_id: "task-012-event-first",
      from_address: "alice@example.com",
      recipient_addresses: ["kmc@clubs.memba.io"],
      subject: "Trip planning night",
      text_body: "Bring route ideas."
    }

    assert {:ok, %{message_id: message_id}} =
             Messaging.receive_inbound_club_email(inbound_attrs, consistency: :strong)

    first_deliveries = Fake.deliveries()

    assert {:ok,
            %{
              inbound_email_id: "inbound-email:resend:task-012-duplicate-email",
              duplicate?: true,
              status: :accepted,
              message_id: ^message_id
            }} =
             inbound_attrs
             |> Map.merge(%{
               provider_event_id: "task-012-event-retry",
               subject: "Trip planning night retry",
               text_body: "This retry must not be posted."
             })
             |> Messaging.receive_inbound_club_email(consistency: :strong)

    assert [
             %{
               message_id: ^message_id,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] =
             Messaging.list_messages_for_club(kmc.club_id)

    assert Fake.deliveries() == first_deliveries
    assert length(first_deliveries) == 2

    assert %InboundEmailSourceProjection{
             status: "accepted",
             provider_event_id: "task-012-event-first",
             message_id: ^message_id
           } = Messaging.get_inbound_email_source("resend", "task-012-duplicate-email")

    assert 1 == count_events(MessageSent)
    assert 1 == count_events(InboundClubEmailAccepted)
  end

  test "accepted inbound email uses normalized plain text and ignores HTML" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok, %{message_id: message_id}} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-013-normalized-body",
                 from_address: "alice@example.com",
                 recipient_addresses: ["kmc@clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: """
                 Bring route ideas.

                 Meet at 7.

                 -- 
                 Alice

                 On Tue, Bob wrote:
                 > Old message
                 """,
                 html_body: "<p>This HTML must not be converted or posted.</p>"
               },
               consistency: :strong
             )

    assert %{body: "Bring route ideas.\n\nMeet at 7."} = Messaging.get_message(message_id)

    assert [
             %EmailDeliveryRequest{
               body: "Bring route ideas.\n\nMeet at 7."
             }
           ] = Fake.deliveries()
  end

  test "inbound email without usable plain text is rejected without creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: "inbound-email:resend:task-013-html-only",
              status: :rejected,
              rejection_reason: "plain_text_required",
              from_address: "alice@example.com",
              to_address: "kmc@clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-013-html-only",
                 from_address: "alice@example.com",
                 recipient_addresses: ["kmc@clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "  \n> quoted prior content only\n",
                 html_body: "<p>This HTML must not be converted.</p>"
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             inbound_email_id: "inbound-email:resend:task-013-html-only",
             provider: "resend",
             provider_message_id: "task-013-html-only",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "plain_text_required",
             rejection_email_delivery_reference: nil
           } = Messaging.get_inbound_email_source("resend", "task-013-html-only")
  end

  test "inbound email with attachments is rejected before creating a club message" do
    kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    alice = create_person!(name: "Alice Example", email: "alice@example.com")

    add_member!(kmc.club_id, alice.person_id)

    assert {:ok,
            %{
              inbound_email_id: "inbound-email:resend:task-014-attachments",
              status: :rejected,
              rejection_reason: "attachments_not_supported",
              from_address: "alice@example.com",
              to_address: "kmc@clubs.memba.io"
            }} =
             Messaging.receive_inbound_club_email(
               %{
                 provider: "resend",
                 provider_message_id: "task-014-attachments",
                 from_address: "alice@example.com",
                 recipient_addresses: ["kmc@clubs.memba.io"],
                 subject: "Trip planning night",
                 text_body: "Bring route ideas.",
                 attachments: [
                   %{
                     filename: "route.gpx",
                     content_type: "application/gpx+xml",
                     size: 1234
                   }
                 ]
               },
               consistency: :strong
             )

    assert [] = Messaging.list_messages_for_club(kmc.club_id)
    assert [] = Fake.deliveries()
    assert 0 == count_events(MessageSent)
    assert 0 == count_events(InboundClubEmailAccepted)
    assert 1 == count_events(InboundClubEmailRejected)

    assert %InboundEmailSourceProjection{
             inbound_email_id: "inbound-email:resend:task-014-attachments",
             provider: "resend",
             provider_message_id: "task-014-attachments",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "attachments_not_supported",
             rejection_email_delivery_reference: nil
           } = Messaging.get_inbound_email_source("resend", "task-014-attachments")
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

  defp count_events(event_module) when is_atom(event_module) do
    event_type = Atom.to_string(event_module)

    %{rows: [[count]]} =
      Repo.query!(
        ~S|SELECT count(*) FROM "event_store"."events" WHERE event_type = $1|,
        [event_type]
      )

    count
  end
end
