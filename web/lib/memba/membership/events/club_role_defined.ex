defmodule Memba.Membership.Events.ClubRoleDefined do
  @moduledoc """
  Event raised when a club-scoped role has been defined.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :role_id, :name]
  defstruct [:club_id, :role_id, :role_key, :name]
end
