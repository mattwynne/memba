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

    test "refreshes an existing follow when membership generation advances" do
      conversation = followed_conversation(3)
      member_id = hd(MapSet.to_list(conversation.follower_ids))

      assert %ConversationFollowed{membership_generation: 5} =
               ConversationFollowers.execute(conversation, %FollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id,
                 membership_generation: 5
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

    test "records cleanup even when an auto-follow exists only in the projection" do
      club_id = Memba.ID.generate(:club)
      conversation_id = Memba.ID.generate(:message)
      member_id = Memba.ID.generate(:person)

      command = %UnfollowConversation{
        club_id: club_id,
        conversation_id: conversation_id,
        member_id: member_id,
        cleanup_id: "membership-removal-1"
      }

      assert %ConversationUnfollowed{cleanup_id: "membership-removal-1"} =
               event =
               ConversationFollowers.execute(%ConversationFollowers{}, command)

      cleaned = ConversationFollowers.apply(%ConversationFollowers{}, event)

      followed_again =
        ConversationFollowers.apply(cleaned, %ConversationFollowed{
          follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
          club_id: club_id,
          conversation_id: conversation_id,
          member_id: member_id,
          membership_generation: 1
        })

      assert [] = ConversationFollowers.execute(followed_again, command)
      assert MapSet.member?(followed_again.follower_ids, member_id)
    end

    test "records an older cleanup while preserving a newer follow and later rejects stale work" do
      conversation = followed_conversation(6)
      member_id = hd(MapSet.to_list(conversation.follower_ids))

      assert %ConversationUnfollowed{
               cleanup_id: "older-removal",
               membership_generation: 5,
               follow_retained: true
             } =
               cleanup =
               ConversationFollowers.execute(conversation, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id,
                 cleanup_id: "older-removal",
                 membership_generation: 5
               })

      cleaned = ConversationFollowers.apply(conversation, cleanup)
      assert MapSet.member?(cleaned.follower_ids, member_id)
      assert cleaned.cleanup_generations[member_id] == 5

      assert %ConversationUnfollowed{cleanup_id: nil} =
               ordinary_unfollow =
               ConversationFollowers.execute(cleaned, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id
               })

      unfollowed = ConversationFollowers.apply(cleaned, ordinary_unfollow)
      refute MapSet.member?(unfollowed.follower_ids, member_id)
      assert unfollowed.cleanup_generations[member_id] == 5

      for source <- [:manual, :reply] do
        assert [] =
                 ConversationFollowers.execute(unfollowed, %FollowConversation{
                   club_id: conversation.club_id,
                   conversation_id: conversation.conversation_id,
                   member_id: member_id,
                   membership_generation: 4
                 }),
               "expected delayed #{source} follow work to remain rejected"
      end

      stale_root =
        ConversationFollowers.apply(unfollowed, %MessageSent{
          message_id: conversation.conversation_id,
          club_id: conversation.club_id,
          sender_id: member_id,
          subject: "Delayed root",
          body: "Prepared before removal.",
          sender_membership_generation: 4
        })

      refute MapSet.member?(stale_root.follower_ids, member_id)
    end

    test "explicitly retains an equal-generation shared follow while recording its cutoff" do
      conversation = followed_conversation(5)
      member_id = hd(MapSet.to_list(conversation.follower_ids))

      assert %ConversationUnfollowed{
               cleanup_id: "shared-access-removal",
               membership_generation: 5,
               follow_retained: true
             } =
               cleanup =
               ConversationFollowers.execute(conversation, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id,
                 cleanup_id: "shared-access-removal",
                 membership_generation: 5,
                 retain_follow: true
               })

      retained = ConversationFollowers.apply(conversation, cleanup)
      assert MapSet.member?(retained.follower_ids, member_id)
      assert retained.cleanup_generations[member_id] == 5

      assert %ConversationUnfollowed{cleanup_id: nil} =
               ordinary_unfollow =
               ConversationFollowers.execute(retained, %UnfollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id
               })

      unfollowed = ConversationFollowers.apply(retained, ordinary_unfollow)
      refute MapSet.member?(unfollowed.follower_ids, member_id)
      assert unfollowed.cleanup_generations[member_id] == 5

      assert [] =
               ConversationFollowers.execute(unfollowed, %FollowConversation{
                 club_id: conversation.club_id,
                 conversation_id: conversation.conversation_id,
                 member_id: member_id,
                 membership_generation: 5
               })
    end

    test "records a cleanup cutoff that rejects delayed stale follow work" do
      club_id = Memba.ID.generate(:club)
      conversation_id = Memba.ID.generate(:message)
      member_id = Memba.ID.generate(:person)

      cleanup =
        ConversationFollowers.execute(%ConversationFollowers{}, %UnfollowConversation{
          club_id: club_id,
          conversation_id: conversation_id,
          member_id: member_id,
          cleanup_id: "removal-5",
          membership_generation: 5
        })

      cleaned = ConversationFollowers.apply(%ConversationFollowers{}, cleanup)

      assert [] =
               ConversationFollowers.execute(cleaned, %FollowConversation{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: member_id,
                 membership_generation: 4
               })

      stale_auto_follow =
        ConversationFollowers.apply(cleaned, %MessageSent{
          message_id: conversation_id,
          club_id: club_id,
          sender_id: member_id,
          subject: "Delayed root",
          body: "This send was prepared before removal.",
          sender_membership_generation: 4
        })

      refute MapSet.member?(stale_auto_follow.follower_ids, member_id)

      assert %ConversationFollowed{membership_generation: 6} =
               ConversationFollowers.execute(cleaned, %FollowConversation{
                 club_id: club_id,
                 conversation_id: conversation_id,
                 member_id: member_id,
                 membership_generation: 6
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

  test "historic facts without generation remain replayable and precede generated facts" do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    legacy_follow =
      ConversationFollowers.apply(%ConversationFollowers{}, %ConversationFollowed{
        follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
        club_id: club_id,
        conversation_id: conversation_id,
        member_id: member_id
      })

    assert %ConversationUnfollowed{membership_generation: 1} =
             cleanup =
             ConversationFollowers.execute(legacy_follow, %UnfollowConversation{
               club_id: club_id,
               conversation_id: conversation_id,
               member_id: member_id,
               cleanup_id: "generated-removal",
               membership_generation: 1
             })

    cleaned = ConversationFollowers.apply(legacy_follow, cleanup)
    refute MapSet.member?(cleaned.follower_ids, member_id)

    replayed_legacy_message =
      ConversationFollowers.apply(cleaned, %MessageSent{
        message_id: conversation_id,
        club_id: club_id,
        sender_id: member_id,
        subject: "Historic root",
        body: "Historic body"
      })

    refute MapSet.member?(replayed_legacy_message.follower_ids, member_id)
  end

  test "first generated cleanup delivery preserves a follow after legacy cleanup and re-add" do
    conversation = followed_conversation()
    member_id = hd(MapSet.to_list(conversation.follower_ids))

    legacy_cleaned =
      ConversationFollowers.apply(conversation, %ConversationUnfollowed{
        follow_id: ConversationFollowers.follow_id(conversation.conversation_id, member_id),
        club_id: conversation.club_id,
        conversation_id: conversation.conversation_id,
        member_id: member_id
      })

    followed_after_readd =
      ConversationFollowers.apply(legacy_cleaned, %ConversationFollowed{
        follow_id: ConversationFollowers.follow_id(conversation.conversation_id, member_id),
        club_id: conversation.club_id,
        conversation_id: conversation.conversation_id,
        member_id: member_id,
        membership_generation: 2
      })

    assert %ConversationUnfollowed{} =
             cleanup =
             ConversationFollowers.execute(followed_after_readd, %UnfollowConversation{
               club_id: conversation.club_id,
               conversation_id: conversation.conversation_id,
               member_id: member_id,
               cleanup_id: "historic-removal-first-token-delivery",
               membership_generation: 1
             })

    cleaned = ConversationFollowers.apply(followed_after_readd, cleanup)
    assert MapSet.member?(cleaned.follower_ids, member_id)
    assert cleaned.cleanup_generations[member_id] == 1
  end

  defp followed_conversation(generation \\ nil) do
    club_id = Memba.ID.generate(:club)
    conversation_id = Memba.ID.generate(:message)
    member_id = Memba.ID.generate(:person)

    ConversationFollowers.apply(%ConversationFollowers{}, %ConversationFollowed{
      follow_id: ConversationFollowers.follow_id(conversation_id, member_id),
      club_id: club_id,
      conversation_id: conversation_id,
      member_id: member_id,
      membership_generation: generation
    })
  end
end
