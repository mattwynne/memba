defmodule Memba.Membership.AppTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Router

  test "Membership Commanded app is supervised by the Phoenix application" do
    assert is_pid(Process.whereis(App))
    assert is_pid(Process.whereis(Memba.EventStore))

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {App, pid, :supervisor, [App]} when is_pid(pid) -> true
             _child -> false
           end)
  end

  test "Membership Commanded app includes the Membership router" do
    assert App.__registered_commands__() == Router.__registered_commands__()
    assert Router.__registered_commands__() == [CreateClub]
  end

  test "Membership Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end
end
