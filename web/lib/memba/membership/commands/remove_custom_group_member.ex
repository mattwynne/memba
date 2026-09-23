defmodule Memba.Membership.Commands.RemoveCustomGroupMember do
  @moduledoc """
  Command for an authenticated person to remove a current custom-group participant.

  The command is routed to the Club aggregate by `club_id`. The caller-generated
  `removal_operation_id` identifies this removal attempt across retries without
  introducing a separate group-membership lifecycle identity.
  """

  @enforce_keys [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id
  ]
  defstruct [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id
  ]
end
