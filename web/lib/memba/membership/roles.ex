defmodule Memba.Membership.Roles do
  @moduledoc """
  Built-in Membership role definitions.
  """

  alias Memba.ID

  @membership_administrator_key "admin"
  @membership_administrator_role_id_seed "membership_administrator"
  @membership_administrator_name "Admin"

  @doc "Stable role key for the built-in Admin role."
  def membership_administrator_key, do: @membership_administrator_key

  @doc "Display name for the built-in Admin role."
  def membership_administrator_name, do: @membership_administrator_name

  @doc """
  Deterministic role ID for a club's built-in Admin role.
  """
  def membership_administrator_role_id(club_id) when is_binary(club_id) do
    ID.deterministic(:role, [@membership_administrator_role_id_seed, club_id])
  end
end
