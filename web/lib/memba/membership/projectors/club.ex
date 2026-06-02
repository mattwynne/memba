defmodule Memba.Membership.Projectors.Club do
  @moduledoc """
  Projects club events into the Membership club read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Club",
    consistency: :strong

  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Projections.Club, as: ClubProjection

  project(%ClubCreated{} = event, fn multi ->
    Ecto.Multi.insert(multi, :membership_club, %ClubProjection{
      club_id: event.club_id,
      name: event.name,
      slug: event.slug
    })
  end)
end
