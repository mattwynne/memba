defmodule Memba.Membership.MembershipProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.RemoveMember
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  test "AddMember is projected into the Membership read model" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    assert is_nil(Repo.get(MembershipProjection, membership_id))

    assert :ok =
             App.dispatch(
               %AddMember{
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

  test "RemoveMember marks the projected Membership row inactive" do
    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %AddMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(%RemoveMember{membership_id: membership_id}, consistency: :strong)

    assert %MembershipProjection{active: false} = Repo.get(MembershipProjection, membership_id)
  end
end
