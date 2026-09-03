defmodule Memba.Membership.Events.GroupMemberAdded do
  @moduledoc """
  Event raised when a club membership has been added to a conversation group.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
