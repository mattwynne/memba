defmodule MembaWeb.MemberInvitationQuery do
  @moduledoc """
  Loads a fresh-authorized context for member invitations.

  The routed club and authenticated email are stable query inputs. Every load
  resolves active-club authority, Person identity, active membership, member
  count, and manage-members permission again. Invitation form, validation,
  delivery feedback, command, flash, and navigation state remain owned by the
  LiveView.
  """

  alias LiveQuery.Query
  alias Memba.Accounts
  alias Memba.Membership.Authorization
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.PersonQueries

  @doc """
  Returns the app-owned descriptor for the invitation context.
  """
  @spec query() :: Query.t()
  def query do
    Query.new!(
      id: :member_invitation,
      assign: :invitation_context,
      load: fn inputs ->
        case load(inputs.club_id, inputs.authenticated_email) do
          {:ok, context} -> {:ok, context, interests(context)}
          {:error, reason} -> {:error, reason}
        end
      end
    )
  end

  @doc """
  Returns the selected Club, current member, and active-member count after
  fresh authorization.

  Missing, invalid, inactive, foreign-club, unresolved identity, and
  unauthorized contexts retain the existing invitation `:forbidden` treatment.
  """
  @spec load(term(), term()) :: {:ok, map()} | {:error, :forbidden}
  def load(club_id, authenticated_email) do
    normalized_email = Accounts.normalize_email(authenticated_email)

    with normalized_email when is_binary(normalized_email) <- normalized_email,
         selected_club when not is_nil(selected_club) <-
           find_selected_club(club_id, normalized_email),
         person when not is_nil(person) <-
           PersonQueries.get_person_by_email(normalized_email),
         active_members <- ClubGroupQueries.list_active_members_of_club(selected_club.club_id),
         current_member when not is_nil(current_member) <-
           Enum.find(active_members, &(&1.id == person.person_id)),
         :ok <-
           Authorization.authorize_manage_members(
             selected_club.club_id,
             person.person_id
           ) do
      {:ok,
       %{
         selected_club: selected_club,
         current_member: current_member,
         active_member_count: length(active_members)
       }}
    else
      _missing_or_forbidden_context -> {:error, :forbidden}
    end
  end

  @doc """
  Derives the complete selected-club collection, member, Person, role, and
  permission interests for an invitation context.
  """
  @spec interests(map()) :: [term()]
  def interests(context) when is_map(context) do
    selected_club = Map.fetch!(context, :selected_club)
    current_member = Map.fetch!(context, :current_member)

    club_id = Map.fetch!(selected_club, :club_id)
    membership_id = Map.fetch!(current_member, :membership_id)
    person_id = Map.fetch!(current_member, :id)

    [
      {:club, club_id},
      {:club_members, club_id},
      {:membership, membership_id},
      {:person, person_id},
      {:person_club, club_id, person_id},
      {:member_roles, club_id, membership_id, person_id},
      {:member_permissions, club_id, membership_id, person_id},
      {:club_roles, club_id},
      {:club_permissions, club_id}
    ]
  end

  defp find_selected_club(club_id, normalized_email) do
    normalized_email
    |> Accounts.list_active_clubs_for_email()
    |> Enum.find(&(&1.club_id == club_id))
  end
end
