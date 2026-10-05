defmodule Memba.Messaging.ConversationFollowPreparationTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationFollowPreparation

  test "raw follow and unfollow preserve the supplied IDs without dispatch" do
    attrs = %{club_id: "club", conversation_id: "conversation", member_id: "member"}

    assert {:ok, %FollowConversation{} = follow} =
             ConversationFollowPreparation.prepare_follow(attrs)

    assert {:ok, %UnfollowConversation{} = unfollow} =
             ConversationFollowPreparation.prepare_unfollow(attrs)

    assert Map.take(follow, Map.keys(attrs)) == attrs
    assert Map.take(unfollow, Map.keys(attrs)) == attrs
  end

  test "string keys are accepted, and atom keys take precedence" do
    attrs = %{
      "club_id" => "other",
      "conversation_id" => "conversation",
      "member_id" => "member",
      club_id: nil
    }

    for prepare <- [
          &ConversationFollowPreparation.prepare_follow/1,
          &ConversationFollowPreparation.prepare_unfollow/1
        ] do
      assert {:ok, %{club_id: nil, conversation_id: "conversation", member_id: "member"}} =
               prepare.(attrs)
    end
  end

  test "missing required attributes retain the first missing field error" do
    for prepare <- [
          &ConversationFollowPreparation.prepare_follow/1,
          &ConversationFollowPreparation.prepare_unfollow/1
        ] do
      assert {:error, {:missing_required_attribute, :club_id}} = prepare.(%{})

      assert {:error, {:missing_required_attribute, :conversation_id}} =
               prepare.(%{club_id: "club"})

      assert {:error, {:missing_required_attribute, :member_id}} =
               prepare.(%{club_id: "club", conversation_id: "conversation"})
    end
  end
end
