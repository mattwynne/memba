defmodule Memba.Membership.Policies.ClearRemovedGroupMemberFollows do
  @moduledoc """
  Retired legacy follow-cleanup subscriber.

  It remains registered at its historic subscription name so deployments can
  advance the old checkpoint without dispatching conversation-owned follow
  commands. First-class GroupMembership revocation is intentionally handled by
  a later person-subscription policy slice.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.ClearRemovedGroupMemberFollows",
    consistency: :strong,
    start_from: :origin

  @impl Commanded.Event.Handler
  def handle(_event, _metadata), do: :ok
end
