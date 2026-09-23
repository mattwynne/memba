defmodule Memba.Membership.Commands.ReconcileLegacyGroupMembership do
  @moduledoc """
  Reconciles one legacy custom-group relation at a named Club-stream fence.

  This operator command carries the exact source fact and stream versions seen
  during canonical enumeration. The Club aggregate revalidates both before it
  creates first-class state.
  """

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
