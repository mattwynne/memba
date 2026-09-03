defmodule Memba.Membership.Commands.RemoveGroupMember do
  @moduledoc """
  Command to remove a club membership from a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being removed.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
