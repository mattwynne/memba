defmodule Memba.Membership.Commands.CreateGroup do
  @moduledoc """
  Internal command to create a club-scoped conversation group.

  The caller supplies the club aggregate identity as `club_id` and the group
  identity as `group_id`. When `email_slug` is supplied, creation records the
  routing key as a separate immutable fact. Reissuing the same command for a
  matching historic group appends that missing fact without replacing its
  original creation event.

  This is a trusted internal command registered for system-group policy/backfill
  work and event-sourced fixture setup. It deliberately remains actor-free so
  those existing producers can replay and repair historical group definitions.

  User-facing custom-group creation must instead prepare an actor-bearing
  command with `Memba.Membership.CustomGroup.Create.prepare/1` and dispatch it
  through `Memba.Membership.CommandDispatch`. The Club aggregate authorizes it.
  """

  @enforce_keys [:club_id, :group_id, :name]
  defstruct [:club_id, :group_id, :email_slug, :group_key, :name]
end
