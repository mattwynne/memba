defmodule MembaWeb.LiveQuery.BindingTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MembaWeb.LiveQuery.Binding
  alias MembaWeb.LiveQuery.Query
  alias MembaWeb.LiveQuery.Source

  test "a disconnected bind reads in the owner without subscribing" do
    owner = self()

    query =
      query(:members, :members, fn inputs ->
        send(owner, {:read, self(), inputs})
        {:ok, %{names: ["Alice"]}, [{:club_members, inputs.club_id}]}
      end)

    socket =
      false
      |> socket()
      |> Phoenix.Component.assign(:transient, :preserved)

    assert {:ok, socket} = Binding.bind(socket, query, %{club_id: "club-1"}, source(owner))

    assert_receive {:read, ^owner, %{club_id: "club-1"}}
    refute_receive {:subscribed, _pid}
    assert socket.assigns.members == %{names: ["Alice"]}
    assert socket.assigns.transient == :preserved
    refute Map.has_key?(socket.assigns, :names)
  end

  test "a connected bind subscribes before its first read and subscribes only once" do
    owner = self()

    first =
      query(:first, :first_result, fn inputs ->
        send(owner, {:read, :first, self(), inputs})
        {:ok, %{value: inputs}, [:first]}
      end)

    second =
      query(:second, :second_result, fn inputs ->
        send(owner, {:read, :second, self(), inputs})
        {:ok, %{value: inputs}, [:second]}
      end)

    source = source(owner)

    assert {:ok, socket} = Binding.bind(socket(true), first, "one", source)
    assert_receive {:subscribed, ^owner}
    assert_receive {:read, :first, ^owner, "one"}

    assert {:ok, socket} = Binding.bind(socket, second, "two", source)
    assert_receive {:read, :second, ^owner, "two"}
    refute_receive {:subscribed, _pid}

    assert socket.assigns.first_result == %{value: "one"}
    assert socket.assigns.second_result == %{value: "two"}
  end

  test "only relevant registrations refresh and a success replaces result and interests together" do
    store =
      start_agent(%{
        first: %{result: %{value: "first-v1"}, interests: [:first_old], reads: 0},
        second: %{result: %{value: "second-v1"}, interests: [:second], reads: 0}
      })

    first = stateful_query(:first, :first_result, store)
    second = stateful_query(:second, :second_result, store)

    socket =
      true
      |> socket()
      |> Phoenix.Component.assign(:transient, %{draft: "keep me"})

    source = source(self())
    assert {:ok, socket} = Binding.bind(socket, first, :first, source)
    assert {:ok, socket} = Binding.bind(socket, second, :second, source)
    flush_subscription()

    Agent.update(store, fn state ->
      put_in(state, [:first], %{
        result: %{value: "first-v2"},
        interests: [:first_new],
        reads: state.first.reads
      })
    end)

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :first_old})
    assert socket.assigns.first_result == %{value: "first-v2"}
    assert socket.assigns.second_result == %{value: "second-v1"}
    assert socket.assigns.transient == %{draft: "keep me"}
    assert read_count(store, :first) == 2
    assert read_count(store, :second) == 1

    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :first_old})
    assert read_count(store, :first) == 2

    Agent.update(store, fn state ->
      put_in(state, [:first, :result], %{value: "first-v3"})
    end)

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :first_new})
    assert socket.assigns.first_result == %{value: "first-v3"}
    assert socket.assigns.second_result == %{value: "second-v1"}
    assert socket.assigns.transient == %{draft: "keep me"}
  end

  test "route rebind replaces inputs and old interests before later refreshes" do
    store =
      start_agent(%{
        old_route: %{result: %{route: :old_route, version: 1}, interests: [:old_scope], reads: 0},
        new_route: %{result: %{route: :new_route, version: 1}, interests: [:new_scope], reads: 0}
      })

    query = stateful_query(:route, :route_result, store)
    source = source(self())

    assert {:ok, socket} = Binding.bind(socket(true), query, :old_route, source)
    flush_subscription()
    assert {:ok, socket} = Binding.rebind(socket, :route, :new_route)
    assert socket.assigns.route_result == %{route: :new_route, version: 1}

    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :old_scope})
    assert read_count(store, :old_route) == 1
    assert read_count(store, :new_route) == 1

    Agent.update(store, fn state ->
      put_in(state, [:new_route, :result], %{route: :new_route, version: 2})
    end)

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :new_scope})
    assert socket.assigns.route_result == %{route: :new_route, version: 2}
    assert read_count(store, :new_route) == 2
  end

  test "initial, rebind, and refresh access errors are surfaced and clear successful data" do
    store =
      start_agent(%{
        allowed: %{result: %{secret: "allowed"}, interests: [:allowed], reads: 0},
        forbidden: %{error: :forbidden, reads: 0},
        missing: %{error: :not_found, reads: 0}
      })

    source = source(self())
    initial = stateful_query(:initial, :initial_result, store)

    assert {:error, [{:initial, :forbidden}], initial_socket} =
             Binding.bind(socket(true), initial, :forbidden, source)

    flush_subscription()
    assert initial_socket.assigns.initial_result == nil

    route = stateful_query(:route, :route_result, store)
    assert {:ok, socket} = Binding.bind(socket(true), route, :allowed, source)
    flush_subscription()
    assert socket.assigns.route_result == %{secret: "allowed"}

    assert {:error, [{:route, :not_found}], socket} =
             Binding.rebind(socket, :route, :missing)

    assert socket.assigns.route_result == nil
    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :allowed})

    refresh = stateful_query(:refresh, :refresh_result, store)
    assert {:ok, socket} = Binding.bind(socket, refresh, :allowed, source)

    Agent.update(store, fn state ->
      put_in(state, [:allowed], %{error: :forbidden, reads: state.allowed.reads})
    end)

    assert {:error, [{:refresh, :forbidden}], socket} =
             Binding.handle_notification(socket, {:change, :allowed})

    assert socket.assigns.refresh_result == nil
    assert socket.assigns.route_result == nil
  end

  test "a notification delivered during the connected bind window causes a deterministic reread" do
    store = start_agent(%{reads: 0, trace: []})

    source =
      Source.new!(
        subscribe: fn ->
          record_trace(store, :subscribed)
          :ok
        end,
        classify: fn
          {:projection_changed, :members} ->
            record_trace(store, :notification_classified)
            {:ok, [:members]}

          _message ->
            :ignore
        end,
        matches?: fn interest, invalidation -> interest == invalidation end
      )

    query =
      query(:members, :members, fn :current ->
        read_number =
          Agent.get_and_update(store, fn state ->
            next = state.reads + 1
            {next, %{state | reads: next, trace: state.trace ++ [{:read, next}]}}
          end)

        if read_number == 1 do
          send(self(), {:projection_changed, :members})
          record_trace(store, :notification_delivered_during_read)
        end

        {:ok, %{version: read_number}, [:members]}
      end)

    assert {:ok, socket} = Binding.bind(socket(true), query, :current, source)
    assert socket.assigns.members == %{version: 2}

    assert Agent.get(store, & &1.trace) == [
             :subscribed,
             {:read, 1},
             :notification_delivered_during_read,
             :notification_classified,
             {:read, 2}
           ]

    refute_receive {:projection_changed, :members}
  end

  test "a fresh connected mount subscribes again and rereads current state", %{conn: conn} do
    store = start_agent(1)
    session = %{"store" => store, "test_pid" => self()}

    assert {:ok, first_view, first_html} =
             live_isolated(conn, MembaWeb.LiveQueryFixtureLive, session: session)

    assert first_html =~ ~s(data-version="1")
    assert_receive {:fixture_subscribed, first_pid}
    assert first_pid == first_view.pid
    assert_receive {:fixture_read, ^first_pid, true}

    Agent.update(store, fn _version -> 2 end)

    assert {:ok, second_view, second_html} =
             live_isolated(conn, MembaWeb.LiveQueryFixtureLive, session: session)

    assert second_html =~ ~s(data-version="2")
    assert_receive {:fixture_subscribed, second_pid}
    assert second_pid == second_view.pid
    assert second_pid != first_pid
    assert_receive {:fixture_read, ^second_pid, true}
  end

  defp query(id, assign, load) do
    Query.new!(id: id, assign: assign, load: load)
  end

  defp stateful_query(id, assign, store) do
    query(id, assign, fn input ->
      Agent.get_and_update(store, fn state ->
        entry = Map.fetch!(state, input)
        updated_entry = Map.update!(entry, :reads, &(&1 + 1))
        result = Map.put(state, input, updated_entry)

        reply =
          case entry do
            %{result: value, interests: interests} -> {:ok, value, interests}
            %{error: reason} -> {:error, reason}
          end

        {reply, result}
      end)
    end)
  end

  defp source(test_pid) do
    Source.new!(
      subscribe: fn ->
        send(test_pid, {:subscribed, self()})
        :ok
      end,
      classify: fn
        {:change, invalidation} -> {:ok, [invalidation]}
        _message -> :ignore
      end,
      matches?: fn interest, invalidation -> interest == invalidation end
    )
  end

  defp socket(connected?) do
    %Phoenix.LiveView.Socket{
      transport_pid: if(connected?, do: self()),
      assigns: %{__changed__: %{}}
    }
  end

  defp start_agent(initial) do
    child_spec = Supervisor.child_spec({Agent, fn -> initial end}, id: make_ref())
    start_supervised!(child_spec)
  end

  defp read_count(store, input) do
    Agent.get(store, &get_in(&1, [input, :reads]))
  end

  defp record_trace(store, event) do
    Agent.update(store, &Map.update!(&1, :trace, fn events -> events ++ [event] end))
  end

  defp flush_subscription do
    assert_receive {:subscribed, _pid}
  end
end
