defmodule Memba.Messaging.ConversationGroupAccessQueries do
  @moduledoc "Read-only conversation audience and group-access queries."

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.ConversationAudience
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def group_has_conversation_access?(conversation_id, group_id, access_level) do
    with {:ok, group_id} <- ID.cast(:group, group_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level),
         {:ok, %{group_id: ^group_id, access_level: granted_access_level}} <-
           resolve_conversation_audience(conversation_id) do
      granted_access_level in ConversationAccess.grant_levels_including(access_level)
    else
      _invalid_missing_or_ambiguous -> false
    end
  end

  def resolve_conversation_audience(conversation_id),
    do: ConversationAudience.resolve(conversation_id)

  def member_has_conversation_access?(message_id, club_id, person_id, access_level) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level),
         %MessageProjection{club_id: ^club_id} = message <-
           Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{club_id: ^club_id} <-
           fetch_conversation_root_projection(conversation_id),
         {:ok, %{club_id: ^club_id, group_id: group_id, access_level: granted_access_level}} <-
           resolve_conversation_audience(conversation_id),
         true <-
           Membership.active_member_of_group_authoritatively?(club_id, group_id, person_id) do
      granted_access_level in ConversationAccess.grant_levels_including(access_level)
    else
      _invalid_missing_or_inaccessible -> false
    end
  end

  def list_everyone_conversation_access_backfill_page(cursor \\ nil, limit \\ 1_000) do
    root_conversations =
      MessageProjection
      |> where([message], message.message_id == message.conversation_id)
      |> after_backfill_cursor(:message_id, cursor)
      |> order_by([message], asc: message.message_id)
      |> limit(^normalize_backfill_page_size(limit))
      |> select([message], %{
        conversation_id: message.message_id,
        club_id: message.club_id
      })
      |> Repo.all()

    entries =
      root_conversations
      |> Enum.map(fn root ->
        Map.put(root, :group_id, SystemGroups.everyone_group_id(root.club_id))
      end)
      |> reject_conversations_with_access()

    %{
      entries: entries,
      next_cursor: backfill_next_cursor(root_conversations, :conversation_id),
      source_count: length(root_conversations)
    }
  end

  defp conversation_id_for_message(%MessageProjection{conversation_id: conversation_id}) do
    case ID.cast(:message, conversation_id) do
      {:ok, conversation_id} -> {:ok, conversation_id}
      :error -> :error
    end
  end

  defp fetch_conversation_root_projection(conversation_id) do
    case Repo.get(MessageProjection, conversation_id) do
      %MessageProjection{message_id: ^conversation_id, conversation_id: ^conversation_id} = root ->
        root

      _missing_or_not_root ->
        nil
    end
  end

  defp reject_conversations_with_access([]), do: []

  defp reject_conversations_with_access(entries) do
    conversation_ids = Enum.map(entries, & &1.conversation_id)

    conversations_with_access =
      ConversationGroupAccessProjection
      |> where([access], access.conversation_id in ^conversation_ids)
      |> select([access], access.conversation_id)
      |> Repo.all()
      |> MapSet.new()

    Enum.reject(entries, &MapSet.member?(conversations_with_access, &1.conversation_id))
  end

  defp after_backfill_cursor(query, _field, nil), do: query
  defp after_backfill_cursor(query, _field, ""), do: query

  defp after_backfill_cursor(query, field, cursor) when is_binary(cursor) do
    where(query, [row], field(row, ^field) > ^cursor)
  end

  defp normalize_backfill_page_size(limit) when is_integer(limit) and limit > 0, do: limit
  defp normalize_backfill_page_size(_limit), do: 1_000

  defp backfill_next_cursor([], _field), do: nil

  defp backfill_next_cursor(rows, field) do
    rows
    |> List.last()
    |> Map.fetch!(field)
  end
end
