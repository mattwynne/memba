defmodule Memba.Membership.Commands.AddMember do
  @moduledoc """
  Command to add a person as an active member of a club.

  The caller supplies the aggregate identity as `membership_id`.
  """

  @enforce_keys [:membership_id, :club_id, :person_id]
  defstruct [:membership_id, :club_id, :person_id]
end
