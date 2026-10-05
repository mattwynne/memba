defmodule Memba.Membership.ClubMember.Role do
  @moduledoc """
  Prepare actor-bearing Club role commands. Projection authorization is an early
  rejection; the Club aggregate remains authoritative for membership and roles.
  """

  alias Memba.ID
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.{AssignClubRoleToMember, RemoveClubRoleFromMember}
  alias Memba.Membership.CustomGroup.Required
  alias Memba.Membership.Roles

  def prepare_assign(attrs) when is_map(attrs) do
    with {:ok, fields} <- fields(attrs),
         :ok <- Authorization.authorize_manage_members(fields.club_id, fields.actor_person_id) do
      {:ok,
       %AssignClubRoleToMember{
         club_id: fields.club_id,
         membership_id: fields.membership_id,
         person_id: fields.person_id,
         role_id: fields.role_id,
         assigned_by_person_id: fields.actor_person_id
       }}
    end
  end

  def prepare_remove(attrs) when is_map(attrs) do
    with {:ok, fields} <- fields(attrs),
         :ok <- Authorization.authorize_manage_members(fields.club_id, fields.actor_person_id) do
      {:ok,
       %RemoveClubRoleFromMember{
         club_id: fields.club_id,
         membership_id: fields.membership_id,
         person_id: fields.person_id,
         role_id: fields.role_id,
         removed_by_person_id: fields.actor_person_id
       }}
    end
  end

  def prepare_assign_administrator(attrs) when is_map(attrs) do
    with {:ok, attrs} <- administrator_role(attrs), do: prepare_assign(attrs)
  end

  def prepare_remove_administrator(attrs) when is_map(attrs) do
    with {:ok, attrs} <- administrator_role(attrs), do: prepare_remove(attrs)
  end

  defp administrator_role(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, club_id} <- cast_club_id(club_id) do
      {:ok, Map.put(attrs, :role_id, Roles.membership_administrator_role_id(club_id))}
    end
  end

  defp cast_club_id(club_id) do
    case ID.cast(:club, club_id) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :invalid_club_id}
    end
  end

  defp fields(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, membership_id} <- Required.fetch(attrs, :membership_id),
         {:ok, person_id} <- Required.fetch(attrs, :person_id),
         {:ok, role_id} <- Required.fetch(attrs, :role_id),
         {:ok, actor_person_id} <- Required.fetch(attrs, :actor_person_id) do
      {:ok,
       %{
         club_id: club_id,
         membership_id: membership_id,
         person_id: person_id,
         role_id: role_id,
         actor_person_id: actor_person_id
       }}
    end
  end
end
