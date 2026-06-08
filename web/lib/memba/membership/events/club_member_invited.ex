defmodule Memba.Membership.Events.ClubMemberInvited do
  @moduledoc """
  Event raised when a club member invitation is pending for an email address.
  """

  @derive Jason.Encoder
  @enforce_keys [:invitation_id, :club_id, :email, :normalized_email, :token_hash]
  defstruct [:invitation_id, :club_id, :email, :normalized_email, :token_hash]
end
