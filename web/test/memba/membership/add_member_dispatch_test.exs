defmodule Memba.Membership.AddMemberDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.MemberRoleAssigned
  alias Memba.Membership.Roles

  test "legacy membership-ID aggregate write model is not available" do
    refute Code.ensure_loaded?(Memba.Membership.Membership)
  end

  test "Membership app routes member activation and removal to the Club aggregate" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    admin_role_id = Roles.membership_administrator_role_id(club_id)

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    command = %AddMember{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %MemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                },
                %MemberRoleAssigned{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id,
                  role_id: ^admin_role_id
                }
              ],
              aggregate_state: %Club{
                club_id: ^club_id,
                active_memberships: %{^membership_id => ^person_id}
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %MemberRemoved{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                }
              ],
              aggregate_state: %Club{club_id: ^club_id, active_memberships: %{}}
            }} =
             App.dispatch(
               %RemoveMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "Membership app requires the routed Club aggregate to exist" do
    command = %AddMember{
      membership_id: Memba.ID.generate(:membership),
      club_id: Memba.ID.generate(:club),
      person_id: Memba.ID.generate(:person)
    }

    assert {:error, :not_created} = App.dispatch(command)
  end
end
