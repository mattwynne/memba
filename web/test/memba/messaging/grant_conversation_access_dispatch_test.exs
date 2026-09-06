defmodule Memba.Messaging.GrantConversationAccessDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.GrantInitialConversationAccessToGroup
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RevokeConversationAccessFromGroup
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.ConversationAccessRevokedFromGroup
  alias Memba.Messaging.Message
  alias Memba.Messaging.Recipient

  test "Messaging app dispatch routes GrantConversationAccessToGroup to the root Message stream" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^conversation_id,
              events: [
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^conversation_id,
                  club_id: ^club_id,
                  group_id: ^group_id,
                  access_level: "read"
                }
              ],
              aggregate_state: %Message{group_access: %{^group_id => "read"}}
            }} =
             App.dispatch(
               %GrantConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: :read
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "repeated grants and write-satisfies-read requests are no-ops" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert {:ok, %ExecutionResult{events: [%ConversationAccessGrantedToGroup{}]}} =
             App.dispatch(
               grant_command(conversation_id, club_id, group_id, "write"),
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               grant_command(conversation_id, club_id, group_id, "write"),
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               grant_command(conversation_id, club_id, group_id, "read"),
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "read grants can be upgraded to write grants" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert {:ok,
            %ExecutionResult{events: [%ConversationAccessGrantedToGroup{access_level: "read"}]}} =
             App.dispatch(
               grant_command(conversation_id, club_id, group_id, "read"),
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              events: [%ConversationAccessGrantedToGroup{access_level: "write"}],
              aggregate_state: %Message{group_access: %{^group_id => "write"}}
            }} =
             App.dispatch(
               grant_command(conversation_id, club_id, group_id, "write"),
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "public API grants are strongly visible in the conversation access query" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert :ok =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: group_id,
               access_level: :write
             })

    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :write)
    assert Messaging.group_has_conversation_access?(conversation_id, group_id, :read)
  end

  test "initial-access API cannot widen a conversation that already has an audience" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    admin_group_id = Memba.ID.generate(:group)
    everyone_group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert :ok =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: admin_group_id,
               access_level: :write
             })

    assert :ok =
             Messaging.grant_initial_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: everyone_group_id,
               access_level: :write
             })

    assert Messaging.group_has_conversation_access?(conversation_id, admin_group_id, :write)
    refute Messaging.group_has_conversation_access?(conversation_id, everyone_group_id, :read)

    assert {:ok, %ExecutionResult{events: []}} =
             App.dispatch(
               %GrantInitialConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: everyone_group_id,
                 access_level: :write
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "public API revokes access, projects the removal, and is idempotent" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    send_root_conversation(conversation_id, club_id)

    assert :ok =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: group_id,
               access_level: :write
             })

    assert :ok =
             Messaging.revoke_conversation_access_from_group(%{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: group_id
             })

    refute Messaging.group_has_conversation_access?(conversation_id, group_id, :read)

    assert {:ok,
            %ExecutionResult{
              events: [],
              aggregate_state: %Message{group_access: %{}}
            }} =
             App.dispatch(
               %RevokeConversationAccessFromGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert 1 ==
             App
             |> Commanded.EventStore.stream_forward(conversation_id)
             |> Enum.count(&match?(%{data: %ConversationAccessRevokedFromGroup{}}, &1))
  end

  test "public API rejects attempts to grant access to a reply stream" do
    conversation_id = Memba.ID.generate(:message)
    reply_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)
    sender_id = Memba.ID.generate(:person)
    send_root_conversation(conversation_id, club_id)

    assert :ok =
             App.dispatch(
               %PostMessageReply{
                 message_id: reply_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 conversation_id: conversation_id,
                 reply_to_message_id: conversation_id,
                 subject: "Trail day",
                 body: "I'll bring maps.",
                 recipients: []
               },
               consistency: :strong
             )

    assert {:error, :conversation_id_mismatch} =
             Messaging.grant_conversation_access_to_group(%{
               conversation_id: reply_id,
               club_id: club_id,
               group_id: group_id,
               access_level: :read
             })
  end

  defp send_root_conversation(conversation_id, club_id) do
    sender_id = Memba.ID.generate(:person)

    App.dispatch(
      %SendMessage{
        message_id: conversation_id,
        club_id: club_id,
        sender_id: sender_id,
        subject: "Trail day",
        body: "Meet at 9am.",
        recipients: [
          %Recipient{
            delivery_id: Memba.ID.generate(:delivery),
            person_id: sender_id,
            name: "Alice Sender",
            email: "alice@example.com"
          }
        ]
      },
      consistency: :strong
    )
  end

  defp grant_command(conversation_id, club_id, group_id, access_level) do
    %GrantConversationAccessToGroup{
      conversation_id: conversation_id,
      club_id: club_id,
      group_id: group_id,
      access_level: access_level
    }
  end
end
