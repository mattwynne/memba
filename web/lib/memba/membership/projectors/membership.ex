defmodule Memba.Membership.Projectors.Membership do
  @moduledoc """
  Projects membership events into the Membership read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Membership",
    consistency: :strong

  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  project(%MemberAdded{} = event, fn multi ->
    Ecto.Multi.insert(multi, :membership_membership, %MembershipProjection{
      membership_id: event.membership_id,
      club_id: event.club_id,
      person_id: event.person_id,
      active: true
    })
  end)

  project(%MemberRemoved{} = event, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :membership_membership,
      membership_query(event.membership_id),
      set: [active: false]
    )
  end)

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
