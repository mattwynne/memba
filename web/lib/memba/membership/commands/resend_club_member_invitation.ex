defmodule Memba.Membership.Commands.ResendClubMemberInvitation do
  @moduledoc """
  Command to record a resend for an existing pending club member invitation.

  Resending rotates the stored invitation token hash while preserving the single
  pending invitation aggregate.
  """

  @enforce_keys [:invitation_id, :token_hash]
  defstruct [:invitation_id, :token_hash]
end
