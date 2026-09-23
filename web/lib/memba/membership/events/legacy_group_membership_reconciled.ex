defmodule Memba.Membership.Events.LegacyGroupMembershipReconciled do
  @moduledoc """
  Fact that an active legacy custom-group relation was materialized at a named
  reconciliation fence without asserting an unproved historical interval.
  """

  @derive Jason.Encoder
  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :namespace,
    :fence_stream_version,
    :source_stream_version
  ]
  defstruct [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :namespace,
    :fence_stream_version,
    :source_stream_version
  ]
end
