defmodule Memba.Membership.Commands.AddGroupMember do
  @moduledoc """
  Internal command to add a club membership to a conversation group.

  The caller supplies the club aggregate identity as `club_id` and identifies
  both the group and member being joined.

  This is a trusted internal command registered for system-group policy/backfill
  work and event-sourced fixture setup. It is not the actor-authorized path
  for changing custom-group membership. Web callers must prepare an actor-bearing
  command with `Memba.Membership.CustomGroup.Admit.prepare/1` and dispatch it
  through `Memba.Membership.CommandDispatch`. The Club aggregate authorizes it.
  """

  @enforce_keys [:club_id, :group_id, :membership_id, :person_id]
  defstruct [:club_id, :group_id, :membership_id, :person_id]
end
