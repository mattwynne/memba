defmodule Memba.Membership.GroupName do
  @moduledoc """
  Defines display-name normalization and the club-local comparison key for
  conversation-group names.

  Group creation reuses the Club aggregate's existing nonblank, outer-trimmed
  display-name semantics. Group names retain their Unicode display value; the
  derived key is only for case-insensitive uniqueness checks and read-model
  lookup constraints.
  """

  @spec normalize(term()) :: {:ok, String.t()} | {:error, :invalid_name}
  def normalize(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  def normalize(_name), do: {:error, :invalid_name}

  @spec uniqueness_key(String.t()) :: String.t()
  def uniqueness_key(name) when is_binary(name) do
    name
    |> String.trim()
    |> String.downcase()
  end
end
