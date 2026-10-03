defmodule LiveQuery.SubscriptionTracker do
  @moduledoc false

  use GenServer

  def start_link(test_pid) do
    GenServer.start_link(__MODULE__, test_pid)
  end

  def subscribe(tracker, subscriber) do
    GenServer.call(tracker, {:subscribe, subscriber})
  end

  def subscribers(tracker) do
    GenServer.call(tracker, :subscribers)
  end

  @impl GenServer
  def init(test_pid) do
    {:ok, %{test_pid: test_pid, subscribers: %{}}}
  end

  @impl GenServer
  def handle_call({:subscribe, subscriber}, _from, state) do
    reference = Process.monitor(subscriber)
    subscribers = Map.put(state.subscribers, reference, subscriber)
    {:reply, :ok, %{state | subscribers: subscribers}}
  end

  def handle_call(:subscribers, _from, state) do
    {:reply, MapSet.new(Map.values(state.subscribers)), state}
  end

  @impl GenServer
  def handle_info({:DOWN, reference, :process, subscriber, reason}, state) do
    send(state.test_pid, {:subscriber_removed, subscriber, reason})
    {:noreply, %{state | subscribers: Map.delete(state.subscribers, reference)}}
  end
end
