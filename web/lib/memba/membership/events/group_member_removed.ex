defmodule Memba.Membership.Events.GroupMemberRemoved do
  @moduledoc """
  Event raised when a club membership has been removed from a conversation group.

  Actor-authorized custom-group removals include `actor_person_id` and the
  caller-generated `removal_operation_id`. Trusted system and club-departure
  flows, and legacy facts, leave those additive fields unset.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id
  ]
end
