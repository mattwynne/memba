defmodule Memba.Messaging.ConversationAccess do
  @moduledoc """
  Access-level rules for conversation-to-group grants.

  Persisted access levels are `"read"` and `"write"`. Write access includes read
  access; read access does not include write access.
  """

  @access_levels ["read", "write"]

  @doc """
  Normalize a caller/event supplied access level.
  """
  def normalize_access_level(:read), do: {:ok, "read"}
  def normalize_access_level(:write), do: {:ok, "write"}

  def normalize_access_level(access_level) when is_binary(access_level) do
    access_level = access_level |> String.trim() |> String.downcase()

    if access_level in @access_levels do
      {:ok, access_level}
    else
      {:error, :invalid_access_level}
    end
  end

  def normalize_access_level(_access_level), do: {:error, :invalid_access_level}

  @doc """
  Return persisted grant levels that satisfy the requested access level.
  """
  def grant_levels_including("read"), do: ["read", "write"]
  def grant_levels_including("write"), do: ["write"]
end
