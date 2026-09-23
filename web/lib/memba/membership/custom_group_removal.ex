defmodule Memba.Membership.CustomGroupRemoval do
  @moduledoc """
  Completed result of the authenticated custom-group removal use case.

  Success means the exact GroupMembership ended (or had already ended by this
  operation) and Messaging has durably recorded its subscription-revocation
  completion receipt.
  """

  @type transition :: :member_removed

  @enforce_keys [
    :club_id,
    :group_id,
    :membership_id,
    :club_membership_id,
    :group_membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id,
    :revocation_id,
    :subscription_revocation_completed,
    :transition
  ]
  defstruct @enforce_keys
end
