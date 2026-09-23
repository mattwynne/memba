defmodule Memba.Membership.CustomGroupRemoval do
  @moduledoc """
  Result of an authenticated custom-group removal.

  Exact retries return the same `:member_removed` outcome without emitting a
  second event, including when the former participant has since been re-added.
  """

  @type t :: %__MODULE__{
          club_id: String.t(),
          group_id: String.t(),
          membership_id: String.t(),
          person_id: String.t(),
          actor_person_id: String.t(),
          removal_operation_id: String.t(),
          transition: :member_removed
        }

  @enforce_keys [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id,
    :transition
  ]
  defstruct [
    :club_id,
    :group_id,
    :membership_id,
    :person_id,
    :actor_person_id,
    :removal_operation_id,
    :transition
  ]
end
