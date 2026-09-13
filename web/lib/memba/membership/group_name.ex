defmodule Memba.Membership.GroupName do
  @moduledoc """
  Defines the club-local comparison key for conversation-group display names.

  Group names retain their original Unicode display value. The derived key is
  only for case-insensitive uniqueness checks and read-model lookup constraints.
  """

  @spec uniqueness_key(String.t()) :: String.t()
  def uniqueness_key(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
  end
end
