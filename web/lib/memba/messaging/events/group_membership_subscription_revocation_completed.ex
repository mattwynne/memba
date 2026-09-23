defmodule Memba.Messaging.Events.GroupMembershipSubscriptionRevocationCompleted do
  @moduledoc "Durable receipt that one GroupMembership subscription revocation completed."
  @derive Jason.Encoder
  @enforce_keys [:person_id, :group_membership_id, :revocation_id]
  defstruct @enforce_keys
end
