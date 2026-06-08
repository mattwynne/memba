defmodule Memba.Membership.Commands.InviteClubMember do
  @moduledoc """
  Command to create a pending invitation for an email address to join a club.

  The caller supplies the aggregate identity as `invitation_id` and stores only
  the invitation token hash in Membership.
  """

  @enforce_keys [:invitation_id, :club_id, :email, :token_hash]
  defstruct [:invitation_id, :club_id, :email, :token_hash]
end
