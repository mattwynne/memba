defmodule MembaWeb.MessagesLive.Show do
  use MembaWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Message</h1>
    </Layouts.app>
    """
  end
end
