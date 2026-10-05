defmodule Memba.Messaging.CurrentMemberConversationFollow do
  @moduledoc """
  Prepare in-app follow and unfollow commands for a person who still has effective
  read access to the conversation. The stable authorization check is the
  membership-ordering point; a later departure races the prepared dispatch.

  Email stop-follow links deliberately do not use this authorization: former
  members must still be able to reduce notifications.
  """

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging.App
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.Message
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def prepare_follow(attrs) when is_map(attrs), do: prepare(attrs, FollowConversation)
  def prepare_unfollow(attrs) when is_map(attrs), do: prepare(attrs, UnfollowConversation)

  defp prepare(attrs, command_module) do
    AuthorizationCheckpoint.run(fn ->
      with {:ok, club_id} <- fetch_required(attrs, :club_id),
           {:ok, conversation_id} <- fetch_required(attrs, :conversation_id),
           {:ok, member_id} <- fetch_required(attrs, :member_id) do
        command =
          struct(command_module,
            club_id: club_id,
            conversation_id: conversation_id,
            member_id: member_id
          )

        with :ok <- authorize(command) do
          {:ok, command}
        end
      end
    end)
  end

  defp authorize(command) do
    with {:ok, conversation_id} <- cast_conversation_id(command.conversation_id),
         %MessageProjection{} = root <- Repo.get(MessageProjection, conversation_id),
         :ok <- require_conversation_in_club(root, command.club_id),
         true <- effective_read_access?(command) do
      :ok
    else
      nil -> {:error, :conversation_not_found}
      false -> {:error, :not_current_member}
      {:error, _reason} = error -> error
    end
  end

  defp effective_read_access?(command) do
    with {:ok, conversation_id} <- ID.cast(:message, command.conversation_id),
         {:ok, club_id} <- ID.cast(:club, command.club_id),
         {:ok, person_id} <- ID.cast(:person, command.member_id),
         %Message{message_id: ^conversation_id, club_id: ^club_id, group_access: group_access} <-
           App.aggregate_state(Message, conversation_id),
         [{group_id, granted_level}] <- Map.to_list(group_access) do
      granted_level in ConversationAccess.grant_levels_including("read") and
        Membership.active_member_of_group_authoritatively?(club_id, group_id, person_id)
    else
      _missing_or_inaccessible -> false
    end
  end

  defp cast_conversation_id(id) do
    case ID.cast(:message, id) do
      {:ok, id} -> {:ok, id}
      :error -> {:error, :invalid_conversation_id}
    end
  end

  defp require_conversation_in_club(%MessageProjection{club_id: club_id}, club_id), do: :ok

  defp require_conversation_in_club(%MessageProjection{}, _club_id),
    do: {:error, :conversation_not_found}

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end
end
