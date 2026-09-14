defmodule Memba.Membership.Commands.RemoveGroupMember do
  @moduledoc """
  Internal command to remove a club membership from a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being removed.

  This is a trusted internal command registered for system-group policy work and
  event-sourced fixture setup. It is not the public, actor-authorized path for
  changing custom-group membership.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
