defmodule Memba.Membership.Events.ClubRoleAssignedToMember do
  @moduledoc """
  Event raised when a club role has been assigned to an active club member.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :membership_id, :person_id, :role_id]
  defstruct [
    :club_id,
    :membership_id,
    :person_id,
    :role_id,
    :assigned_by_person_id,
    :assignment_source
  ]
end
