defmodule Memba.Messaging.ConversationFollowPreparation do
  @moduledoc """
  Prepare raw follow and unfollow commands for system and email workflows.

  This boundary only checks required attributes; browser opt-in/out must use
  `Memba.Messaging.CurrentMemberConversationFollow` for current-member access.
  Dispatch remains the responsibility of the Messaging context API.
  """

  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation

  def prepare_follow(attrs) when is_map(attrs), do: prepare(attrs, FollowConversation)
  def prepare_unfollow(attrs) when is_map(attrs), do: prepare(attrs, UnfollowConversation)

  defp prepare(attrs, command_module) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, conversation_id} <- fetch_required(attrs, :conversation_id),
         {:ok, member_id} <- fetch_required(attrs, :member_id) do
      {:ok,
       struct(command_module,
         club_id: club_id,
         conversation_id: conversation_id,
         member_id: member_id
       )}
    end
  end

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end
end
