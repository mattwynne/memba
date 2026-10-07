defmodule MembaWeb.MemberMessageComposeQuery do
  @moduledoc """
  Loads the fresh-authorized projection data shown by member message compose.

  The routed club, optional audience group, and authenticated email are stable
  query inputs. Every load resolves active-club authority, Person identity,
  active membership, audience participation, and recipient eligibility again.
  Form, validation, command, retry, flash, and navigation state remain owned by
  the LiveView.
  """

  alias LiveQuery.Query
  alias Memba.Accounts
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.PersonQueries
  alias Memba.Membership.SystemGroups

  @doc """
  Returns the app-owned descriptor for the message-compose context.
  """
  @spec query() :: Query.t()
  def query do
    Query.new!(
      id: :member_message_compose,
      assign: :compose_context,
      load: fn inputs ->
        case load_context(
               inputs.club_id,
               Map.get(inputs, :group_id),
               inputs.authenticated_email
             ) do
          {:ok, result, participants} ->
            {:ok, result, interests(result, participants)}

          {:error, reason} ->
            {:error, reason}
        end
      end
    )
  end

  @doc """
  Returns one coherent message-compose context after fresh authorization.

  Missing or lost club/default-audience authority is forbidden. An explicitly
  requested audience that is unknown, foreign, or no longer available to the
  current member is not found.
  """
  @spec load(term(), term(), term()) ::
          {:ok, map()} | {:error, :forbidden | :not_found}
  def load(club_id, requested_group_id, authenticated_email) do
    case load_context(club_id, requested_group_id, authenticated_email) do
      {:ok, result, _participants} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Derives the complete authority, collection, and represented-Person interests.

  Participants include every active selected-audience participant, whether or
  not that Person currently has a primary email address.
  """
  @spec interests(map(), [map()]) :: [term()]
  def interests(result, participants) when is_map(result) and is_list(participants) do
    selected_club = Map.fetch!(result, :selected_club)
    current_member = Map.fetch!(result, :current_member)
    audience_group = Map.fetch!(result, :audience_group)

    club_id = Map.fetch!(selected_club, :club_id)
    membership_id = Map.fetch!(current_member, :membership_id)
    person_id = Map.fetch!(current_member, :id)
    group_id = Map.fetch!(audience_group, :group_id)

    [
      {:club, club_id},
      {:club_members, club_id},
      {:membership, membership_id},
      {:person, person_id},
      {:person_club, club_id, person_id},
      {:person_groups, club_id, person_id},
      {:group, group_id},
      {:group_members, group_id},
      {:group_participation, club_id, group_id, person_id}
    ]
    |> Kernel.++(participant_interests(participants))
    |> Enum.uniq()
  end

  defp load_context(club_id, requested_group_id, authenticated_email) do
    normalized_email = Accounts.normalize_email(authenticated_email)

    with normalized_email when is_binary(normalized_email) <- normalized_email,
         selected_club when not is_nil(selected_club) <-
           find_selected_club(club_id, normalized_email),
         current_person when not is_nil(current_person) <-
           PersonQueries.get_person_by_email(normalized_email),
         current_member when not is_nil(current_member) <-
           find_current_member(selected_club.club_id, current_person.person_id) do
      groups =
        ClubGroupQueries.list_active_groups_for_member(
          selected_club.club_id,
          current_person.person_id
        )

      group_id =
        requested_group_id ||
          SystemGroups.everyone_group_id(selected_club.club_id)

      load_audience(
        selected_club,
        current_member,
        groups,
        group_id,
        requested_group_id
      )
    else
      _missing_or_forbidden_context -> {:error, :forbidden}
    end
  end

  defp load_audience(
         selected_club,
         current_member,
         groups,
         group_id,
         requested_group_id
       ) do
    case Enum.find(groups, &(&1.group_id == group_id)) do
      nil when is_nil(requested_group_id) ->
        {:error, :forbidden}

      nil ->
        {:error, :not_found}

      audience_group ->
        participants =
          ClubGroupQueries.list_active_members_of_group(
            audience_group.group_id,
            include_without_primary_email: true
          )

        active_member_count = Enum.count(participants, &(not is_nil(&1.email)))

        {:ok,
         %{
           selected_club: selected_club,
           current_member: current_member,
           audience_group: audience_group,
           active_member_count: active_member_count,
           message_audience: message_audience(selected_club, audience_group, active_member_count)
         }, participants}
    end
  end

  defp find_selected_club(club_id, normalized_email) do
    normalized_email
    |> Accounts.list_active_clubs_for_email()
    |> Enum.find(&(&1.club_id == club_id))
  end

  defp find_current_member(club_id, person_id) do
    club_id
    |> ClubGroupQueries.list_active_members_of_club()
    |> Enum.find(&(&1.id == person_id))
  end

  defp participant_interests(participants) do
    Enum.flat_map(participants, fn participant ->
      person_id = Map.fetch!(participant, :id)
      [{:person, person_id}, {:person_emails, person_id}]
    end)
  end

  defp message_audience(selected_club, audience_group, active_member_count) do
    %{
      club_name: selected_club.name,
      group_id: audience_group.group_id,
      group_name: audience_group.name,
      active_member_count: active_member_count,
      recipient_count_summary: recipient_count_summary(active_member_count),
      inbound_email_address: audience_group.email_address
    }
  end

  defp recipient_count_summary(1), do: "1 member"
  defp recipient_count_summary(count), do: "#{count} members"
end
