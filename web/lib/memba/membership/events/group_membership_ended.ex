defmodule Memba.Membership.Events.GroupMembershipEnded do
  @moduledoc """
  Fact that one exact custom GroupMembership ended.
  """

  @derive Jason.Encoder
  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :idempotency_key,
    :reason
  ]
  defstruct [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :idempotency_key,
    :reason,
    :actor_person_id,
    :removal_operation_id
  ]
end
