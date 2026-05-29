defmodule Memba.Messaging.AppTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Memba.Messaging.App
  alias Memba.Messaging.Router

  test "Messaging Commanded app is supervised by the Phoenix application" do
    assert is_pid(Process.whereis(App))
    assert is_pid(Process.whereis(Memba.EventStore))
    assert is_pid(Process.whereis(Memba.Messaging.EventStore))

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {App, pid, :supervisor, [App]} when is_pid(pid) -> true
             _child -> false
           end)
  end

  test "Messaging Commanded app includes the Messaging router" do
    assert App.__registered_commands__() == []
    assert Router.__registered_commands__() == []
  end

  test "Messaging Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end
end
