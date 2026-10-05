defmodule Memba.Messaging.ConversationListing do
  @moduledoc """
  Read-side overview queries for club and group conversations.

  Group grants narrow the projected candidates; the root aggregate's canonical
  audience remains the final filter. Membership authorization of a person is
  the caller's responsibility.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def list_for_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      club_id
      |> conversations_for_club_query()
      |> Repo.all()
      |> add_latest_replier_names()
    else
      :error -> []
    end
  end

  def list_for_group(group_id) do
    with {:ok, group_id} <- ID.cast(:group, group_id) do
      group_id
      |> conversations_for_group_query()
      |> Repo.all()
      |> Enum.filter(&canonical_group?(&1.conversation_id, group_id))
      |> add_latest_replier_names()
    else
      :error -> []
    end
  end

  defp conversations_for_club_query(club_id) do
    {:club, club_id}
    |> conversations_query()
  end

  defp conversations_for_group_query(group_id) do
    {:group, group_id}
    |> conversations_query()
  end

  defp conversations_query(scope) do
    reply_counts_query =
      MessageProjection
      |> where([reply], reply.message_id != reply.conversation_id)
      |> scope_conversation_entries_query(scope)
      |> group_by([reply, ...], [reply.club_id, reply.conversation_id])
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        reply_count: count(reply.message_id)
      })

    latest_replies_query =
      MessageProjection
      |> where([reply], reply.message_id != reply.conversation_id)
      |> scope_conversation_entries_query(scope)
      |> distinct([reply, ...], asc: reply.club_id, asc: reply.conversation_id)
      |> order_by([reply, ...],
        asc: reply.club_id,
        asc: reply.conversation_id,
        desc: reply.inserted_at,
        desc: reply.message_id
      )
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        latest_replier_id: reply.sender_id
      })

    participant_first_replies_query =
      MessageProjection
      |> join(:inner, [reply], root in MessageProjection,
        on:
          root.club_id == reply.club_id and
            root.message_id == reply.conversation_id and
            root.message_id == root.conversation_id
      )
      |> where(
        [reply, root],
        reply.message_id != reply.conversation_id and reply.sender_id != root.sender_id
      )
      |> scope_conversation_entries_query(scope)
      |> group_by([reply, ...], [reply.club_id, reply.conversation_id, reply.sender_id])
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        sender_id: reply.sender_id,
        first_replied_at: min(reply.inserted_at)
      })

    participants_query =
      from(participant in subquery(participant_first_replies_query),
        group_by: [participant.club_id, participant.conversation_id],
        select: %{
          club_id: participant.club_id,
          conversation_id: participant.conversation_id,
          participant_ids:
            fragment(
              "array_agg(? ORDER BY ?, ?)",
              participant.sender_id,
              participant.first_replied_at,
              participant.sender_id
            )
        }
      )

    query =
      from(root in MessageProjection,
        left_join: reply_counts in subquery(reply_counts_query),
        on:
          reply_counts.club_id == root.club_id and
            reply_counts.conversation_id == root.message_id,
        left_join: latest_reply in subquery(latest_replies_query),
        on:
          latest_reply.club_id == root.club_id and
            latest_reply.conversation_id == root.message_id,
        left_join: participants in subquery(participants_query),
        on:
          participants.club_id == root.club_id and
            participants.conversation_id == root.message_id,
        where: root.message_id == root.conversation_id,
        order_by: [desc: root.inserted_at, desc: root.message_id],
        select: %{
          message: root,
          message_id: root.message_id,
          conversation_id: root.conversation_id,
          club_id: root.club_id,
          sender_id: root.sender_id,
          subject: root.subject,
          body: root.body,
          inserted_at: root.inserted_at,
          updated_at: root.updated_at,
          reply_count: fragment("COALESCE(?, 0)", reply_counts.reply_count),
          latest_replier_id: latest_reply.latest_replier_id,
          participant_ids: fragment("COALESCE(?, ARRAY[]::text[])", participants.participant_ids)
        }
      )

    scope_conversation_roots_query(query, scope)
  end

  defp scope_conversation_entries_query(query, {:club, club_id}) do
    where(query, [entry, ...], entry.club_id == ^club_id)
  end

  defp scope_conversation_entries_query(query, {:group, group_id}) do
    read_grant_levels = ConversationAccess.grant_levels_including("read")

    from([entry, ...] in query,
      join: access in ConversationGroupAccessProjection,
      on:
        access.conversation_id == entry.conversation_id and
          access.club_id == entry.club_id,
      where: access.group_id == ^group_id and access.access_level in ^read_grant_levels
    )
  end

  defp scope_conversation_roots_query(query, {:club, club_id}) do
    where(query, [root, _reply_counts, _latest_reply, _participants], root.club_id == ^club_id)
  end

  defp scope_conversation_roots_query(query, {:group, group_id}) do
    read_grant_levels = ConversationAccess.grant_levels_including("read")

    from([root, _reply_counts, _latest_reply, _participants] in query,
      join: access in ConversationGroupAccessProjection,
      on:
        access.conversation_id == root.message_id and
          access.club_id == root.club_id,
      where: access.group_id == ^group_id and access.access_level in ^read_grant_levels
    )
  end

  defp add_latest_replier_names(conversation_rows) do
    replier_summaries =
      conversation_rows
      |> Enum.map(& &1.latest_replier_id)
      |> Enum.reject(&is_nil/1)
      |> Membership.list_person_contact_summaries()

    Enum.map(conversation_rows, fn row ->
      latest_replier_name =
        row.latest_replier_id
        |> then(&Map.get(replier_summaries, &1, %{}))
        |> Map.get(:name)

      Map.put(row, :latest_replier_name, latest_replier_name)
    end)
  end

  @doc false
  def canonical_group?(conversation_id, group_id) do
    case Messaging.resolve_conversation_audience(conversation_id) do
      {:ok, %{group_id: ^group_id}} -> true
      _missing_or_ambiguous -> false
    end
  end
end
