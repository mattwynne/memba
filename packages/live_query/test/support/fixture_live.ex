defmodule LiveQuery.FixtureLive do
  @moduledoc false

  use Phoenix.LiveView

  alias LiveQuery.Binding
  alias LiveQuery.Query
  alias LiveQuery.Source
  alias LiveQuery.SubscriptionTracker

  @impl Phoenix.LiveView
  def mount(
        _params,
        %{"store" => store, "test_pid" => test_pid, "tracker" => tracker},
        socket
      ) do
    source =
      Source.new!(
        subscribe: fn ->
          :ok = SubscriptionTracker.subscribe(tracker, self())
          send(test_pid, {:fixture_subscribed, self()})
          :ok
        end,
        classify: fn _notification -> :ignore end,
        matches?: fn interest, invalidation -> interest == invalidation end
      )

    query =
      Query.new!(
        id: :projection,
        assign: :projection,
        load: fn :current ->
          version = Agent.get(store, & &1)
          send(test_pid, {:fixture_read, self(), connected?(socket), version})
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
    <div id="projection" data-version={@projection.version}>
      {@projection.version}
    </div>
    """
  end
end
