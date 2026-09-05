defmodule Memba.Membership.Commands.AssignGroupEmailSlug do
  @moduledoc """
  Internal command to assign a stable inbound-email routing slug to a group.

  Assignment is one-time: the Club aggregate permits an idempotent repeat of
  the same normalized slug, but does not permit the slug to change.
  """

  @enforce_keys [:club_id, :group_id, :email_slug]
  defstruct [:club_id, :group_id, :email_slug]
end
