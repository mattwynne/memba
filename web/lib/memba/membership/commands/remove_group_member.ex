defmodule Memba.Membership.Commands.RemoveGroupMember do
  @moduledoc """
  Internal command to remove a club membership from a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being removed.

  This command is registered for system-group policy/backfill work and the
  event-sourced group foundation. It is not a public custom-group API in this
  slice; external callers use `Memba.Membership`, which intentionally exposes no
  custom-group mutation functions yet.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
