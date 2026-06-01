defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Messaging

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
      when not is_nil(identity) do
    render_club_home(conn, club_id)
  end

  def home(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil ->
        not_found(conn)

      _club ->
        Phoenix.LiveView.Controller.live_render(conn, MembaWeb.ClubMarketingLive,
          session: %{"club_id" => club_id}
        )
    end
  end

  def home(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "My clubs"
      else
        "Membership made calm"
      end

    conn
    |> assign(:page_title, page_title)
    |> render(:home)
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def terms(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end

  defp render_club_home(conn, club_id) do
    case selected_club(conn, club_id) do
      nil ->
        not_found(conn)

      selected_club ->
        members =
          club_id
          |> Membership.list_active_members_of_club()
          |> Enum.map(&with_member_initials/1)

        messages =
          club_id
          |> Messaging.list_messages_for_club()
          |> Enum.reverse()

        current_member = current_member_for_identity(members, conn.assigns.current_identity)

        conn
        |> assign(:page_title, selected_club.name)
        |> assign(:selected_club, selected_club)
        |> assign(:members, members)
        |> assign(:active_member_count, Enum.count(members))
        |> assign(:current_member, current_member)
        |> assign(:member_names_by_id, Map.new(members, &{&1.id, &1.name}))
        |> assign(:messages, messages)
        |> render(:club)
    end
  end

  defp selected_club(conn, club_id) do
    Enum.find(conn.assigns.current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp current_member_for_identity(_members, nil), do: nil

  defp current_member_for_identity(members, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    Enum.find(members, fn member -> Accounts.normalize_email(member.email) == identity_email end)
  end

  defp with_member_initials(member) do
    Map.put(member, :initials, initials(member.name))
  end

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

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end
end
