defmodule Memba.Membership.Commands.ReconcileLegacyAdminHistory do
  @moduledoc """
  Operator-only command to append missing legacy Admin role facts.

  The Club aggregate derives the deterministic Admin role identity, key, name,
  and permission. Callers only identify the active legacy membership that should
  have the built-in Admin assignment reconciled into event history.
  """

  @enforce_keys [:club_id, :membership_id, :person_id]
  defstruct [:club_id, :membership_id, :person_id]
end
