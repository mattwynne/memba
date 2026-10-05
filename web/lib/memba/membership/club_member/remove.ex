defmodule Memba.Membership.ClubMember.Remove do
  @moduledoc """
  Prepare a Club-routed member removal. The projection supplies routing identity
  only when the caller omits both IDs; Club decides whether removal is allowed.
  """

  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.CustomGroup.Required
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Repo

  def prepare(attrs) when is_map(attrs) do
    with {:ok, membership_id} <- Required.fetch(attrs, :membership_id),
         {:ok, club_id, person_id} <- removal_identity(attrs, membership_id) do
      {:ok,
       %RemoveClubMember{
         club_id: club_id,
         membership_id: membership_id,
         person_id: person_id
       }}
    end
  end

  defp removal_identity(attrs, membership_id) do
    case {optional(attrs, :club_id), optional(attrs, :person_id)} do
      {{:ok, club_id}, {:ok, person_id}} ->
        {:ok, club_id, person_id}

      {:error, :error} ->
        case Repo.get(MembershipProjection, membership_id) do
          %MembershipProjection{club_id: club_id, person_id: person_id} ->
            {:ok, club_id, person_id}

          nil ->
            {:error, :not_found}
        end

      {:error, {:ok, _}} ->
        {:error, {:missing_required_attribute, :club_id}}

      {{:ok, _}, :error} ->
        {:error, {:missing_required_attribute, :person_id}}
    end
  end

  defp optional(attrs, key) do
    case Required.fetch(attrs, key) do
      {:ok, value} -> {:ok, value}
      {:error, {:missing_required_attribute, ^key}} -> :error
    end
  end
end
