defmodule Memba.Membership.Commands.AddGroupMember do
  @moduledoc """
  Command to add a club membership to a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being joined.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
