defmodule Memba.Membership.Commands.UpdateClub do
  @moduledoc """
  Command to update a club's staff-managed display name and public slug.
  """

  @enforce_keys [:club_id, :name, :slug]
  defstruct [:club_id, :name, :slug]
end
