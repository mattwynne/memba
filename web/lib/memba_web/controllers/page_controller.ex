defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, "Membership made calm")
    |> render(:home)
  end
end
