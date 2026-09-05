defmodule Memba.Membership.Commands.CreateGroup do
  @moduledoc """
  Internal command to create a club-scoped conversation group.

  The caller supplies the club aggregate identity as `club_id` and the group
  identity as `group_id`. When supplied, `email_slug` is recorded as a separate
  immutable email-routing fact so historic `GroupCreated` events keep their
  original shape.

  This command is registered for system-group policy/backfill work and the
  event-sourced group foundation. It is not a public custom-group API in this
  slice; external callers use `Memba.Membership`, which intentionally exposes no
  custom-group mutation functions yet.
  """

  @enforce_keys [:club_id, :group_id, :name]
  defstruct [:club_id, :group_id, :group_key, :email_slug, :name]
end
