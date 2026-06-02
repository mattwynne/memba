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
  alias Memba.Membership.Events.ClubUpdated
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

  project(%ClubUpdated{} = event, fn multi ->
    with {:ok, slug} <- projected_slug(event) do
      Ecto.Multi.update_all(
        multi,
        :membership_club,
        club_query(event.club_id),
        set: [name: event.name, slug: slug, updated_at: DateTime.utc_now()]
      )
    end
  end)

  defp projected_slug(%ClubCreated{} = event) do
    case Slug.validate(event.slug) do
      {:ok, slug} -> {:ok, slug}
      {:error, reason} -> {:error, {:invalid_club_created_slug, reason}}
    end
  end

  defp projected_slug(%ClubUpdated{} = event) do
    case Slug.validate(event.slug) do
      {:ok, slug} -> {:ok, slug}
      {:error, reason} -> {:error, {:invalid_club_updated_slug, reason}}
    end
  end

  defp club_query(club_id) do
    Ecto.Query.from(club in ClubProjection, where: club.club_id == ^club_id)
  end
end
