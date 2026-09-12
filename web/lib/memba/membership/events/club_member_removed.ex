defmodule Memba.Membership.Events.ClubMemberRemoved do
  @moduledoc """
  Event raised when a person is removed from active club membership.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :membership_id, :person_id]
  defstruct [:club_id, :membership_id, :person_id]
end
