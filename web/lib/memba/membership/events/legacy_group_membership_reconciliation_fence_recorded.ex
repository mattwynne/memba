defmodule Memba.Membership.Events.LegacyGroupMembershipReconciliationFenceRecorded do
  @moduledoc """
  Fact naming the last Club-stream version from which legacy relations may be
  reconciled for one declared namespace/version.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :namespace, :source_stream_version]
  defstruct [:club_id, :namespace, :source_stream_version]
end
