defmodule Memba.Membership.Commands.DefineClubRole do
  @moduledoc """
  Command to define a club-scoped role as a permission bundle.

  The caller supplies the club aggregate identity as `club_id` and the role
  identity as `role_id`.
  """

  @enforce_keys [:club_id, :role_id, :name]
  defstruct [:club_id, :role_id, :role_key, :name]
end
