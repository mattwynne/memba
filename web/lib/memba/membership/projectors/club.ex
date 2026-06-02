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
  alias Memba.Membership.Slug

  project(%ClubCreated{} = event, fn multi ->
    with {:ok, slug} <- projected_slug(event) do
      Ecto.Multi.insert(multi, :membership_club, %ClubProjection{
        club_id: event.club_id,
        name: event.name,
        slug: slug
      })
    end
  end)

  defp projected_slug(%ClubCreated{} = event) do
    case Slug.validate(event.slug) do
      {:ok, slug} -> {:ok, slug}
      {:error, reason} -> {:error, {:invalid_club_created_slug, reason}}
    end
  end
end
