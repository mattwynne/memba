defmodule Memba.Messaging.ConversationFollowQueries do
  @moduledoc "Read-only queries over projected conversation follows."

  import Ecto.Query

  alias Memba.ID
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection
  alias Memba.Repo

  def get_conversation_follow(conversation_id, member_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, member_id} <- ID.cast(:person, member_id) do
      Repo.get(
        ConversationFollowProjection,
        ConversationFollowers.follow_id(conversation_id, member_id)
      )
    else
      :error -> nil
    end
  end

  def following_conversation?(conversation_id, member_id) do
    case get_conversation_follow(conversation_id, member_id) do
      %ConversationFollowProjection{following: true} -> true
      _not_following -> false
    end
  end

  def list_conversation_followers(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      ConversationFollowProjection
      |> where([follow], follow.conversation_id == ^conversation_id and follow.following == true)
      |> order_by([follow], asc: follow.member_id)
      |> Repo.all()
    else
      :error -> []
    end
  end
end
