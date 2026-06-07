defmodule Memba.Membership.Roles do
  @moduledoc """
  Built-in Membership role definitions.
  """

  alias Memba.ID

  @membership_administrator_key "membership_administrator"
  @membership_administrator_name "Membership Administrator"

  @doc "Stable role key for the built-in Membership Administrator role."
  def membership_administrator_key, do: @membership_administrator_key

  @doc "Display name for the built-in Membership Administrator role."
  def membership_administrator_name, do: @membership_administrator_name

  @doc """
  Deterministic role ID for a club's built-in Membership Administrator role.
  """
  def membership_administrator_role_id(club_id) when is_binary(club_id) do
    ID.deterministic(:role, [@membership_administrator_key, club_id])
  end
end
