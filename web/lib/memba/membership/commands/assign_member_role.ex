defmodule Memba.Membership.Commands.AssignMemberRole do
  @moduledoc """
  Command to assign a club role to an active member.

  The caller supplies the club aggregate identity as `club_id`. Application
  services are responsible for checking that `membership_id` is currently active
  before dispatching.
  """

  @enforce_keys [:club_id, :membership_id, :person_id, :role_id]
  defstruct [:club_id, :membership_id, :person_id, :role_id, :assigned_by_person_id]
end
