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
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  project(%MemberAdded{} = event, fn multi ->
    Ecto.Multi.insert(multi, :membership_membership, %MembershipProjection{
      membership_id: event.membership_id,
      club_id: event.club_id,
      person_id: event.person_id,
      active?: true
    })
  end)
end
