defmodule Memba.Membership.Commands.AddCustomGroupMember do
  @moduledoc """
  Command for an authenticated person to add a club member to a custom group.

  The command is routed to the Club aggregate by `club_id`. It carries the
  authenticated actor separately from the target membership/person pair so
  admission policy is decided from current membership, group membership, role,
  permission, and group identity state at the authoritative write boundary.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id, :actor_person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id, :actor_person_id]
end
