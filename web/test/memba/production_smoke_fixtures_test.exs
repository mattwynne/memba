defmodule Memba.ProductionSmokeFixturesTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.ProductionSmokeFixtures

  test "ensures the production smoke club member fixture exists" do
    result = ProductionSmokeFixtures.ensure!()

    club = Membership.get_club_by_slug("test")
    person = Membership.get_person_by_email("test@memba.io")

    assert club.name == "Smoke Test Club"
    assert result.club_id == club.club_id
    assert result.club_name == "Smoke Test Club"
    assert result.club_slug == "test"
    assert result.person_id == person.person_id
    assert result.email == "test@memba.io"
    assert Membership.active_member_of_club?(club.club_id, person.person_id)

    assert %MembershipProjection{membership_id: membership_id, active: true} =
             Repo.get_by(MembershipProjection,
               club_id: club.club_id,
               person_id: person.person_id
             )

    assert result.membership_id == membership_id
  end

  test "repairs an existing smoke club and person without duplicating the membership" do
    :ok =
      Membership.create_club(
        %{club_id: Memba.ID.generate(:club), name: "Test", slug: "test"},
        consistency: :strong
      )

    :ok =
      Membership.create_person(
        %{
          person_id: Memba.ID.generate(:person),
          name: "Smoke Test Staff",
          email: "test@memba.io"
        },
        consistency: :strong
      )

    first = ProductionSmokeFixtures.ensure!()
    second = ProductionSmokeFixtures.ensure!()

    club = Membership.get_club_by_slug("test")
    person = Membership.get_person_by_email("test@memba.io")

    assert club.name == "Smoke Test Club"
    assert person.name == "Smoke Test Staff"
    assert first.membership_id == second.membership_id

    assert [membership] =
             Repo.all(
               from(membership in MembershipProjection,
                 where: membership.club_id == ^club.club_id,
                 where: membership.person_id == ^person.person_id,
                 where: membership.active == true
               )
             )

    assert membership.membership_id == first.membership_id
  end
end
