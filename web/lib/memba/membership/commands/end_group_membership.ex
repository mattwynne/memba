defmodule Memba.Membership.Commands.EndGroupMembership do
  @moduledoc """
  Internal command to end one exact first-class custom GroupMembership.

  Naming the exact `group_membership_id` prevents delayed work from ending a
  later admission for the same club membership and group. The public,
  actor-bearing removal use case is intentionally deferred.
  """

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
    :reason
  ]
end
