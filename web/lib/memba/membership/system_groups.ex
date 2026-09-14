defmodule Memba.Membership.SystemGroups do
  @moduledoc """
  Built-in Membership conversation group definitions.
  """

  alias Memba.ID

  @system_group_id_seed "system-group"
  @everyone_key "everyone"
  @everyone_email_slug "everyone"
  @everyone_name "Everyone"
  @admin_key "admin"
  @admin_email_slug "admin"
  @admin_name "Admin"

  @doc "Stable group key for the built-in Everyone conversation group."
  def everyone_key, do: @everyone_key

  @doc "Stable email routing slug for the built-in Everyone conversation group."
  def everyone_email_slug, do: @everyone_email_slug

  @doc "Display name for the built-in Everyone conversation group."
  def everyone_name, do: @everyone_name

  @doc "Deterministic group ID for a club's built-in Everyone conversation group."
  def everyone_group_id(club_id) when is_binary(club_id) do
    group_id(club_id, @everyone_key)
  end

  @doc "Stable group key for the built-in Admin conversation group."
  def admin_key, do: @admin_key

  @doc "Stable email routing slug for the built-in Admin conversation group."
  def admin_email_slug, do: @admin_email_slug

  @doc "Display name for the built-in Admin conversation group."
  def admin_name, do: @admin_name

  @doc "Deterministic group ID for a club's built-in Admin conversation group."
  def admin_group_id(club_id) when is_binary(club_id) do
    group_id(club_id, @admin_key)
  end

  @doc """
  Return whether a group summary identifies a custom conversation group.

  Classification uses the club-scoped deterministic identities of the built-in
  groups. Display names, email slugs, and caller-supplied group keys are not
  group-type authority.
  """
  def custom_group?(%{club_id: club_id, group_id: group_id})
      when is_binary(club_id) and is_binary(group_id) do
    group_id not in [everyone_group_id(club_id), admin_group_id(club_id)]
  end

  def custom_group?(_group), do: false

  defp group_id(club_id, group_key) do
    ID.deterministic(:group, [@system_group_id_seed, club_id, group_key])
  end
end
