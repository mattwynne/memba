defmodule Memba.Messaging.Projectors.ConversationGroupAccess do
  @moduledoc """
  Projects conversation-to-group access events into the Messaging access read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Messaging.App,
    repo: Memba.Repo,
    name: "Memba.Messaging.Projectors.ConversationGroupAccess",
    consistency: :strong

  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection

  project(%ConversationAccessGrantedToGroup{} = event, fn multi ->
    with {:ok, access_level} <- ConversationAccess.normalize_access_level(event.access_level) do
      upsert_access(multi, event, access_level)
    end
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end

  defp upsert_access(multi, event, access_level) do
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :messaging_conversation_group_access,
      %ConversationGroupAccessProjection{
        conversation_id: event.conversation_id,
        club_id: event.club_id,
        group_id: event.group_id,
        access_level: access_level,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          access_level: access_level,
          updated_at: now
        ]
      ],
      conflict_target: [:conversation_id, :group_id]
    )
  end
end
