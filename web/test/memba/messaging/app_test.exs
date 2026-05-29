defmodule Memba.Messaging.AppTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
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
    expected_commands =
      MapSet.new([
        SendMessage,
        ReportDeliveryDelivered,
        ReportDeliveryDelayed,
        ReportDeliveryBounced,
        ReportDeliverySpamComplaint,
        ReportDeliveryOpened
      ])

    assert MapSet.new(App.__registered_commands__()) == expected_commands
    assert MapSet.new(Router.__registered_commands__()) == expected_commands
  end

  test "Messaging Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end
end
