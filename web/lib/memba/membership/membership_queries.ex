defmodule Memba.Membership.MembershipQueries do
  @moduledoc """
  Projected membership predicates and club membership reads.

  These reads can lag committed Club events; privacy-sensitive action boundaries
  should use `Memba.Membership.AuthoritativeMembershipQueries` instead.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.GroupMembership, as: GroupMembershipProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Repo

  def list_active_club_memberships_for_person(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      MembershipProjection
      |> join(:inner, [membership], club in Club, on: club.club_id == membership.club_id)
      |> where([membership, _club], membership.person_id == ^person_id)
      |> where([membership, _club], membership.active == true)
      |> order_by([membership, club],
        asc: club.name,
        asc: club.club_id,
        asc: membership.membership_id
      )
      |> select([membership, club], %{
        membership_id: membership.membership_id,
        club_id: club.club_id,
        club_name: club.name,
        club_slug: club.slug,
        member_since: membership.inserted_at
      })
      |> Repo.all()
    else
      :error -> []
    end
  end

  def list_active_clubs_for_member_email(email) do
    case normalize_email(email) do
      nil ->
        []

      normalized_email ->
        MembershipProjection
        |> join(:inner, [membership], email_address in PersonEmailAddress,
          on: email_address.person_id == membership.person_id
        )
        |> join(:inner, [membership, _email_address], club in Club,
          on: club.club_id == membership.club_id
        )
        |> where([membership, _email_address, _club], membership.active == true)
        |> where(
          [_membership, email_address, _club],
          email_address.normalized_email == ^normalized_email
        )
        |> distinct(true)
        |> order_by([_membership, _email_address, club], asc: club.name, asc: club.club_id)
        |> select([_membership, _email_address, club], club)
        |> Repo.all()
    end
  end

  def active_member_of_club?(club_id, person_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      MembershipProjection
      |> where([membership], membership.club_id == ^club_id)
      |> where([membership], membership.person_id == ^person_id)
      |> where([membership], membership.active == true)
      |> Repo.exists?()
    else
      :error -> false
    end
  end

  def active_member_of_group?(group_id, person_id) do
    with {:ok, group_id} <- ID.cast(:group, group_id),
         {:ok, person_id} <- ID.cast(:person, person_id) do
      GroupMembershipProjection
      |> join(:inner, [group_membership], membership in MembershipProjection,
        on:
          membership.membership_id == group_membership.membership_id and
            membership.club_id == group_membership.club_id and
            membership.person_id == group_membership.person_id
      )
      |> where([group_membership, _membership], group_membership.group_id == ^group_id)
      |> where([group_membership, _membership], group_membership.person_id == ^person_id)
      |> where(
        [group_membership, membership],
        group_membership.active == true and membership.active == true
      )
      |> Repo.exists?()
    else
      :error -> false
    end
  end

  def active_member_of_club_by_email?(club_id, email) do
    with {:ok, club_id} <- ID.cast(:club, club_id),
         normalized_email when is_binary(normalized_email) <- normalize_email(email) do
      MembershipProjection
      |> join(:inner, [membership], email_address in PersonEmailAddress,
        on: email_address.person_id == membership.person_id
      )
      |> where([membership, _email_address], membership.club_id == ^club_id)
      |> where([membership, _email_address], membership.active == true)
      |> where(
        [_membership, email_address],
        email_address.normalized_email == ^normalized_email
      )
      |> Repo.exists?()
    else
      _invalid -> false
    end
  end

  defp normalize_email(email) when is_binary(email) do
    case email |> String.trim() |> String.downcase() do
      "" -> nil
      normalized_email -> normalized_email
    end
  end

  defp normalize_email(_email), do: nil
end
