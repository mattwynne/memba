defmodule Memba.Membership.Commands.RemoveCustomGroupMember do
  @moduledoc """
  Command for an authenticated person to end one exact custom GroupMembership.

  `club_membership_id` is the existing durable club membership identity. The
  caller-generated `removal_operation_id` identifies the removal attempt and
  must be reused after an uncertain result.
  """

  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id
  ]
  defstruct @enforce_keys
end
