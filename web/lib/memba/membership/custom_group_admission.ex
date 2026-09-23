defmodule Memba.Membership.CustomGroupAdmission do
  @moduledoc """
  Result of the authenticated custom-group admission use case.

  `transition` is `:member_added` only when the command committed a new
  `GroupMembershipStarted` fact. An exact retry that reuses the current
  `group_membership_id` and the same command data returns `:already_member`.

  `club_membership_id` is the qualified name for the existing durable
  `membership_id`; both fields contain the same value during compatibility.
  """

  @type transition :: :member_added | :already_member

  @type t :: %__MODULE__{
          club_id: String.t(),
          group_id: String.t(),
          membership_id: String.t(),
          club_membership_id: String.t(),
          group_membership_id: String.t(),
          person_id: String.t(),
          actor_person_id: String.t(),
          transition: transition()
        }

  @enforce_keys [
    :club_id,
    :group_id,
    :membership_id,
    :club_membership_id,
    :group_membership_id,
    :person_id,
    :actor_person_id,
    :transition
  ]
  defstruct [
    :club_id,
    :group_id,
    :membership_id,
    :club_membership_id,
    :group_membership_id,
    :person_id,
    :actor_person_id,
    :transition
  ]
end
