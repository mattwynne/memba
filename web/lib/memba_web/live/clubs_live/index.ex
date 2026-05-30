defmodule MembaWeb.ClubsLive.Index do
  use MembaWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Clubs</h1>
    </Layouts.app>
    """
  end
end
