defmodule Memba.Membership.Commands.AddClubMember do
  @moduledoc """
  Command to add a person as an active member of a club.

  The command is routed to the Club aggregate by `club_id`. The caller also
  supplies the new membership and person identities.
  """

  @enforce_keys [:membership_id, :club_id, :person_id]
  defstruct [:membership_id, :club_id, :person_id]
end
