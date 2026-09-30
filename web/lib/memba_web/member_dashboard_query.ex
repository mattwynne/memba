defmodule MembaWeb.MemberDashboardQuery do
  @moduledoc """
  Loads the member dashboard from fresh authority for an authenticated email.

  The routed club and selected group are stable query inputs. Active-club
  authority is deliberately resolved again for every call so a dashboard
  refresh cannot be authorized by a mount-time club snapshot.
  """

  alias Memba.Accounts
  alias MembaWeb.MemberDashboardPresentation
  alias MembaWeb.LiveQuery.Query

  @fallback_families [
    :club,
    :membership,
    :person,
    :group,
    :group_membership,
    :role,
    :message,
    :conversation_access
  ]

  @doc """
  Returns the app-private provisional descriptor for the dashboard binding.

  Inputs contain the routed club ID, authenticated email and optional selected
  group ID. A successful read returns the coherent dashboard plus a complete
  replacement set of opaque interests.
  """
  def query do
    Query.new!(
      id: :member_dashboard,
      assign: :dashboard,
      load: fn inputs ->
        case load(
               inputs.club_id,
               inputs.authenticated_email,
               inputs.selected_group_id
             ) do
          {:ok, dashboard} -> {:ok, dashboard, interests(dashboard)}
          {:error, reason} -> {:error, reason}
        end
      end
    )
  end

  @doc """
  Returns one coherent dashboard view model or the presentation boundary's
  existing `:forbidden`/`:not_found` access result.
  """
  def load(club_id, authenticated_email, selected_group_id) do
    normalized_email = Accounts.normalize_email(authenticated_email)
    active_clubs = Accounts.list_active_clubs_for_email(normalized_email)
    identity = if normalized_email, do: %{email: normalized_email}

    MemberDashboardPresentation.load(
      club_id,
      identity,
      active_clubs,
      selected_group_id
    )
  end

  @doc """
  Builds the dashboard's provisional collection, identity and authorization
  interests from one successful result.
  """
  def interests(dashboard) when is_map(dashboard) do
    selected_club = Map.fetch!(dashboard, :selected_club)
    selected_group = Map.fetch!(dashboard, :selected_group)
    current_member = Map.fetch!(dashboard, :current_member)

    club_id = Map.fetch!(selected_club, :club_id)
    group_id = Map.fetch!(selected_group, :group_id)
    current_person_id = Map.fetch!(current_member, :id)
    current_membership_id = Map.fetch!(current_member, :membership_id)

    represented_members = represented_members(dashboard)
    message_rows = Map.get(dashboard, :message_rows, [])

    [
      {:club, club_id},
      {:club_members, club_id},
      {:club_groups, club_id},
      {:club_conversations, club_id},
      {:person_groups, club_id, current_person_id},
      {:group_members, group_id},
      {:group_conversations, group_id},
      {:group_participation, club_id, group_id, current_person_id},
      {:membership, current_membership_id},
      {:person, current_person_id},
      {:person_clubs, current_person_id},
      {:member_permissions, club_id, current_membership_id, current_person_id},
      {:club_permissions, club_id},
      {:club_roles, club_id}
    ]
    |> Kernel.++(group_interests(dashboard))
    |> Kernel.++(member_interests(club_id, represented_members))
    |> Kernel.++(conversation_interests(group_id, message_rows))
    |> Kernel.++(fallback_interests(club_id))
    |> Enum.uniq()
  end

  defp represented_members(dashboard) do
    dashboard
    |> Map.get(:members, [])
    |> Kernel.++(Map.get(dashboard, :custom_group_member_candidates, []))
    |> Kernel.++([Map.fetch!(dashboard, :current_member)])
    |> Enum.uniq_by(&Map.get(&1, :id))
  end

  defp group_interests(dashboard) do
    dashboard
    |> Map.get(:groups, [])
    |> Enum.flat_map(fn group ->
      case Map.get(group, :group_id) do
        nil -> []
        group_id -> [{:group, group_id}]
      end
    end)
  end

  defp member_interests(club_id, members) do
    Enum.flat_map(members, fn member ->
      person_id = Map.get(member, :id)
      membership_id = Map.get(member, :membership_id)

      [
        optional_tuple(:person, person_id),
        optional_tuple(:membership, membership_id),
        optional_tuple(:member_roles, club_id, membership_id, person_id)
      ]
      |> Enum.reject(&is_nil/1)
    end)
  end

  defp conversation_interests(group_id, message_rows) do
    Enum.flat_map(message_rows, fn row ->
      conversation_id = Map.get(row, :conversation_id) || Map.get(row, :message_id)
      message_id = Map.get(row, :message_id)

      [
        optional_tuple(:conversation, conversation_id),
        optional_tuple(:conversation_messages, conversation_id),
        optional_tuple(:conversation_access, group_id, conversation_id),
        optional_tuple(:message, message_id)
      ]
      |> Enum.reject(&is_nil/1)
    end)
  end

  defp fallback_interests(club_id) do
    Enum.flat_map(@fallback_families, fn family ->
      [{:fallback, family}, {:fallback, family, club_id}]
    end)
  end

  defp optional_tuple(_name, nil), do: nil
  defp optional_tuple(name, value), do: {name, value}

  defp optional_tuple(_name, nil, _third), do: nil
  defp optional_tuple(_name, _second, nil), do: nil
  defp optional_tuple(name, second, third), do: {name, second, third}

  defp optional_tuple(_name, nil, _second, _third), do: nil
  defp optional_tuple(_name, _first, nil, _third), do: nil
  defp optional_tuple(_name, _first, _second, nil), do: nil
  defp optional_tuple(name, first, second, third), do: {name, first, second, third}
end
