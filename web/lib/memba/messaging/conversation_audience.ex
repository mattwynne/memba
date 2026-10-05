defmodule Memba.Messaging.ConversationAudience do
  @moduledoc """
  Resolve the single current group audience of a conversation from its root aggregate.

  Missing and multi-group audiences fail closed. Projected grants are only
  candidates for read queries, not the authority for this decision.
  """

  alias Memba.ID
  alias Memba.Messaging.App
  alias Memba.Messaging.Message

  def resolve(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         %Message{
           message_id: ^conversation_id,
           club_id: club_id,
           group_access: group_access
         } <- App.aggregate_state(Message, conversation_id),
         {:ok, group_id, access_level} <- canonical_group_access(group_access) do
      {:ok,
       %{
         conversation_id: conversation_id,
         club_id: club_id,
         group_id: group_id,
         access_level: access_level
       }}
    else
      {:error, _reason} = error -> error
      _invalid_or_missing -> {:error, :conversation_audience_not_found}
    end
  end

  @doc false
  def canonical_group?(conversation_id, group_id) do
    case resolve(conversation_id) do
      {:ok, %{group_id: ^group_id}} -> true
      _missing_or_ambiguous -> false
    end
  end

  @doc false
  def canonical_group_access(group_access) when map_size(group_access) == 1 do
    [{group_id, access_level}] = Map.to_list(group_access)
    {:ok, group_id, access_level}
  end

  def canonical_group_access(group_access) when map_size(group_access) == 0,
    do: {:error, :conversation_audience_not_found}

  def canonical_group_access(_ambiguous),
    do: {:error, :ambiguous_conversation_audience}
end
