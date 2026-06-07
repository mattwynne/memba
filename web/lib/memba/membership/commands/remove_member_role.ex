defmodule Memba.Membership.Commands.RemoveMemberRole do
  @moduledoc """
  Command to remove a club role assignment from a member.

  The caller supplies the club aggregate identity as `club_id`.
  """

  @enforce_keys [:club_id, :membership_id, :person_id, :role_id]
  defstruct [:club_id, :membership_id, :person_id, :role_id, :removed_by_person_id]
end
