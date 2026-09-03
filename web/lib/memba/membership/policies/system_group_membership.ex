defmodule Memba.Membership.Policies.SystemGroupMembership do
  @moduledoc """
  Keeps built-in group memberships aligned with membership and role lifecycle events.

  The release backfill seeds existing clubs. This strongly consistent policy starts
  from current events only and holds no process state, so future lifecycle events can
  be handled idempotently by the Club aggregate.
  """

  use Commanded.Event.Handler,
    application: Memba.Membership.App,
    name: "Memba.Membership.Policies.SystemGroupMembership",
    consistency: :strong,
    start_from: :current
end
