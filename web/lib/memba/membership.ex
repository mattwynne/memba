defmodule Memba.Membership do
  @moduledoc """
  Public query API for the Membership bounded context.
  """

  alias Memba.Membership.Projections.Club
  alias Memba.Repo

  @doc """
  Fetch a projected club read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_club(club_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
      Repo.get(Club, club_id)
    else
      :error -> nil
    end
  end
end
