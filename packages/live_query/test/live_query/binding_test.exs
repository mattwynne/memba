defmodule LiveQuery.BindingTest do
  use ExUnit.Case, async: true

  alias LiveQuery.Binding
  alias LiveQuery.Query
  alias LiveQuery.Source

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
  end

  test "a connected owner subscribes before reading and shares one subscription" do
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
    assert socket.assigns.second_result == %{value: "two"}
  end

  test "only matching registrations refresh and successes replace results and interests" do
    store =
      start_agent(%{
        first: %{result: %{value: "first-v1"}, interests: [:first_old], reads: 0},
        second: %{result: %{value: "second-v1"}, interests: [:second], reads: 0}
      })

    socket =
      true
      |> socket()
      |> Phoenix.Component.assign(:transient, %{draft: "keep me"})

    source = source(self())

    assert {:ok, socket} =
             Binding.bind(socket, stateful_query(:first, :first_result, store), :first, source)

    assert {:ok, socket} =
             Binding.bind(socket, stateful_query(:second, :second_result, store), :second, source)

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

    Agent.update(store, &put_in(&1, [:first, :result], %{value: "first-v3"}))
    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :first_new})
    assert socket.assigns.first_result == %{value: "first-v3"}
  end

  test "duplicate and out-of-order notifications reread current state without regressing" do
    store =
      start_agent(%{
        current: %{result: %{version: 1}, interests: [:members], reads: 0}
      })

    query = stateful_query(:members, :members, store)
    source = sequenced_source(self())

    assert {:ok, socket} = Binding.bind(socket(true), query, :current, source)
    flush_subscription()

    Agent.update(store, &put_in(&1, [:current, :result], %{version: 2}))

    assert {:ok, socket} =
             Binding.handle_notification(socket, {:change, :members, 2})

    assert {:ok, socket} =
             Binding.handle_notification(socket, {:change, :members, 2})

    Agent.update(store, &put_in(&1, [:current, :result], %{version: 3}))

    assert {:ok, socket} =
             Binding.handle_notification(socket, {:change, :members, 1})

    assert socket.assigns.members == %{version: 3}
    assert read_count(store, :current) == 4
  end

  test "route rebind replaces inputs and superseded interests" do
    store =
      start_agent(%{
        old_route: %{result: %{route: :old_route}, interests: [:old_scope], reads: 0},
        new_route: %{result: %{route: :new_route}, interests: [:new_scope], reads: 0}
      })

    query = stateful_query(:route, :route_result, store)
    source = source(self())

    assert {:ok, socket} = Binding.bind(socket(true), query, :old_route, source)
    flush_subscription()
    assert {:ok, socket} = Binding.rebind(socket, :route, :new_route)

    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :old_scope})
    assert read_count(store, :old_route) == 1
    assert read_count(store, :new_route) == 1

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :new_scope})
    assert socket.assigns.route_result == %{route: :new_route}
    assert read_count(store, :new_route) == 2
  end

  test "access errors clear successful data and interests for bind, rebind, and refresh" do
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
  end

  test "a relevant notification delivered during bind causes a fresh read" do
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

          _notification ->
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

  test "a relevant notification delivered during rebind rereads the new registration" do
    store = start_agent(%{old: 0, new: 0})

    query =
      query(:route, :route_result, fn input ->
        read_number =
          Agent.get_and_update(store, fn counts ->
            next = Map.fetch!(counts, input) + 1
            {next, Map.put(counts, input, next)}
          end)

        if input == :new and read_number == 1 do
          send(self(), {:change, :new_scope})
        end

        scope = Map.fetch!(%{old: :old_scope, new: :new_scope}, input)
        {:ok, %{route: input, version: read_number}, [scope]}
      end)

    assert {:ok, socket} = Binding.bind(socket(true), query, :old, source(self()))
    flush_subscription()
    assert {:ok, socket} = Binding.rebind(socket, :route, :new)
    assert socket.assigns.route_result == %{route: :new, version: 2}
    assert Agent.get(store, & &1) == %{old: 1, new: 2}
    refute_receive {:change, :new_scope}
  end

  test "a classified notification crossing an initial access error recovers current data" do
    store = start_agent(%{reads: 0})

    query =
      query(:members, :members, fn :current ->
        read_number =
          Agent.get_and_update(store, fn state ->
            next = state.reads + 1
            {next, %{state | reads: next}}
          end)

        if read_number == 1 do
          send(self(), {:change, :members})
          {:error, :forbidden}
        else
          {:ok, %{version: read_number}, [:members]}
        end
      end)

    assert {:ok, socket} = Binding.bind(socket(true), query, :current, source(self()))
    assert socket.assigns.members == %{version: 2}
    assert Agent.get(store, & &1.reads) == 2
    refute_receive {:change, :members}

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :members})
    assert socket.assigns.members == %{version: 3}
  end

  test "a classified notification crossing a route access error recovers only the new route" do
    store = start_agent(%{old: 0, new: 0})

    query =
      query(:route, :route_result, fn input ->
        read_number =
          Agent.get_and_update(store, fn counts ->
            next = Map.fetch!(counts, input) + 1
            {next, Map.put(counts, input, next)}
          end)

        case {input, read_number} do
          {:old, _read_number} ->
            {:ok, %{route: :old, version: read_number}, [:old_scope]}

          {:new, 1} ->
            send(self(), {:change, :new_scope})
            {:error, :forbidden}

          {:new, _read_number} ->
            {:ok, %{route: :new, version: read_number}, [:new_scope]}
        end
      end)

    assert {:ok, socket} = Binding.bind(socket(true), query, :old, source(self()))
    flush_subscription()

    assert {:ok, socket} = Binding.rebind(socket, :route, :new)
    assert socket.assigns.route_result == %{route: :new, version: 2}
    assert Agent.get(store, & &1) == %{old: 1, new: 2}
    refute_receive {:change, :new_scope}

    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :old_scope})
    assert Agent.get(store, & &1) == %{old: 1, new: 2}

    assert {:ok, socket} = Binding.handle_notification(socket, {:change, :new_scope})
    assert socket.assigns.route_result == %{route: :new, version: 3}
  end

  test "a repeated access error after a crossing notification remains cleared and does not retry" do
    store = start_agent(%{reads: 0})

    query =
      query(:members, :members, fn :current ->
        read_number =
          Agent.get_and_update(store, fn state ->
            next = state.reads + 1
            {next, %{state | reads: next}}
          end)

        case read_number do
          1 ->
            send(self(), {:change, :members})
            {:error, :forbidden}

          2 ->
            {:error, :not_found}

          _later_read ->
            flunk("bind-window reconciliation retried more than once")
        end
      end)

    assert {:error, [{:members, :not_found}], socket} =
             Binding.bind(socket(true), query, :current, source(self()))

    assert socket.assigns.members == nil
    assert Agent.get(store, & &1.reads) == 2
    refute_receive {:change, :members}

    assert {:ignored, socket} = Binding.handle_notification(socket, {:change, :members})
    assert socket.assigns.members == nil
    assert Agent.get(store, & &1.reads) == 2
  end

  test "an access error without a crossing notification reads only once" do
    store = start_agent(%{reads: 0})

    query =
      query(:members, :members, fn :current ->
        Agent.update(store, &Map.update!(&1, :reads, fn reads -> reads + 1 end))
        {:error, :forbidden}
      end)

    assert {:error, [{:members, :forbidden}], socket} =
             Binding.bind(socket(true), query, :current, source(self()))

    assert socket.assigns.members == nil
    assert Agent.get(store, & &1.reads) == 1
  end

  defp query(id, assign, load) do
    Query.new!(id: id, assign: assign, load: load)
  end

  defp stateful_query(id, assign, store) do
    query(id, assign, fn input ->
      Agent.get_and_update(store, fn state ->
        entry = Map.fetch!(state, input)
        updated_entry = Map.update!(entry, :reads, &(&1 + 1))
        state = Map.put(state, input, updated_entry)

        reply =
          case entry do
            %{result: result, interests: interests} -> {:ok, result, interests}
            %{error: reason} -> {:error, reason}
          end

        {reply, state}
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
        _notification -> :ignore
      end,
      matches?: fn interest, invalidation -> interest == invalidation end
    )
  end

  defp sequenced_source(test_pid) do
    Source.new!(
      subscribe: fn ->
        send(test_pid, {:subscribed, self()})
        :ok
      end,
      classify: fn
        {:change, invalidation, _sequence} -> {:ok, [invalidation]}
        _notification -> :ignore
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
