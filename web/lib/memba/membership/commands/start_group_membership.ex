defmodule Memba.Membership.Commands.StartGroupMembership do
  @moduledoc """
  Internal command to start one first-class custom GroupMembership.

  The Club aggregate remains the consistency boundary for this slice.
  `club_membership_id` is the existing durable club membership identity; it is
  not a second club-membership entity.
  """

  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id
  ]
  defstruct [:club_id, :group_id, :group_membership_id, :club_membership_id, :person_id]
end
