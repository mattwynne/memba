defmodule Memba.Membership.Events.GroupMembershipStarted do
  @moduledoc """
  Fact that one uninterrupted custom GroupMembership started.

  `club_membership_id` is the existing durable club membership identity exposed
  with qualified language at this new boundary.
  """

  @derive Jason.Encoder
  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id
  ]
  defstruct [:club_id, :group_id, :group_membership_id, :club_membership_id, :person_id]
end
