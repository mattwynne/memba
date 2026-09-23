defmodule Memba.Membership.Policies.ClearRemovedGroupMemberFollows do
  @moduledoc """
  Retired follow-cleanup handler retained as a durable no-op.

  The subscription name and checkpoint are intentionally preserved so deployed
  installations continue from their existing position without replaying or
  replacing subscription history. Group departure no longer changes Messaging
  follow preferences; current group participation makes a preserved follow
  dormant until the person rejoins.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.ClearRemovedGroupMemberFollows",
    consistency: :strong,
    start_from: :origin

  @impl Commanded.Event.Handler
  def handle(_event, _metadata), do: :ok
end
