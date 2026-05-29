defmodule Memba.Membership.AppTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.Person, as: PersonProjector
  alias Memba.Membership.Router

  test "Membership Commanded app is supervised by the Phoenix application" do
    assert is_pid(Process.whereis(App))
    assert is_pid(Process.whereis(Memba.EventStore))

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {App, pid, :supervisor, [App]} when is_pid(pid) -> true
             _child -> false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{ClubProjector, _opts}, pid, :worker, [ClubProjector]} when is_pid(pid) -> true
             _child -> false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{PersonProjector, _opts}, pid, :worker, [PersonProjector]} when is_pid(pid) -> true
             _child -> false
           end)
  end

  test "Membership Commanded app includes the Membership router" do
    expected_commands = [CreateClub, CreatePerson]

    assert same_commands?(App.__registered_commands__(), Router.__registered_commands__())
    assert same_commands?(Router.__registered_commands__(), expected_commands)
  end

  test "Membership Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end

  defp same_commands?(left, right) do
    Enum.sort_by(left, &inspect/1) == Enum.sort_by(right, &inspect/1)
  end
end
