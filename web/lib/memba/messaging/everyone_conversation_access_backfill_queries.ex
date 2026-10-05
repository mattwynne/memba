defmodule Memba.Messaging.EveryoneConversationAccessBackfillQueries do
  @moduledoc "Read-only, keyset-paged root conversation query for Everyone access backfill."

  import Ecto.Query

  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

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
