defmodule Memba.Membership.Events.ClubMemberInvitationResent do
  @moduledoc """
  Event raised when a pending club member invitation is resent.
  """

  @derive Jason.Encoder
  @enforce_keys [:invitation_id, :token_hash]
  defstruct [:invitation_id, :token_hash]
end
