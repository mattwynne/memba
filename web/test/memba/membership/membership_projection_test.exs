defmodule Memba.Membership.MembershipProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  test "AddMember is projected into the Membership read model" do
    membership_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

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
end
