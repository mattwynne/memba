defmodule Memba.Membership.Events.PersonMerged do
  @moduledoc """
  Records that another person was merged into this surviving person.

  The complete email state makes the surviving Person stream authoritative on replay.
  """

  @derive Jason.Encoder
  @enforce_keys [:person_id, :source_person_id, :email_addresses, :primary_email]
  defstruct [:person_id, :source_person_id, :email_addresses, :primary_email]
end
