defmodule Memba.Membership.Permissions do
  @moduledoc """
  App-defined permission primitives for club-scoped Membership authorization.
  """

  @club_manage_members "club.manage_members"
  @permissions MapSet.new([@club_manage_members])

  @doc "Permission for managing club membership and membership-management roles."
  def club_manage_members, do: @club_manage_members

  @doc "Return whether the permission identifier is app-defined and supported."
  def valid?(permission) when is_binary(permission), do: MapSet.member?(@permissions, permission)
  def valid?(_permission), do: false
end
