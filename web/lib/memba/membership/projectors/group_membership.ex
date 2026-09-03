defmodule Memba.Membership.Projectors.GroupMembership do
  @moduledoc """
  Projects group membership events into the Membership group-membership read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.GroupMembership",
    consistency: :strong

  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection

  project(%GroupMemberAdded{} = event, fn multi ->
    upsert_group_membership(multi, event, true)
  end)

  project(%GroupMemberRemoved{} = event, fn multi ->
    upsert_group_membership(multi, event, false)
  end)

  defp upsert_group_membership(multi, event, active) do
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :membership_group_membership,
      %GroupMembershipProjection{
        club_id: event.club_id,
        group_id: event.group_id,
        membership_id: event.membership_id,
        person_id: event.person_id,
        active: active,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          person_id: event.person_id,
          active: active,
          updated_at: now
        ]
      ],
      conflict_target: [:group_id, :membership_id]
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
