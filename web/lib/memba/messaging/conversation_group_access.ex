defmodule Memba.Messaging.ConversationGroupAccess do
  @moduledoc """
  Prepare group-access commands for a conversation. No command is dispatched here;
  the Message aggregate remains responsible for enforcing access invariants.
  """

  alias Memba.ID
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.GrantInitialConversationAccessToGroup
  alias Memba.Messaging.Commands.RevokeConversationAccessFromGroup

  def prepare_grant(attrs) when is_map(attrs) do
    with {:ok, scope} <- scope(attrs),
         {:ok, access_level} <- access_level(attrs) do
      {:ok, struct(GrantConversationAccessToGroup, Map.put(scope, :access_level, access_level))}
    end
  end

  def prepare_initial_grant(attrs) when is_map(attrs) do
    with {:ok, scope} <- scope(attrs),
         {:ok, access_level} <- access_level(attrs) do
      {:ok,
       struct(GrantInitialConversationAccessToGroup, Map.put(scope, :access_level, access_level))}
    end
  end

  def prepare_revoke(attrs) when is_map(attrs) do
    with {:ok, scope} <- scope(attrs) do
      {:ok, struct(RevokeConversationAccessFromGroup, scope)}
    end
  end

  defp scope(attrs) do
    with {:ok, conversation_id} <- required_id(attrs, :conversation_id, :message),
         {:ok, club_id} <- required_id(attrs, :club_id, :club),
         {:ok, group_id} <- required_id(attrs, :group_id, :group) do
      {:ok, %{conversation_id: conversation_id, club_id: club_id, group_id: group_id}}
    end
  end

  defp access_level(attrs) do
    with {:ok, level} <- required(attrs, :access_level) do
      ConversationAccess.normalize_access_level(level)
    end
  end

  defp required_id(attrs, key, type) do
    with {:ok, value} <- required(attrs, key) do
      case ID.cast(type, value) do
        {:ok, ^value} -> {:ok, value}
        :error -> {:error, invalid_id_reason(key)}
      end
    end
  end

  defp required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _ -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp invalid_id_reason(:conversation_id), do: :invalid_conversation_id
  defp invalid_id_reason(:club_id), do: :invalid_club_id
  defp invalid_id_reason(:group_id), do: :invalid_group_id
end
