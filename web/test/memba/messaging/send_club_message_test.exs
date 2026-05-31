defmodule Memba.Messaging.SendClubMessageTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Messaging
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.RecipientDeliveryCreated

  setup do
    Fake.reset()
    :ok
  end

  test "resolves active club members via Membership and dispatches SendMessage" do
    kootenay_club_id = Ecto.UUID.generate()
    nelson_club_id = Ecto.UUID.generate()

    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")

    add_member(kootenay_club_id, alice.person_id)
    add_member(kootenay_club_id, bob.person_id)
    add_member(kootenay_club_id, carol.person_id)
    add_member(nelson_club_id, pat.person_id)

    message_id = Ecto.UUID.generate()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^kootenay_club_id,
                  sender_id: sender_id,
                  subject: "Trip planning night",
                  body: "Bring route ideas."
                }
                | delivery_events
              ]
            }} =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: kootenay_club_id,
                 sender_id: alice.person_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert sender_id == alice.person_id

    assert [
             %RecipientDeliveryCreated{
               message_id: ^message_id,
               recipient_id: alice_id,
               recipient_name: "Alice",
               recipient_email: "alice@example.com"
             },
             %RecipientDeliveryCreated{
               message_id: ^message_id,
               recipient_id: bob_id,
               recipient_name: "Bob",
               recipient_email: "bob@example.com"
             },
             %RecipientDeliveryCreated{
               message_id: ^message_id,
               recipient_id: carol_id,
               recipient_name: "Carol",
               recipient_email: "carol@example.com"
             }
           ] = delivery_events

    assert [alice_id, bob_id, carol_id] == [alice.person_id, bob.person_id, carol.person_id]
    refute pat.person_id in Enum.map(delivery_events, & &1.recipient_id)

    delivery_ids = Enum.map(delivery_events, & &1.delivery_id)

    assert Enum.all?(delivery_ids, &(Ecto.UUID.cast(&1) != :error))
    assert Enum.uniq(delivery_ids) == delivery_ids

    assert [
             %DeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: alice_delivery_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %DeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: bob_delivery_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             },
             %DeliveryRequest{
               message_id: ^message_id,
               club_id: ^kootenay_club_id,
               delivery_id: carol_delivery_id,
               recipient_id: ^carol_id,
               recipient_name: "Carol",
               recipient_address: "carol@example.com",
               channel: :email,
               subject: "Trip planning night",
               body: "Bring route ideas."
             }
           ] = Fake.deliveries()

    assert [alice_delivery_id, bob_delivery_id, carol_delivery_id] == delivery_ids
  end

  test "does not call the provider when the send command is rejected" do
    club_id = Ecto.UUID.generate()
    alice = create_person(name: "Alice", email: "alice@example.com")
    add_member(club_id, alice.person_id)

    assert {:error, :invalid_subject} =
             Messaging.send_club_message(%{
               message_id: Ecto.UUID.generate(),
               club_id: club_id,
               sender_id: alice.person_id,
               subject: "  ",
               body: "Bring route ideas."
             })

    assert Fake.deliveries() == []
  end

  defp create_person(attrs) do
    person = %{
      person_id: Ecto.UUID.generate(),
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    }

    assert :ok =
             MembershipApp.dispatch(
               %CreatePerson{
                 person_id: person.person_id,
                 name: person.name,
                 email: person.email
               },
               consistency: :strong
             )

    person
  end

  defp add_member(club_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AddMember{
                 membership_id: Ecto.UUID.generate(),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end
end
