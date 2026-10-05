defmodule Memba.Messaging.MessageQueries do
  @moduledoc """
  Projected message, conversation thread, and operator message reads.

  Group-scoped reads establish a conversation's canonical audience; callers
  decide whether a person may act through that group.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging.ConversationAudience
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def get_message(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      Repo.get(MessageProjection, message_id)
    else
      :error -> nil
    end
  end

  def list_messages_for_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      MessageProjection
      |> where([message], message.club_id == ^club_id)
      |> order_by([message], asc: message.inserted_at, asc: message.message_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  def list_conversation_messages(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         %MessageProjection{} = message <- Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{} = root <- fetch_conversation_root_projection(conversation_id) do
      list_projected_conversation_messages(conversation_id, root.club_id)
    else
      _invalid_or_missing -> []
    end
  end

  def list_conversation_messages_for_group(message_id, group_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, group_id} <- ID.cast(:group, group_id),
         %MessageProjection{} = message <- Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{club_id: club_id} <-
           fetch_conversation_root_projection(conversation_id),
         true <- ConversationAudience.canonical_group?(conversation_id, group_id) do
      list_projected_conversation_messages(conversation_id, club_id)
    else
      _invalid_missing_or_inaccessible -> []
    end
  end

  def list_operator_messages() do
    messages =
      MessageProjection
      |> order_by([message], desc: message.inserted_at, desc: message.message_id)
      |> Repo.all()

    club_summaries =
      messages
      |> Enum.map(& &1.club_id)
      |> Membership.list_club_summaries()

    sender_summaries =
      messages
      |> Enum.map(& &1.sender_id)
      |> Membership.list_person_contact_summaries()

    Enum.map(messages, fn message ->
      club = Map.get(club_summaries, message.club_id, %{})
      sender = Map.get(sender_summaries, message.sender_id, %{})

      %{
        message_id: message.message_id,
        subject: message.subject,
        club_id: message.club_id,
        club_name: Map.get(club, :name),
        club_slug: Map.get(club, :slug),
        sender_id: message.sender_id,
        sender_name: Map.get(sender, :name),
        sender_email: Map.get(sender, :primary_email),
        projected_at: message.inserted_at
      }
    end)
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

  defp list_projected_conversation_messages(conversation_id, club_id) do
    MessageProjection
    |> where(
      [message],
      message.conversation_id == ^conversation_id and message.club_id == ^club_id
    )
    |> order_by([message],
      asc:
        fragment(
          "CASE WHEN ? = ? THEN 0 ELSE 1 END",
          message.message_id,
          ^conversation_id
        ),
      asc: message.inserted_at,
      asc: message.message_id
    )
    |> Repo.all()
  end
end
