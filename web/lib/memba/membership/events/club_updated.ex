defmodule Memba.Membership.Events.ClubUpdated do
  @moduledoc """
  Event raised when a club's staff-managed display name or public slug changes.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :name, :slug]
  defstruct [:club_id, :name, :slug]
end
