defmodule Memba.Membership.Events.MemberRemoved do
  @moduledoc """
  Event raised when a person has been removed from active club membership.
  """

  @derive Jason.Encoder
  @enforce_keys [:membership_id]
  defstruct [:membership_id, :club_id, :person_id]
end
