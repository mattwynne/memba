defmodule Memba.Messaging.ConversationFollowersTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.MessageSent

  describe "execute/2 FollowConversation" do
    test "emits a follow event for a member in a conversation" do
      club_id = Memba.ID.generate(:club)
      conversation_id = Memba.ID.generate(:message)
      member_id = Memba.ID.generate(:person)

      assert %ConversationFollowed{
               follow_id: follow_id,
               club_id: ^club_id,
               conversation_id: ^conversation_id,
               member_id: ^member_id
             } =
               ConversationFollowers.execute(%ConversationFollowers{}, %FollowConversation{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: member_id
               })

      assert Memba.ID.valid?(:conversation_follow, follow_id)
    end

    test "is idempotent when the member already follows the conversation" do
      conversation = followed_conversation()

      assert [] =
               ConversationFollowers.execute(conversation, %FollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: hd(MapSet.to_list(conversation.follower_ids))
               })
    end

    test "rejects malformed identifiers and mismatched club context" do
      conversation = followed_conversation()
      member_id = hd(MapSet.to_list(conversation.follower_ids))

      assert {:error, :invalid_club_id} =
               ConversationFollowers.execute(%ConversationFollowers{}, %FollowConversation{
                 club_id: nil,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id
               })

      assert {:error, :invalid_conversation_id} =
               ConversationFollowers.execute(%ConversationFollowers{}, %FollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: "not-a-uuid",
                 member_id: member_id
               })

      assert {:error, :invalid_member_id} =
               ConversationFollowers.execute(%ConversationFollowers{}, %FollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: nil
               })

      assert {:error, :club_id_mismatch} =
               ConversationFollowers.execute(conversation, %FollowConversation{
                 club_id: Memba.ID.generate(:club),
                 conversation_id: conversation.conversation_id,
                 member_id: Memba.ID.generate(:person)
               })
    end
  end

  describe "execute/2 UnfollowConversation" do
    test "emits an unfollow event for a current follower" do
      conversation = followed_conversation()
      member_id = hd(MapSet.to_list(conversation.follower_ids))

      assert %ConversationUnfollowed{
               club_id: club_id,
               conversation_id: conversation_id,
               member_id: ^member_id
             } =
               ConversationFollowers.execute(conversation, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id
               })

      assert club_id == conversation.club_id
      assert conversation_id == conversation.conversation_id
    end

    test "is idempotent when the member is not following the conversation" do
      conversation = followed_conversation()

      assert [] =
               ConversationFollowers.execute(conversation, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: Memba.ID.generate(:person)
               })
    end
  end

  test "apply/2 records follower state" do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    followed =
      ConversationFollowers.apply(%ConversationFollowers{}, %ConversationFollowed{
        follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
        club_id: club_id,
        conversation_id: conversation_id,
        member_id: member_id
      })

    assert %ConversationFollowers{
             club_id: ^club_id,
             conversation_id: ^conversation_id,
             follower_ids: follower_ids
           } = followed

    assert MapSet.member?(follower_ids, member_id)

    unfollowed =
      ConversationFollowers.apply(followed, %ConversationUnfollowed{
        follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
        club_id: club_id,
        conversation_id: conversation_id,
        member_id: member_id
      })

    refute MapSet.member?(unfollowed.follower_ids, member_id)
  end

  test "a root sender excluded from delivery is not rehydrated as a follower" do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    sender_id = Memba.ID.generate(:person)

    conversation =
      ConversationFollowers.apply(%ConversationFollowers{}, %MessageSent{
        message_id: conversation_id,
        club_id: club_id,
        sender_id: sender_id,
        subject: "Private Admin topic",
        body: "Please discuss this with the Admin group.",
        sender_follows_conversation: false
      })

    refute MapSet.member?(conversation.follower_ids, sender_id)

    assert %ConversationFollowed{member_id: ^sender_id} =
             ConversationFollowers.execute(conversation, %FollowConversation{
               club_id: club_id,
               conversation_id: conversation_id,
               member_id: sender_id
             })
  end

  defp followed_conversation do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    ConversationFollowers.apply(%ConversationFollowers{}, %ConversationFollowed{
      follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
      club_id: club_id,
      conversation_id: conversation_id,
      member_id: member_id
    })
  end
end
