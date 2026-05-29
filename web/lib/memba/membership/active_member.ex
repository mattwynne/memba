defmodule Memba.Membership.ActiveMember do
  @moduledoc """
  Public read model for an active club member.

  This struct is returned from the Membership context boundary so callers do not
  depend on the context's projection schemas or tables.
  """

  @enforce_keys [:id, :name, :email]
  defstruct [:id, :name, :email]
end
