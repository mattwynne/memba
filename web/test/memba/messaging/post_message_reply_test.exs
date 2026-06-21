defmodule Memba.Messaging.PostMessageReplyTest do
  use Memba.EventSourcedCase, async: false

  import Ecto.Query

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Messaging
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  test "a current club member can post a reply in the root message conversation and email everyone except themself" do
    club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")
    carol = create_person(name: "Carol", email: "carol@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")
    other_club_id = Memba.ID.generate(:club)

    add_member(club_id, alice.person_id)
    add_member(club_id, bob.person_id)
    add_member(club_id, carol.person_id)
    add_member(other_club_id, pat.person_id)

    root_message_id = send_root_message(club_id, alice.person_id)
    reply_message_id = Memba.ID.generate(:message)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^reply_message_id,
              events: [
                %MessageSent{
                  message_id: ^reply_message_id,
                  club_id: ^club_id,
                  sender_id: bob_id,
                  conversation_id: ^root_message_id,
                  reply_to_message_id: ^root_message_id,
                  subject: "Trip planning night",
                  body: "I can bring maps."
                }
                | delivery_events
              ]
            }} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: root_message_id,
                 sender_id: bob.person_id,
                 body: " I can bring maps. "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert bob_id == bob.person_id

    assert [
             %EmailDeliveryCreated{
               message_id: ^reply_message_id,
               recipient_id: alice_id,
               recipient_name: "Alice",
               recipient_email: "alice@example.com"
             },
             %EmailDeliveryCreated{
               message_id: ^reply_message_id,
               recipient_id: carol_id,
               recipient_name: "Carol",
               recipient_email: "carol@example.com"
             }
           ] = delivery_events

    assert [alice_id, carol_id] == [alice.person_id, carol.person_id]
    refute bob.person_id in Enum.map(delivery_events, & &1.recipient_id)
    refute pat.person_id in Enum.map(delivery_events, & &1.recipient_id)

    assert %MessageProjection{
             message_id: ^reply_message_id,
             club_id: ^club_id,
             sender_id: ^bob_id,
             conversation_id: ^root_message_id,
             reply_to_message_id: ^root_message_id,
             subject: "Trip planning night",
             body: "I can bring maps."
           } = Messaging.get_message(reply_message_id)

    assert [
             %EmailDeliveryProjection{
               message_id: ^reply_message_id,
               recipient_id: ^alice_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               status: "pending"
             },
             %EmailDeliveryProjection{
               message_id: ^reply_message_id,
               recipient_id: ^carol_id,
               recipient_name: "Carol",
               recipient_address: "carol@example.com",
               status: "pending"
             }
           ] = pending_deliveries_for_message(reply_message_id)
  end

  test "a person who is not a current member of the root message club cannot reply" do
    club_id = Memba.ID.generate(:club)
    other_club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    pat = create_person(name: "Pat", email: "pat@example.com")

    add_member(club_id, alice.person_id)
    add_member(other_club_id, pat.person_id)

    root_message_id = send_root_message(club_id, alice.person_id)
    reply_message_id = Memba.ID.generate(:message)

    assert {:error, :not_current_member} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: root_message_id,
                 sender_id: pat.person_id,
                 body: "Can I join?"
               },
               consistency: :strong
             )

    refute Repo.get(MessageProjection, reply_message_id)
  end

  test "a reply body cannot be blank" do
    club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")

    add_member(club_id, alice.person_id)
    add_member(club_id, bob.person_id)

    root_message_id = send_root_message(club_id, alice.person_id)
    reply_message_id = Memba.ID.generate(:message)

    assert {:error, :invalid_body} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: root_message_id,
                 sender_id: bob.person_id,
                 body: "   "
               },
               consistency: :strong
             )

    refute Repo.get(MessageProjection, reply_message_id)
  end

  defp send_root_message(club_id, sender_id) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    message_id
  end

  defp pending_deliveries_for_message(message_id) do
    EmailDeliveryProjection
    |> where([delivery], delivery.message_id == ^message_id)
    |> order_by([delivery], asc: delivery.recipient_name)
    |> Repo.all()
  end

  defp create_person(attrs) do
    person = %{
      person_id: Memba.ID.generate(:person),
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
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end
end
