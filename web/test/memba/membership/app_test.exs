defmodule Memba.Membership.AppTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.DefineClubRole
  alias Memba.Membership.Commands.GrantClubRolePermission
  alias Memba.Membership.Commands.InviteClubMember
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.RemoveGroupMember
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.ResendClubMemberInvitation
  alias Memba.Membership.Commands.UpdateClub
  alias Memba.Membership.Commands.VerifyPersonEmailAddress
  alias Memba.Membership.Projectors.Club, as: ClubProjector
  alias Memba.Membership.Projectors.ClubInvitation, as: ClubInvitationProjector
  alias Memba.Membership.Projectors.Membership, as: MembershipProjector
  alias Memba.Membership.Projectors.Person, as: PersonProjector
  alias Memba.Membership.Projectors.Role, as: RoleProjector
  alias Memba.Membership.Policies.SystemGroupMembership
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
             {{ClubInvitationProjector, _opts}, pid, :worker, [ClubInvitationProjector]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{MembershipProjector, _opts}, pid, :worker, [MembershipProjector]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{RoleProjector, _opts}, pid, :worker, [RoleProjector]} when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{PersonProjector, _opts}, pid, :worker, [PersonProjector]} when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{SystemGroupMembership, _opts}, pid, :worker, [SystemGroupMembership]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)
  end

  test "Membership Commanded app includes the Membership router" do
    expected_commands =
      MapSet.new([
        AcceptClubMemberInvitation,
        AddGroupMember,
        AddMember,
        AddPersonEmailAddress,
        AssignMemberRole,
        CreateClub,
        CreateGroup,
        CreatePerson,
        DefineClubRole,
        GrantClubRolePermission,
        InviteClubMember,
        MakePersonEmailAddressPrimary,
        RemoveGroupMember,
        RemoveMember,
        RemoveMemberRole,
        RemovePersonEmailAddress,
        ReplacePersonEmailAddresses,
        ResendClubMemberInvitation,
        UpdateClub,
        VerifyPersonEmailAddress
      ])

    assert MapSet.new(App.__registered_commands__()) == expected_commands
    assert MapSet.new(Router.__registered_commands__()) == expected_commands
  end

  test "Membership Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end
end
