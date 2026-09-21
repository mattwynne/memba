defmodule Memba.Membership.Policies.ClearRemovedGroupMemberFollows do
  @moduledoc """
  Clears Messaging follows when a custom-group membership ends.

  The handler subscribes to Membership facts and coordinates the cross-context
  consequence through Messaging's public API. Starting from origin repairs
  earlier removals. Each removal's durable EventStore identity becomes the
  Messaging cleanup key, making repeated delivery and replay safe even after a
  genuine re-add and new follow.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.ClearRemovedGroupMemberFollows",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging

  @impl Commanded.Event.Handler
  def handle(%GroupMemberRemoved{} = event, metadata) do
    if SystemGroups.custom_group?(event) do
      clear_conversation_follows(event, metadata)
    else
      :ok
    end
  end

  def handle(_event, _metadata), do: :ok

  defp clear_conversation_follows(event, metadata) do
    Messaging.clear_removed_group_member_follows(%{
      club_id: event.club_id,
      group_id: event.group_id,
      member_id: event.person_id,
      cleanup_id: cleanup_id(event, metadata),
      checkpoint: cleanup_checkpoint(metadata)
    })
  end

  defp cleanup_id(event, metadata) do
    Map.get(metadata, :event_id) ||
      Map.get(metadata, "event_id") ||
      Enum.join(
        [
          "historic-group-member-removal",
          event.club_id,
          event.group_id,
          event.membership_id,
          event.person_id
        ],
        ":"
      )
  end

  defp cleanup_checkpoint(metadata) do
    Map.get(metadata, :event_number) ||
      Map.get(metadata, "event_number") ||
      Memba.ProjectionBarrier.current_checkpoint()
  end
end
