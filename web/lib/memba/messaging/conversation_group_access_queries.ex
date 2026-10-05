defmodule Memba.Messaging.ConversationGroupAccessQueries do
  @moduledoc "Read-only conversation audience and group-access queries."

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.ConversationAudience
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
end
