defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
