defmodule Memba.Membership.Policies.ClearRemovedGroupMemberFollows do
  @moduledoc """
  Clears follows when club departure removes a person from custom groups.

  Actor-authorized custom-group departure preserves follows so they can resume
  after rejoining. Club departure retains the earlier cleanup behaviour. The
  existing subscription identity remains stable across that distinction.
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
  def handle(
        %GroupMemberRemoved{actor_person_id: nil, removal_operation_id: nil} = event,
        _metadata
      ) do
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
      case Messaging.unfollow_conversation(
             %{
               club_id: event.club_id,
               conversation_id: conversation.conversation_id,
               member_id: event.person_id
             },
             consistency: [ConversationFollow]
           ) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end
end
