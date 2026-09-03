defmodule Memba.Membership.Commands.AddGroupMember do
  @moduledoc """
  Internal command to add a club membership to a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being joined.

  This command is registered for system-group policy/backfill work and the
  event-sourced group foundation. It is not a public custom-group API in this
  slice; external callers use `Memba.Membership`, which intentionally exposes no
  custom-group mutation functions yet.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
