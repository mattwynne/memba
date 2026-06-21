defmodule Memba.Messaging.PostMessageReplyTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Messaging
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  test "a current club member can post a reply in the root message conversation" do
    club_id = Memba.ID.generate(:club)
    alice = create_person(name: "Alice", email: "alice@example.com")
    bob = create_person(name: "Bob", email: "bob@example.com")

    add_member(club_id, alice.person_id)
    add_member(club_id, bob.person_id)

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
                | _delivery_events
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

    assert %MessageProjection{
             message_id: ^reply_message_id,
             club_id: ^club_id,
             sender_id: ^bob_id,
             subject: "Trip planning night",
             body: "I can bring maps."
           } = Messaging.get_message(reply_message_id)
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
