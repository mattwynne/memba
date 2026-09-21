defmodule Memba.Messaging.MemberFollowEligibility do
  @moduledoc """
  Aggregate tracking group-removal cutoffs for one potential follower.

  Conversation-specific cleanup remains on `ConversationFollowers`. This
  member-scoped stream protects conversations created only after cleanup was
  acknowledged, so delayed message work cannot establish a stale sender follow.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Messaging.Commands.RecordMemberFollowCleanup
  alias Memba.Messaging.Events.MemberFollowCleanupRecorded

  @behaviour Aggregate

  defstruct [
    :member_id,
    cleanup_generations: %{},
    completed_cleanup_ids: MapSet.new()
  ]

  @impl Aggregate
  def execute(%__MODULE__{} = eligibility, %RecordMemberFollowCleanup{} = command) do
    with :ok <- validate_eligibility_id(command.eligibility_id, command.member_id),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:group, command.group_id, :invalid_group_id),
         :ok <- validate_id(:person, command.member_id, :invalid_member_id),
         :ok <- validate_cleanup_id(command.cleanup_id),
         :ok <- validate_generation(command.membership_generation) do
      if MapSet.member?(eligibility.completed_cleanup_ids, command.cleanup_id) do
        []
      else
        %MemberFollowCleanupRecorded{
          club_id: command.club_id,
          group_id: command.group_id,
          member_id: command.member_id,
          cleanup_id: command.cleanup_id,
          membership_generation: command.membership_generation
        }
      end
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = eligibility, %MemberFollowCleanupRecorded{} = event) do
    key = {event.club_id, event.group_id}

    %__MODULE__{
      eligibility
      | member_id: event.member_id,
        cleanup_generations:
          Map.update(
            eligibility.cleanup_generations,
            key,
            event.membership_generation,
            &max(&1, event.membership_generation)
          ),
        completed_cleanup_ids: MapSet.put(eligibility.completed_cleanup_ids, event.cleanup_id)
    }
  end

  def apply(%__MODULE__{} = eligibility, _event), do: eligibility

  def identity(member_id) do
    ID.deterministic(:conversation_follow, ["member-follow-eligibility", member_id])
  end

  @doc """
  Return whether a follow from `membership_generation` remains eligible through
  at least one of the conversation's access groups.

  An empty group list represents historic messages without an audience group and
  remains eligible for backward replay compatibility.
  """
  def follow_allowed?(
        %__MODULE__{} = eligibility,
        club_id,
        group_ids,
        membership_generation
      )
      when is_list(group_ids) do
    generation = normalize_generation(membership_generation)

    group_ids == [] or
      Enum.any?(group_ids, fn group_id ->
        generation > Map.get(eligibility.cleanup_generations, {club_id, group_id}, -1)
      end)
  end

  defp validate_cleanup_id(cleanup_id) when is_binary(cleanup_id) do
    if String.trim(cleanup_id) == "", do: {:error, :invalid_cleanup_id}, else: :ok
  end

  defp validate_cleanup_id(_cleanup_id), do: {:error, :invalid_cleanup_id}

  defp validate_eligibility_id(eligibility_id, member_id) do
    if eligibility_id == identity(member_id),
      do: :ok,
      else: {:error, :invalid_member_follow_eligibility_id}
  end

  defp validate_generation(generation) when is_integer(generation) and generation >= 0, do: :ok
  defp validate_generation(_generation), do: {:error, :invalid_membership_generation}

  defp normalize_generation(generation) when is_integer(generation) and generation >= 0,
    do: generation

  defp normalize_generation(_historic_or_invalid), do: 0

  defp validate_id(type, value, error) do
    case ID.cast(type, value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end
end
