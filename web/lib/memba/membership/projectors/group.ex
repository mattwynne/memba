defmodule Memba.Membership.Projectors.Group do
  @moduledoc """
  Projects group definition events into the Membership group read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Group",
    consistency: :strong

  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Projections.Group, as: GroupProjection

  project(%GroupCreated{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :membership_group,
      %GroupProjection{
        club_id: event.club_id,
        group_id: event.group_id,
        group_key: event.group_key,
        name: event.name,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          group_key: event.group_key,
          name: event.name,
          updated_at: now
        ]
      ],
      conflict_target: :group_id
    )
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
