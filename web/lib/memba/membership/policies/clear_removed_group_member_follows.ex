defmodule Memba.Membership.Policies.ClearRemovedGroupMemberFollows do
  @moduledoc """
  Clears Messaging follows when a custom-group membership ends.

  The handler subscribes to Membership facts and coordinates the cross-context
  consequence through Messaging's public query and command APIs. Starting from
  origin makes a first deployment repair earlier removals, while the existing
  idempotent unfollow command makes repeated delivery and replay safe.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.ClearRemovedGroupMemberFollows",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.Projectors.ConversationFollow

  @impl Commanded.Event.Handler
  def handle(%GroupMemberRemoved{} = event, _metadata) do
    if SystemGroups.custom_group?(event) do
      clear_conversation_follows(event)
    else
      :ok
    end
  end

  def handle(_event, _metadata), do: :ok

  defp clear_conversation_follows(event) do
    event.group_id
    |> Messaging.list_conversations_for_group()
    |> Enum.reduce_while(:ok, fn conversation, :ok ->
      case unfollow(event, conversation.conversation_id) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp unfollow(event, conversation_id) do
    Messaging.unfollow_conversation(
      %{
        club_id: event.club_id,
        conversation_id: conversation_id,
        member_id: event.person_id
      },
      consistency: [ConversationFollow]
    )
  end
end
