defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
      when not is_nil(identity) do
    selected_club =
      Enum.find(conn.assigns.current_identity_clubs, fn club -> club.club_id == club_id end)

    if selected_club do
      conn
      |> assign(:page_title, selected_club.name)
      |> assign(:selected_club, selected_club)
      |> render(:club)
    else
      conn
      |> put_status(:not_found)
      |> put_view(html: MembaWeb.ErrorHTML)
      |> render(:"404")
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
end
