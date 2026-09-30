defmodule MembaWeb.LiveQueryFixtureLive do
  @moduledoc false

  use MembaWeb, :live_view

  alias MembaWeb.LiveQuery.Binding
  alias MembaWeb.LiveQuery.Query
  alias MembaWeb.LiveQuery.Source

  @impl Phoenix.LiveView
  def mount(_params, %{"store" => store, "test_pid" => test_pid}, socket) do
    source =
      Source.new!(
        subscribe: fn ->
          send(test_pid, {:fixture_subscribed, self()})
          :ok
        end,
        classify: fn _message -> :ignore end,
        matches?: fn interest, invalidation -> interest == invalidation end
      )

    query =
      Query.new!(
        id: :projection,
        assign: :projection,
        load: fn :current ->
          send(test_pid, {:fixture_read, self(), connected?(socket)})
          version = Agent.get(store, & &1)
          {:ok, %{version: version}, [{:version, version}]}
        end
      )

    case Binding.bind(socket, query, :current, source) do
      {:ok, socket} -> {:ok, socket}
      {:error, errors, _socket} -> raise "fixture binding failed: #{inspect(errors)}"
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div id="live-query-fixture" data-version={@projection.version}>
      {@projection.version}
    </div>
    """
  end
end
