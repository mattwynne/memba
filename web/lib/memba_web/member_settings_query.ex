defmodule MembaWeb.MemberSettingsQuery do
  @moduledoc """
  Loads the fresh-authorized projection data shown by member settings.

  The routed club and authenticated email are stable query inputs. Every load
  resolves active-club authority, Person identity, active memberships, and
  Person email rows again. Tab, form, command, flash, and navigation state
  remain owned by the LiveView.
  """

  alias LiveQuery.Query
  alias Memba.Accounts
  alias Memba.Membership

  @doc """
  Returns the app-owned descriptor for the settings result.
  """
  @spec query() :: Query.t()
  def query do
    Query.new!(
      id: :member_settings,
      assign: :settings,
      load: fn inputs ->
        case load(inputs.club_id, inputs.authenticated_email) do
          {:ok, settings} -> {:ok, settings, interests(settings)}
          {:error, reason} -> {:error, reason}
        end
      end
    )
  end

  @doc """
  Returns the selected Club and current Person's settings projection data.

  Missing, invalid, inactive, foreign-club, and unresolved identity contexts
  retain the existing settings `:forbidden` treatment.
  """
  @spec load(term(), term()) :: {:ok, map()} | {:error, :forbidden}
  def load(club_id, authenticated_email) do
    normalized_email = Accounts.normalize_email(authenticated_email)

    with normalized_email when is_binary(normalized_email) <- normalized_email,
         selected_club when not is_nil(selected_club) <-
           find_selected_club(club_id, normalized_email),
         current_person when not is_nil(current_person) <-
           Membership.get_person_by_email(normalized_email),
         current_person_clubs <-
           Membership.list_active_club_memberships_for_person(current_person.person_id),
         true <-
           Enum.any?(
             current_person_clubs,
             &(&1.club_id == selected_club.club_id)
           ) do
      {:ok,
       %{
         selected_club: selected_club,
         current_person: current_person,
         current_person_clubs: current_person_clubs,
         current_person_email_addresses:
           Membership.list_person_email_addresses(current_person.person_id)
       }}
    else
      _missing_or_forbidden_context -> {:error, :forbidden}
    end
  end

  @doc """
  Derives the complete Person collections, selected relationship, and
  represented Club interests for a settings result.
  """
  @spec interests(map()) :: [term()]
  def interests(settings) when is_map(settings) do
    selected_club = Map.fetch!(settings, :selected_club)
    current_person = Map.fetch!(settings, :current_person)
    current_person_clubs = Map.fetch!(settings, :current_person_clubs)

    person_id = Map.fetch!(current_person, :person_id)
    selected_club_id = Map.fetch!(selected_club, :club_id)

    club_interests =
      [selected_club_id | Enum.map(current_person_clubs, &Map.fetch!(&1, :club_id))]
      |> Enum.uniq()
      |> Enum.map(&{:club, &1})

    [
      {:person, person_id},
      {:person_emails, person_id},
      {:person_clubs, person_id},
      {:person_club, selected_club_id, person_id}
      | club_interests
    ]
  end

  defp find_selected_club(club_id, normalized_email) do
    normalized_email
    |> Accounts.list_active_clubs_for_email()
    |> Enum.find(&(&1.club_id == club_id))
  end
end
