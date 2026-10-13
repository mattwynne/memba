defmodule Memba.Membership.Commands.MergePerson do
  @moduledoc """
  Merge a source person into the target Person aggregate identified by `person_id`.
  """

  @enforce_keys [:person_id, :source_person_id, :email_addresses]
  defstruct [:person_id, :source_person_id, :email_addresses]
end
