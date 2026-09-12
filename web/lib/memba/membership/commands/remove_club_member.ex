defmodule Memba.Membership.Commands.RemoveClubMember do
  @moduledoc """
  Command to remove a person from active club membership.

  The command is routed to the Club aggregate by `club_id`. The membership and
  person identities must match the Club's active club memberships.
  """

  @enforce_keys [:club_id, :membership_id, :person_id]
  defstruct [:club_id, :membership_id, :person_id]
end
