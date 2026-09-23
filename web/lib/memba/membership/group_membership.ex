defmodule Memba.Membership.GroupMembership do
  @moduledoc """
  Command-side value describing one uninterrupted custom-group membership.

  `club_membership_id` is the existing durable club membership identity. A
  `group_membership_id` identifies only this admission and is never reused by a
  later admission.
  """

  @type status :: :current | :ended

  @type t :: %__MODULE__{
          club_id: String.t(),
          group_id: String.t(),
          group_membership_id: String.t(),
          club_membership_id: String.t(),
          person_id: String.t(),
          status: status(),
          end_idempotency_key: String.t() | nil,
          end_reason: String.t() | nil
        }

  @enforce_keys [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :status
  ]
  defstruct [
    :club_id,
    :group_id,
    :group_membership_id,
    :club_membership_id,
    :person_id,
    :status,
    :end_idempotency_key,
    :end_reason
  ]
end
