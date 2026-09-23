defmodule Memba.Membership.FencedClubAuthorityState do
  @moduledoc """
  Opaque, server-signed canonical Club state reconstructed at a global fence.

  Reconciliation may cache this immutable value within a batch without making
  caller-supplied projection or aggregate state trusted authority.
  """

  @opaque t :: %__MODULE__{}
  @enforce_keys [:club_id, :fence_position, :stream_version, :club, :signature]
  defstruct @enforce_keys
end
