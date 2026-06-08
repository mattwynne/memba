defmodule Memba.Membership.Commands.GrantClubRolePermission do
  @moduledoc """
  Command to grant an app-defined permission to a club role.

  The caller supplies the club aggregate identity as `club_id`.
  """

  @enforce_keys [:club_id, :role_id, :permission]
  defstruct [:club_id, :role_id, :permission]
end
