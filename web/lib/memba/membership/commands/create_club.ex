defmodule Memba.Membership.Commands.CreateClub do
  @moduledoc """
  Command to create a club in the Membership context.

  The caller supplies the aggregate identity as `club_id`.
  """

  @enforce_keys [:club_id, :name]
  defstruct [:club_id, :name]
end
