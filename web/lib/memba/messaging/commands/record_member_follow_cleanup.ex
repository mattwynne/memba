defmodule Memba.Messaging.Commands.RecordMemberFollowCleanup do
  @moduledoc """
  Records a custom-group removal cutoff for one member in Messaging.
  """

  @enforce_keys [
    :eligibility_id,
    :club_id,
    :group_id,
    :member_id,
    :cleanup_id,
    :membership_generation
  ]
  defstruct [
    :eligibility_id,
    :club_id,
    :group_id,
    :member_id,
    :cleanup_id,
    :membership_generation
  ]
end
