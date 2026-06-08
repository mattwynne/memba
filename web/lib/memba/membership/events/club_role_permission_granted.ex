defmodule Memba.Membership.Events.ClubRolePermissionGranted do
  @moduledoc """
  Event raised when an app-defined permission has been granted to a club role.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :role_id, :permission]
  defstruct [:club_id, :role_id, :permission]
end
