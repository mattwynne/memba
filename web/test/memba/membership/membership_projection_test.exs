defmodule Memba.Membership.MembershipProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AssignClubRoleToMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.RemoveClubMember
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  test "AddClubMember is projected into the Membership read model" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    create_club(club_id)

    assert is_nil(Repo.get(MembershipProjection, membership_id))

    assert :ok =
             App.dispatch(
               %AddClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %MembershipProjection{
             membership_id: ^membership_id,
             club_id: ^club_id,
             person_id: ^person_id,
             active: true
           } = Repo.get(MembershipProjection, membership_id)
  end

  test "RemoveClubMember marks the projected Membership row inactive" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    replacement_membership_id = Memba.ID.generate(:membership)
    replacement_person_id = Memba.ID.generate(:person)

    create_club(club_id)

    assert :ok =
             App.dispatch(
               %AddClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %AddClubMember{
                 membership_id: replacement_membership_id,
                 club_id: club_id,
                 person_id: replacement_person_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %AssignClubRoleToMember{
                 club_id: club_id,
                 membership_id: replacement_membership_id,
                 person_id: replacement_person_id,
                 role_id: Memba.Membership.Roles.membership_administrator_role_id(club_id)
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %RemoveClubMember{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert %MembershipProjection{active: false} = Repo.get(MembershipProjection, membership_id)
  end

  defp create_club(club_id) do
    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )
  end
end
