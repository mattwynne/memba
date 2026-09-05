defmodule Memba.Membership.Commands.CreateGroup do
  @moduledoc """
  Internal command to create a club-scoped conversation group.

  The caller supplies the club aggregate identity as `club_id` and the group
  identity as `group_id`. When `email_slug` is supplied, creation records the
  routing key as a separate immutable fact. Reissuing the same command for a
  matching historic group appends that missing fact without replacing its
  original creation event.

  This command is registered for system-group policy/backfill work and the
  event-sourced group foundation. It is not a public custom-group API in this
  slice; external callers use `Memba.Membership`, which intentionally exposes no
  custom-group mutation functions yet.
  """

  @enforce_keys [:club_id, :group_id, :name]
  defstruct [:club_id, :group_id, :email_slug, :group_key, :name]
end
