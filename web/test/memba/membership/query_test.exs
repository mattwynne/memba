defmodule Memba.Membership.QueryTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  describe "list_active_members_of_club/1" do
    test "returns active members of the given club and excludes members of other clubs" do
      kootenay_club_id = create_club("Kootenay Mountaineering Club")
      nelson_club_id = create_club("Nelson Paddling Club")

      alice = create_person(name: "Alice", email: "alice@example.com")
      bob = create_person(name: "Bob", email: "bob@example.com")
      pat = create_person(name: "Pat", email: "pat@example.com")

      add_member(kootenay_club_id, alice.person_id)
      add_member(kootenay_club_id, bob.person_id)
      add_member(nelson_club_id, pat.person_id)

      assert Membership.list_active_members_of_club(kootenay_club_id) == [
               %{id: alice.person_id, name: "Alice", email: "alice@example.com"},
               %{id: bob.person_id, name: "Bob", email: "bob@example.com"}
             ]

      assert Membership.list_active_members_of_club(nelson_club_id) == [
               %{id: pat.person_id, name: "Pat", email: "pat@example.com"}
             ]
    end

    test "excludes inactive memberships" do
      club_id = Ecto.UUID.generate()
      person_id = Ecto.UUID.generate()

      Repo.insert!(%PersonProjection{
        person_id: person_id,
        name: "Inactive Izzy",
        email: "izzy@example.com"
      })

      Repo.insert!(%MembershipProjection{
        membership_id: Ecto.UUID.generate(),
        club_id: club_id,
        person_id: person_id,
        active: false
      })

      assert Membership.list_active_members_of_club(club_id) == []
    end

    test "returns an empty list for missing or invalid club IDs" do
      assert Membership.list_active_members_of_club(Ecto.UUID.generate()) == []
      assert Membership.list_active_members_of_club(nil) == []
      assert Membership.list_active_members_of_club("not-a-uuid") == []
    end
  end

  describe "active_member_of_club?/2" do
    test "returns true only when the person has an active membership in the club" do
      kootenay_club_id = create_club("Kootenay Mountaineering Club")
      nelson_club_id = create_club("Nelson Paddling Club")

      alice = create_person(name: "Alice", email: "alice@example.com")
      pat = create_person(name: "Pat", email: "pat@example.com")

      add_member(kootenay_club_id, alice.person_id)
      add_member(nelson_club_id, pat.person_id)

      assert Membership.active_member_of_club?(kootenay_club_id, alice.person_id)
      refute Membership.active_member_of_club?(kootenay_club_id, pat.person_id)
      refute Membership.active_member_of_club?(nelson_club_id, alice.person_id)
      refute Membership.active_member_of_club?("not-a-uuid", alice.person_id)
      refute Membership.active_member_of_club?(kootenay_club_id, "not-a-uuid")
    end
  end

  defp create_club(name) do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreateClub{
               club_id: club_id,
               name: name
             })

    club_id
  end

  defp create_person(attrs) do
    person = %{
      person_id: Ecto.UUID.generate(),
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    }

    assert :ok =
             Membership.dispatch(%CreatePerson{
               person_id: person.person_id,
               name: person.name,
               email: person.email
             })

    person
  end

  defp add_member(club_id, person_id) do
    assert :ok =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: club_id,
               person_id: person_id
             })
  end
end
