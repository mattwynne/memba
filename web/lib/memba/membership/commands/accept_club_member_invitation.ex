defmodule Memba.Membership.Commands.AcceptClubMemberInvitation do
  @moduledoc """
  Command to mark a pending club member invitation accepted.

  Membership creation is orchestrated by later application-service work; the
  invitation records the accepted person and membership identities so successful
  acceptance/profile completion is one-use and idempotent.
  """

  @enforce_keys [:invitation_id, :person_id, :membership_id]
  defstruct [:invitation_id, :person_id, :membership_id]
end
