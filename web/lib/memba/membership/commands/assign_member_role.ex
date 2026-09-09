defmodule Memba.Membership.Commands.AssignMemberRole do
  @moduledoc """
  Command to assign a club role to an active member.

  The caller supplies the club aggregate identity as `club_id`. The Club
  aggregate checks that `membership_id` and `person_id` identify an active
  membership before assigning the role.
  """

  @enforce_keys [:club_id, :membership_id, :person_id, :role_id]
  defstruct [:club_id, :membership_id, :person_id, :role_id, :assigned_by_person_id]
end
