defmodule Memba.Membership.Authorization do
  @moduledoc false

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.MemberPermission
  alias Memba.Repo

  @spec has_permission?(term(), term(), term()) :: boolean()
  def has_permission?(club_id, person_id, permission) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         true <- Permissions.valid?(permission) do
      MemberPermission
      |> where([member_permission], member_permission.club_id == ^club_id)
      |> where([member_permission], member_permission.person_id == ^person_id)
      |> where([member_permission], member_permission.permission == ^permission)
      |> where([member_permission], member_permission.grant_count > 0)
      |> Repo.exists?()
    else
      _invalid -> false
    end
  end
end
