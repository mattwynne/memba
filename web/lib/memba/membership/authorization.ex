defmodule Memba.Membership.Authorization do
  @moduledoc false

  alias Memba.Membership.PermissionQueries
  alias Memba.Membership.Permissions

  @spec authorize_manage_members(term(), term()) :: :ok | {:error, :unauthorized}
  def authorize_manage_members(club_id, person_id) do
    if has_permission?(club_id, person_id, Permissions.club_manage_members()) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  @spec has_permission?(term(), term(), term()) :: boolean()
  def has_permission?(club_id, person_id, permission),
    do: PermissionQueries.has_permission?(club_id, person_id, permission)
end
