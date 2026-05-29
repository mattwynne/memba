defmodule Memba.Membership.Events.MemberAdded do
  @moduledoc """
  Event raised when a person has been added as an active club member.
  """

  @derive Jason.Encoder
  @enforce_keys [:membership_id, :club_id, :person_id]
  defstruct [:membership_id, :club_id, :person_id]
end
