defmodule Memba.Membership.CustomGroupAdmission do
  @moduledoc """
  Result of the authenticated custom-group admission use case.

  `transition` is `:member_added` only when the command committed a new
  `GroupMemberAdded` event. An idempotent retry for an active group member
  returns `:already_member`.
  """

  @type transition :: :member_added | :already_member

  @type t :: %__MODULE__{
          club_id: String.t(),
          group_id: String.t(),
          membership_id: String.t(),
          person_id: String.t(),
          actor_person_id: String.t(),
          transition: transition()
        }

  @enforce_keys [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :transition
  ]
  defstruct [:club_id, :group_id, :membership_id, :person_id, :actor_person_id, :transition]
end
