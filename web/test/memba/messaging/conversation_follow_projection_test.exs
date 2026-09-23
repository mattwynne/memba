defmodule Memba.Messaging.ConversationFollowProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection
  alias Memba.Messaging.Recipient

  @sender_follow_replay_projectors [
    Memba.Messaging.Projectors.Message,
    ConversationFollowProjector,
    Memba.Messaging.Projectors.EmailDelivery,
    Memba.Messaging.Projectors.MemberEmailDelivery,
    Memba.Messaging.Projectors.MembaStaffEmailDelivery
  ]

  test "follow and unfollow commands are projected as the member's current conversation follow state" do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    refute Messaging.following_conversation?(conversation_id, member_id)
    assert Messaging.list_conversation_followers(conversation_id) == []

    assert {:ok,
            %ExecutionResult{
              events: [
                %ConversationFollowed{
                  club_id: ^club_id,
                  conversation_id: ^conversation_id,
                  member_id: ^member_id
                }
              ]
            }} =
             Messaging.follow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: member_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %ConversationFollowProjection{
             club_id: ^club_id,
             conversation_id: ^conversation_id,
             member_id: ^member_id,
             following: true
           } = Messaging.get_conversation_follow(conversation_id, member_id)

    assert [%ConversationFollowProjection{member_id: ^member_id}] =
             Messaging.list_conversation_followers(conversation_id)

    assert true == Messaging.following_conversation?(conversation_id, member_id)

    assert {:ok,
            %ExecutionResult{
              events: [
                %ConversationUnfollowed{
                  club_id: ^club_id,
                  conversation_id: ^conversation_id,
                  member_id: ^member_id
                }
              ]
            }} =
             Messaging.unfollow_conversation(
               %{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: member_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %ConversationFollowProjection{following: false} =
             Messaging.get_conversation_follow(conversation_id, member_id)

    refute Messaging.following_conversation?(conversation_id, member_id)
    assert Messaging.list_conversation_followers(conversation_id) == []
  end

  test "repeated follow and unfollow commands are idempotent" do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    assert {:ok, %ExecutionResult{events: [%ConversationFollowed{}]}} =
             Messaging.follow_conversation(
               %{club_id: club_id, conversation_id: conversation_id, member_id: member_id},
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             Messaging.follow_conversation(
               %{club_id: club_id, conversation_id: conversation_id, member_id: member_id},
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: [%ConversationUnfollowed{}]}} =
             Messaging.unfollow_conversation(
               %{club_id: club_id, conversation_id: conversation_id, member_id: member_id},
               returning: :execution_result,
               consistency: :strong
             )

    assert {:ok, %ExecutionResult{events: []}} =
             Messaging.unfollow_conversation(
               %{club_id: club_id, conversation_id: conversation_id, member_id: member_id},
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "MessageSent auto-follows the root sender and each reply author" do
    club_id = Memba.ID.generate(:club)
    root_message_id = Memba.ID.generate(:message)
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)
    carol_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: root_message_id,
                 club_id: club_id,
                 sender_id: alice_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: alice_id,
                     name: "Alice",
                     email: "alice@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    assert true == Messaging.following_conversation?(root_message_id, alice_id)
    refute Messaging.following_conversation?(root_message_id, bob_id)

    assert :ok =
             App.dispatch(
               %PostMessageReply{
                 message_id: Memba.ID.generate(:message),
                 club_id: club_id,
                 sender_id: bob_id,
                 conversation_id: root_message_id,
                 reply_to_message_id: root_message_id,
                 subject: "Trip planning night",
                 body: "I can bring maps.",
                 recipients: []
               },
               consistency: :strong
             )

    follower_ids =
      root_message_id
      |> Messaging.list_conversation_followers()
      |> Enum.map(& &1.member_id)

    assert Enum.sort(follower_ids) == Enum.sort([alice_id, bob_id])

    refute Messaging.following_conversation?(root_message_id, carol_id)
  end

  test "a root sender excluded from delivery remains unfollowed after projection replay" do
    club_id = Memba.ID.generate(:club)
    root_message_id = Memba.ID.generate(:message)
    sender_id = Memba.ID.generate(:person)
    recipient_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: root_message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Private Admin topic",
                 body: "Please discuss this with the Admin group.",
                 recipients: [
                   %Recipient{
                     delivery_id: Memba.ID.generate(:delivery),
                     person_id: recipient_id,
                     name: "Admin Recipient",
                     email: "admin@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(root_message_id, sender_id)

    projection_positions = event_sourced_projection_positions(@sender_follow_replay_projectors)
    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    await_event_sourced_projection_positions!(projection_positions)

    refute Messaging.following_conversation?(root_message_id, sender_id)
  end
end
