defmodule MembaWeb.MemberDashboardLive do
  @moduledoc """
  LiveView-backed member dashboard for signed-in club home requests.

  The public URL remains `GET /?club_id=<club_id>`; the controller keeps the
  logged-out/public dispatch boundary and renders this LiveView for signed-in
  active members.
  """
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Messaging
  alias MembaWeb.UserAuth

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    club_id = Map.get(session, "club_id")
    current_identity = current_identity_from_session(session)
    current_identity_clubs = identity_clubs(current_identity)

    socket = assign_current_identity(socket, current_identity, current_identity_clubs)

    case dashboard_context(club_id, current_identity, current_identity_clubs) do
      {:ok, dashboard_assigns} ->
        {:ok, assign(socket, dashboard_assigns)}

      {:error, :forbidden} ->
        forbidden!()
    end
  end

  @impl Phoenix.LiveView
  def render(%{selected_club: _selected_club} = assigns) do
    MembaWeb.PageHTML.club(assigns)
  end

  defp dashboard_context(club_id, current_identity, current_identity_clubs) do
    with selected_club when not is_nil(selected_club) <-
           selected_club(current_identity_clubs, club_id),
         members <-
           club_id
           |> Membership.list_active_members_of_club()
           |> Enum.map(&with_initials/1),
         current_member when not is_nil(current_member) <-
           current_member_for_identity(members, current_identity) do
      messages =
        club_id
        |> Messaging.list_messages_for_club()
        |> Enum.reverse()

      {:ok,
       %{
         page_title: selected_club.name,
         selected_club: selected_club,
         members: members,
         active_member_count: Enum.count(members),
         current_member: current_member,
         member_names_by_id: Map.new(members, &{&1.id, &1.name}),
         messages: messages
       }}
    else
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  defp selected_club(current_identity_clubs, club_id) do
    Enum.find(current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp current_member_for_identity(_members, nil), do: nil

  defp current_member_for_identity(members, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    Enum.find(members, fn member -> Accounts.normalize_email(member.email) == identity_email end)
  end

  defp current_identity_from_session(session) do
    session
    |> Map.get(UserAuth.identity_session_key())
    |> Accounts.normalize_email()
    |> case do
      nil ->
        nil

      email ->
        %{
          email: email,
          staff?: Accounts.staff_email?(email),
          active_clubs: Accounts.list_active_clubs_for_email(email)
        }
    end
  end

  defp assign_current_identity(socket, identity, current_identity_clubs) do
    assign(socket,
      current_identity: identity,
      current_identity_email: identity_email(identity),
      current_identity_staff?: identity_staff?(identity),
      current_identity_clubs: current_identity_clubs
    )
  end

  defp identity_email(nil), do: nil
  defp identity_email(identity), do: identity.email

  defp identity_staff?(nil), do: false
  defp identity_staff?(identity), do: identity.staff?

  defp identity_clubs(nil), do: []
  defp identity_clubs(identity), do: identity.active_clubs

  defp with_initials(member), do: Map.put(member, :initials, initials(member.name))

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn <<first::utf8, _rest::binary>> -> String.upcase(<<first::utf8>>) end)
    |> case do
      "" -> "?"
      value -> value
    end
  end

  defp initials(_name), do: "?"

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
