defmodule Memba.Membership.Commands.RemoveCustomGroupMember do
  @moduledoc """
  Command for an authenticated person to remove a club member from a custom group.

  The command is routed to the Club aggregate by `club_id`. It carries the
  authenticated actor separately from the target membership/person pair so the
  removal policy is decided from current aggregate state.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id, :actor_person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id, :actor_person_id]
end
