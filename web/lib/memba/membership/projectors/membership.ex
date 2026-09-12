defmodule Memba.Membership.Projectors.Membership do
  @moduledoc """
  Projects membership events into the Membership read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Membership",
    consistency: :strong

  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  project(%ClubMemberAdded{} = event, fn multi ->
    project_member_added(multi, event)
  end)

  project(%LegacyMemberAdded{} = event, fn multi ->
    project_member_added(multi, event)
  end)

  project(%ClubMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  project(%LegacyMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  defp project_member_added(multi, event) do
    Ecto.Multi.insert(multi, :membership_membership, %MembershipProjection{
      membership_id: event.membership_id,
      club_id: event.club_id,
      person_id: event.person_id,
      active: true
    })
  end

  defp project_member_removed(multi, event) do
    Ecto.Multi.update_all(
      multi,
      :membership_membership,
      membership_query(event.membership_id),
      set: [active: false]
    )
  end

  defp membership_query(membership_id) do
    import Ecto.Query

    from(membership in MembershipProjection,
      where: membership.membership_id == ^membership_id
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
