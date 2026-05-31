defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, "Membership made calm")
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
