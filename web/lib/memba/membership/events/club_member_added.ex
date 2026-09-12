defmodule Memba.Membership.Events.ClubMemberAdded do
  @moduledoc """
  Event raised when a person becomes an active member of a club.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :membership_id, :person_id]
  defstruct [:club_id, :membership_id, :person_id]
end
