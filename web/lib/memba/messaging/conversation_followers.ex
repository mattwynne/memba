defmodule Memba.Messaging.ConversationFollowers do
  @moduledoc """
  Aggregate tracking follower state for one message conversation.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.Events.ConversationFollowed
  alias Memba.Messaging.Events.ConversationUnfollowed
  alias Memba.Messaging.Events.MessageSent

  @behaviour Aggregate

  defstruct [:conversation_id, :club_id, follower_ids: MapSet.new()]

  @impl Aggregate
  def execute(%__MODULE__{} = conversation, %FollowConversation{} = command) do
    with :ok <- validate_command(command),
         :ok <- validate_same_conversation(conversation, command),
         :ok <- validate_same_club(conversation, command) do
      if MapSet.member?(conversation.follower_ids, command.member_id) do
        []
      else
        %ConversationFollowed{
          follow_id: follow_id(command.conversation_id, command.member_id),
          club_id: command.club_id,
          conversation_id: command.conversation_id,
          member_id: command.member_id
        }
      end
    end
  end

  def execute(%__MODULE__{} = conversation, %UnfollowConversation{} = command) do
    with :ok <- validate_command(command),
         :ok <- validate_same_conversation(conversation, command),
         :ok <- validate_same_club(conversation, command) do
      if MapSet.member?(conversation.follower_ids, command.member_id) do
        %ConversationUnfollowed{
          follow_id: follow_id(command.conversation_id, command.member_id),
          club_id: command.club_id,
          conversation_id: command.conversation_id,
          member_id: command.member_id
        }
      else
        []
      end
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = conversation, %MessageSent{} = event) do
    follower_ids =
      if MessageSent.sender_follows_conversation?(event) do
        MapSet.put(conversation.follower_ids, event.sender_id)
      else
        conversation.follower_ids
      end

    %__MODULE__{
      conversation
      | conversation_id: event.conversation_id || event.message_id,
        club_id: event.club_id,
        follower_ids: follower_ids
    }
  end

  def apply(%__MODULE__{} = conversation, %ConversationFollowed{} = event) do
    %__MODULE__{
      conversation
      | conversation_id: event.conversation_id,
        club_id: event.club_id,
        follower_ids: MapSet.put(conversation.follower_ids, event.member_id)
    }
  end

  def apply(%__MODULE__{} = conversation, %ConversationUnfollowed{} = event) do
    %__MODULE__{
      conversation
      | conversation_id: event.conversation_id,
        club_id: event.club_id,
        follower_ids: MapSet.delete(conversation.follower_ids, event.member_id)
    }
  end

  def apply(%__MODULE__{} = conversation, _event), do: conversation

  def follow_id(conversation_id, member_id) do
    ID.deterministic(:conversation_follow, [conversation_id, member_id])
  end

  defp validate_command(command) do
    with :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:message, command.conversation_id, :invalid_conversation_id) do
      validate_id(:person, command.member_id, :invalid_member_id)
    end
  end

  defp validate_same_conversation(%__MODULE__{conversation_id: nil}, _command), do: :ok

  defp validate_same_conversation(%__MODULE__{conversation_id: conversation_id}, %{
         conversation_id: conversation_id
       }) do
    :ok
  end

  defp validate_same_conversation(%__MODULE__{}, _command),
    do: {:error, :conversation_id_mismatch}

  defp validate_same_club(%__MODULE__{club_id: nil}, _command), do: :ok
  defp validate_same_club(%__MODULE__{club_id: club_id}, %{club_id: club_id}), do: :ok
  defp validate_same_club(%__MODULE__{}, _command), do: {:error, :club_id_mismatch}

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end
end
