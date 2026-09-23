defmodule Memba.Membership.Commands.RecordLegacyGroupMembershipReconciliationFence do
  @moduledoc """
  Records the immutable Club-stream source boundary used by legacy group
  membership reconciliation.
  """

  @enforce_keys [:club_id, :namespace, :expected_stream_version]
  defstruct [:club_id, :namespace, :expected_stream_version]
end
