defmodule Memba.Membership.Events.MemberRoleRemoved do
  @moduledoc """
  Event raised when a club role assignment has been removed from a member.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :membership_id, :person_id, :role_id]
  defstruct [:club_id, :membership_id, :person_id, :role_id, :removed_by_person_id]
end
