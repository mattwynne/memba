defmodule Memba.Membership.Commands.AddCustomGroupMember do
  @moduledoc """
  Command for an authenticated person to add a club member to a custom group.

  The command is routed to the Club aggregate by `club_id`. It carries the
  authenticated actor separately from the target membership/person pair so
  admission policy is decided from current club membership, GroupMembership,
  role, permission, and group identity state at the authoritative write
  boundary. Every successful admission carries a fresh `group_membership_id`.
  """

  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :membership_id,
    :person_id,
    :actor_person_id
  ]
  defstruct [
    :club_id,
    :group_id,
    :group_membership_id,
    :membership_id,
    :person_id,
    :actor_person_id
  ]
end
