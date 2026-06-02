defmodule Memba.Membership.ClubProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Projections.Club, as: ClubProjection

  test "club projection struct exposes the public slug attribute" do
    club_id = Ecto.UUID.generate()

    assert %ClubProjection{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc"
           } =
             %ClubProjection{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             }
  end

  test "CreateClub is projected into the public Membership club query API" do
    club_id = Ecto.UUID.generate()

    assert is_nil(Membership.get_club(club_id))

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club_id,
                 name: "Kootenay Mountaineering Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    assert %ClubProjection{
             club_id: ^club_id,
             name: "Kootenay Mountaineering Club",
             slug: "kmc"
           } = Membership.get_club(club_id)
  end

  test "get_club/1 returns nil for missing or invalid club IDs" do
    assert is_nil(Membership.get_club(Ecto.UUID.generate()))
    assert is_nil(Membership.get_club(nil))
    assert is_nil(Membership.get_club("not-a-uuid"))
  end
end
