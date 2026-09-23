defmodule Memba.Messaging.Events.GroupMembershipSubscriptionRevocationRecorded do
  @moduledoc "Permanent tombstone for one GroupMembership in a person's subscription stream."
  @derive Jason.Encoder
  @enforce_keys [:person_id, :group_membership_id, :revocation_id]
  defstruct @enforce_keys
end
