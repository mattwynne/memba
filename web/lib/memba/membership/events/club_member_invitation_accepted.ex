defmodule Memba.Membership.Events.ClubMemberInvitationAccepted do
  @moduledoc """
  Event raised when a pending club member invitation has been accepted.
  """

  @derive Jason.Encoder
  @enforce_keys [:invitation_id, :person_id, :membership_id]
  defstruct [:invitation_id, :person_id, :membership_id]
end
