defmodule Memba.Membership.MembershipProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  test "an independently created person can be added as an active club member" do
    membership_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    assert :ok =
             App.dispatch(
               %CreateClub{club_id: club_id, name: "Kootenay Mountaineering Club"},
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: "Alex Member",
                 email: "alex@example.test"
               },
               consistency: :strong
             )

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
             active?: true
           } = Repo.get(MembershipProjection, membership_id)
  end
end
