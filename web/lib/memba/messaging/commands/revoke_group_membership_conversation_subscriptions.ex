defmodule Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions do
  @moduledoc """
  Permanently revokes one exact GroupMembership's subscription grants.

  The command always records a completion receipt, including when no grant used
  the membership.
  """

  @enforce_keys [:person_id, :group_membership_id, :revocation_id]
  defstruct @enforce_keys
end
