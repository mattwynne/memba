defmodule Memba.MembershipFixtures do
  @moduledoc """
  Shared fixtures for Membership projection tests.
  """

  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Slug
  alias Memba.Repo

  def membership_club_attrs(attrs \\ []) when is_list(attrs) do
    club_id = Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0)

    name =
      Keyword.get(attrs, :name, Keyword.get(attrs, :club_name, "Kootenay Mountaineering Club"))

    %{
      club_id: club_id,
      name: name,
      slug: Keyword.get_lazy(attrs, :slug, fn -> membership_club_slug(name, club_id) end)
    }
  end

  def membership_club_slug(name, club_id) when is_binary(name) and is_binary(club_id) do
    suffix =
      club_id
      |> String.replace("-", "")
      |> String.slice(0, 8)

    max_base_length = Slug.max_length() - String.length(suffix) - 1

    base =
      name
      |> Slug.default_from_name()
      |> String.slice(0, max_base_length)
      |> String.trim("-")

    case base do
      "" -> suffix
      base -> "#{base}-#{suffix}"
    end
  end

  def insert_membership_club!(attrs \\ []) when is_list(attrs) do
    attrs = membership_club_attrs(attrs)

    Repo.insert!(%Club{
      club_id: attrs.club_id,
      name: attrs.name,
      slug: attrs.slug
    })
  end
end
