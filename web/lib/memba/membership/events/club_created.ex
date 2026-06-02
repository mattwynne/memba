defmodule Memba.Membership.Events.ClubCreated do
  @moduledoc """
  Event raised when a club has been created.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :name, :slug]
  defstruct [:club_id, :name, :slug]
end
