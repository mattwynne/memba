defmodule LiveQuery.LifecycleTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias LiveQuery.SubscriptionTracker

  @endpoint LiveQuery.TestEndpoint

  setup do
    start_supervised!(@endpoint)
    :ok
  end

  test "a fresh mount after owner termination subscribes again and reads current state" do
    store = start_agent(1)
    tracker = start_supervised!({SubscriptionTracker, self()})
    session = %{"store" => store, "test_pid" => self(), "tracker" => tracker}

    assert {:ok, first_view, first_html} =
             live_isolated(build_conn(), LiveQuery.FixtureLive, session: session)

    assert first_html =~ ~s(data-version="1")
    assert_receive {:fixture_subscribed, first_pid}
    assert first_pid == first_view.pid
    assert_receive {:fixture_read, ^first_pid, true, 1}

    stop_owner(first_pid)
    assert_receive {:subscriber_removed, ^first_pid, _reason}

    Agent.update(store, fn _version -> 2 end)

    assert {:ok, second_view, second_html} =
             live_isolated(build_conn(), LiveQuery.FixtureLive, session: session)

    assert second_html =~ ~s(data-version="2")
    assert_receive {:fixture_subscribed, second_pid}
    assert second_pid == second_view.pid
    assert second_pid != first_pid
    assert_receive {:fixture_read, ^second_pid, true, 2}
  end

  test "the source observes subscriber cleanup when the LiveView owner terminates" do
    store = start_agent(1)
    tracker = start_supervised!({SubscriptionTracker, self()})
    session = %{"store" => store, "test_pid" => self(), "tracker" => tracker}

    assert {:ok, view, _html} =
             live_isolated(build_conn(), LiveQuery.FixtureLive, session: session)

    assert_receive {:fixture_subscribed, owner}
    assert owner == view.pid
    assert SubscriptionTracker.subscribers(tracker) == MapSet.new([owner])

    stop_owner(owner)
    assert_receive {:subscriber_removed, ^owner, _reason}
    assert SubscriptionTracker.subscribers(tracker) == MapSet.new()
  end

  defp start_agent(initial) do
    child_spec = Supervisor.child_spec({Agent, fn -> initial end}, id: make_ref())
    start_supervised!(child_spec)
  end

  defp stop_owner(owner) do
    reference = Process.monitor(owner)
    GenServer.stop(owner)
    assert_receive {:DOWN, ^reference, :process, ^owner, :normal}
  end
end
