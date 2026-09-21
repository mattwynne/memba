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

  defstruct [
    :conversation_id,
    :club_id,
    follower_ids: MapSet.new(),
    follower_generations: %{},
    cleanup_generations: %{},
    completed_cleanup_ids: MapSet.new()
  ]

  @impl Aggregate
  def execute(%__MODULE__{} = conversation, %FollowConversation{} = command) do
    with :ok <- validate_command(command),
         :ok <- validate_group_ids(command.authorizing_group_ids),
         :ok <- validate_same_conversation(conversation, command),
         :ok <- validate_same_club(conversation, command) do
      membership_generation = normalize_generation(command.membership_generation)
      current_generation = follower_generation(conversation, command.member_id)
      authorizing_group_ids = normalize_group_ids(command.authorizing_group_ids)

      cond do
        not follow_allowed?(
          conversation,
          command.member_id,
          authorizing_group_ids,
          membership_generation
        ) ->
          []

        MapSet.member?(conversation.follower_ids, command.member_id) and
            membership_generation <= current_generation ->
          []

        true ->
          %ConversationFollowed{
            follow_id: follow_id(command.conversation_id, command.member_id),
            club_id: command.club_id,
            conversation_id: command.conversation_id,
            member_id: command.member_id,
            membership_generation: command.membership_generation,
            authorizing_group_ids: authorizing_group_ids
          }
      end
    end
  end

  def execute(%__MODULE__{} = conversation, %UnfollowConversation{} = command) do
    with :ok <- validate_command(command),
         :ok <- validate_optional_removed_group_id(command.removed_group_id),
         :ok <- validate_same_conversation(conversation, command),
         :ok <- validate_same_club(conversation, command) do
      cond do
        cleanup_completed?(conversation, command.cleanup_id) ->
          []

        MapSet.member?(conversation.follower_ids, command.member_id) or
            is_binary(command.cleanup_id) ->
          %ConversationUnfollowed{
            follow_id: follow_id(command.conversation_id, command.member_id),
            club_id: command.club_id,
            conversation_id: command.conversation_id,
            member_id: command.member_id,
            cleanup_id: command.cleanup_id,
            membership_generation: command.membership_generation,
            removed_group_id: command.removed_group_id,
            follow_retained:
              MapSet.member?(conversation.follower_ids, command.member_id) and
                is_binary(command.cleanup_id) and
                (command.retain_follow == true or
                   normalize_generation(command.membership_generation) <
                     follower_generation(conversation, command.member_id))
          }

        true ->
          []
      end
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = conversation, %MessageSent{} = event) do
    conversation = %__MODULE__{
      conversation
      | conversation_id: event.conversation_id || event.message_id,
        club_id: event.club_id
    }

    if MessageSent.sender_follows_conversation?(event) do
      apply_follow(
        conversation,
        event.sender_id,
        event.sender_membership_generation,
        message_sender_follow_group_ids(event)
      )
    else
      conversation
    end
  end

  def apply(%__MODULE__{} = conversation, %ConversationFollowed{} = event) do
    conversation = %__MODULE__{
      conversation
      | conversation_id: event.conversation_id,
        club_id: event.club_id
    }

    apply_follow(
      conversation,
      event.member_id,
      event.membership_generation,
      event.authorizing_group_ids
    )
  end

  def apply(%__MODULE__{} = conversation, %ConversationUnfollowed{} = event) do
    conversation = %__MODULE__{
      conversation
      | conversation_id: event.conversation_id,
        club_id: event.club_id,
        completed_cleanup_ids:
          record_completed_cleanup(conversation.completed_cleanup_ids, event.cleanup_id)
    }

    apply_unfollow(conversation, event)
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

  defp cleanup_completed?(_conversation, nil), do: false

  defp cleanup_completed?(conversation, cleanup_id) do
    MapSet.member?(conversation.completed_cleanup_ids, cleanup_id)
  end

  defp record_completed_cleanup(cleanup_ids, cleanup_id) when is_binary(cleanup_id) do
    MapSet.put(cleanup_ids, cleanup_id)
  end

  defp record_completed_cleanup(cleanup_ids, _cleanup_id), do: cleanup_ids

  defp apply_follow(
         conversation,
         member_id,
         membership_generation,
         authorizing_group_ids
       ) do
    membership_generation = normalize_generation(membership_generation)
    authorizing_group_ids = normalize_group_ids(authorizing_group_ids)

    if follow_allowed?(
         conversation,
         member_id,
         authorizing_group_ids,
         membership_generation
       ) do
      %__MODULE__{
        conversation
        | follower_ids: MapSet.put(conversation.follower_ids, member_id),
          follower_generations:
            Map.put(conversation.follower_generations, member_id, membership_generation)
      }
    else
      conversation
    end
  end

  defp apply_unfollow(conversation, %ConversationUnfollowed{cleanup_id: cleanup_id} = event)
       when is_binary(cleanup_id) do
    membership_generation = normalize_generation(event.membership_generation)

    conversation =
      %__MODULE__{
        conversation
        | cleanup_generations:
            Map.update(
              conversation.cleanup_generations,
              {event.member_id, event.removed_group_id},
              membership_generation,
              &max(&1, membership_generation)
            )
      }

    if event.follow_retained == true or
         membership_generation < follower_generation(conversation, event.member_id) do
      conversation
    else
      delete_follower(conversation, event.member_id)
    end
  end

  defp apply_unfollow(conversation, %ConversationUnfollowed{} = event) do
    delete_follower(conversation, event.member_id)
  end

  defp delete_follower(conversation, member_id) do
    %__MODULE__{
      conversation
      | follower_ids: MapSet.delete(conversation.follower_ids, member_id),
        follower_generations: Map.delete(conversation.follower_generations, member_id)
    }
  end

  defp follower_generation(conversation, member_id) do
    Map.get(conversation.follower_generations, member_id, 0)
  end

  defp follow_allowed?(conversation, member_id, [], membership_generation) do
    membership_generation > latest_cleanup_generation(conversation, member_id)
  end

  defp follow_allowed?(
         conversation,
         member_id,
         authorizing_group_ids,
         membership_generation
       ) do
    historic_cutoff =
      Map.get(conversation.cleanup_generations, {member_id, nil}, -1)

    Enum.any?(authorizing_group_ids, fn group_id ->
      removed_group_cutoff =
        Map.get(conversation.cleanup_generations, {member_id, group_id}, -1)

      membership_generation > max(historic_cutoff, removed_group_cutoff)
    end)
  end

  defp latest_cleanup_generation(conversation, member_id) do
    conversation.cleanup_generations
    |> Enum.reduce(-1, fn
      {{^member_id, _group_id}, generation}, latest -> max(generation, latest)
      {_other_member_and_group, _generation}, latest -> latest
    end)
  end

  defp message_sender_follow_group_ids(%MessageSent{} = event) do
    case event.sender_follow_group_ids do
      group_ids when is_list(group_ids) and group_ids != [] ->
        group_ids

      _historic_or_unspecified
      when is_nil(event.conversation_id) or event.message_id == event.conversation_id ->
        List.wrap(event.audience_group_id)

      _historic_or_unspecified ->
        []
    end
  end

  defp validate_group_ids(nil), do: :ok

  defp validate_group_ids(group_ids) when is_list(group_ids) do
    Enum.reduce_while(group_ids, :ok, fn group_id, :ok ->
      case validate_id(:group, group_id, :invalid_authorizing_group_ids) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp validate_group_ids(_invalid), do: {:error, :invalid_authorizing_group_ids}

  defp validate_optional_removed_group_id(nil), do: :ok

  defp validate_optional_removed_group_id(group_id),
    do: validate_id(:group, group_id, :invalid_removed_group_id)

  defp normalize_group_ids(group_ids) when is_list(group_ids),
    do: group_ids |> Enum.uniq() |> Enum.sort()

  defp normalize_group_ids(_historic_or_invalid), do: []

  defp normalize_generation(generation)
       when is_integer(generation) and generation >= 0,
       do: generation

  defp normalize_generation(_historic_or_invalid), do: 0

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end
end
