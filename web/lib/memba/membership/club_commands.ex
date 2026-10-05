defmodule Memba.Membership.ClubCommands do
  @moduledoc """
  Prepare staff club creation and update commands without dispatching them.

  The projected slug check provides early feedback; the Club aggregate remains
  responsible for the serialized write decision. Reuse the same club ID when
  retrying an uncertain create outcome.
  """

  alias Memba.ID
  alias Memba.Membership.Commands.{CreateClub, UpdateClub}
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Slug
  alias Memba.Repo

  def prepare_create(attrs) when is_map(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, slug} <- club_slug(attrs, name),
         command = %CreateClub{club_id: club_id, name: name, slug: slug},
         :ok <- prevent_duplicate_slug(command) do
      {:ok, command}
    end
  end

  def prepare_update(attrs) when is_map(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, club_id} <- cast_club_id(club_id),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, slug} <- fetch_required(attrs, :slug),
         {:ok, slug} <- Slug.validate(slug),
         command = %UpdateClub{club_id: club_id, name: name, slug: slug},
         :ok <- prevent_duplicate_slug(command) do
      {:ok, command}
    end
  end

  defp prevent_duplicate_slug(%CreateClub{slug: slug}) do
    case Repo.get_by(Club, slug: slug) do
      nil -> :ok
      %Club{} -> {:error, :slug_taken}
    end
  end

  defp prevent_duplicate_slug(%UpdateClub{slug: slug, club_id: club_id}) do
    case Repo.get_by(Club, slug: slug) do
      nil -> :ok
      %Club{club_id: ^club_id} -> :ok
      %Club{} -> {:error, :slug_taken}
    end
  end

  defp club_slug(attrs, name) do
    case fetch_optional(attrs, :slug) do
      {:ok, ""} -> Slug.default_from_name(name) |> Slug.validate()
      {:ok, slug} -> Slug.validate(slug)
      :error -> Slug.default_from_name(name) |> Slug.validate()
    end
  end

  defp cast_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :invalid_club_id}
    end
  end

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
  end
end
