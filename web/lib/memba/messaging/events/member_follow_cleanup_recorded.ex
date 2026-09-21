defmodule Memba.Messaging.Events.MemberFollowCleanupRecorded do
  @moduledoc """
  Durable Messaging fact recording the membership generation invalidated by a
  custom-group removal.
  """

  @derive Jason.Encoder
  @enforce_keys [:club_id, :group_id, :member_id, :cleanup_id, :membership_generation]
  defstruct [:club_id, :group_id, :member_id, :cleanup_id, :membership_generation]
end
