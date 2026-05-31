defmodule Memba.Membership.QueryTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  describe "list_active_members_of_club/1" do
    test "returns active members of the given club and excludes members of other clubs" do
      kootenay_club_id = Ecto.UUID.generate()
      nelson_club_id = Ecto.UUID.generate()

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
      kootenay_club_id = Ecto.UUID.generate()
      nelson_club_id = Ecto.UUID.generate()

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

  describe "list_active_clubs_for_member_email/1" do
    test "returns active clubs for the normalized member email in stable name order" do
      alpine = create_club(name: "Alpine Club")
      kootenay = create_club(name: "Kootenay Mountaineering Club")
      other = create_club(name: "Other Club")
      inactive = create_club(name: "Inactive Club")

      alice = create_person(name: "Alice", email: "Member@Example.COM")
      duplicate_alice = create_person(name: "Alice Duplicate", email: "member@example.com")
      bob = create_person(name: "Bob", email: "other@example.com")
      inactive_alice = create_person(name: "Inactive Alice", email: "member@example.com")

      add_member(kootenay.club_id, alice.person_id)
      add_member(alpine.club_id, alice.person_id)
      add_member(alpine.club_id, duplicate_alice.person_id)
      add_member(other.club_id, bob.person_id)

      insert_projected_membership(
        club_id: inactive.club_id,
        person_id: inactive_alice.person_id,
        active: false
      )

      assert Membership.list_active_clubs_for_member_email(" MEMBER@example.com ") == [
               alpine,
               kootenay
             ]

      assert Membership.list_active_clubs_for_member_email("unknown@example.com") == []
      assert Membership.list_active_clubs_for_member_email("not-an-email") == []
    end

    test "excludes active memberships whose club projection is missing" do
      missing_club_id = Ecto.UUID.generate()
      person = create_person(name: "Alice", email: "member@example.com")

      add_member(missing_club_id, person.person_id)

      assert Membership.list_active_clubs_for_member_email("member@example.com") == []
    end
  end

  describe "active_member_email_of_club?/2" do
    test "returns true only when the normalized email has an active membership in the club" do
      club = create_club()
      other_club = create_club()

      alice = create_person(name: "Alice", email: "Member@Example.COM")
      bob = create_person(name: "Bob", email: "other@example.com")
      inactive_alice = create_person(name: "Inactive Alice", email: "inactive@example.com")

      add_member(club.club_id, alice.person_id)
      add_member(other_club.club_id, bob.person_id)

      insert_projected_membership(
        club_id: club.club_id,
        person_id: inactive_alice.person_id,
        active: false
      )

      assert Membership.active_member_email_of_club?(club.club_id, " MEMBER@example.com ")

      refute Membership.active_member_email_of_club?(club.club_id, "other@example.com")
      refute Membership.active_member_email_of_club?(other_club.club_id, "member@example.com")
      refute Membership.active_member_email_of_club?(club.club_id, "inactive@example.com")
      refute Membership.active_member_email_of_club?("not-a-uuid", "member@example.com")
      refute Membership.active_member_email_of_club?(club.club_id, "not-an-email")
    end
  end

  defp create_club(attrs \\ []) do
    club = %{
      club_id: Keyword.get_lazy(attrs, :club_id, &Ecto.UUID.generate/0),
      name: Keyword.get(attrs, :name, "Club #{System.unique_integer([:positive])}")
    }

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club.club_id,
                 name: club.name
               },
               consistency: :strong
             )

    Repo.get!(ClubProjection, club.club_id)
  end

  defp create_person(attrs) do
    person = %{
      person_id: Ecto.UUID.generate(),
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    }

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person.person_id,
                 name: person.name,
                 email: person.email
               },
               consistency: :strong
             )

    person
  end

  defp add_member(club_id, person_id) do
    assert :ok =
             App.dispatch(
               %AddMember{
                 membership_id: Ecto.UUID.generate(),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp insert_projected_membership(attrs) do
    Repo.insert!(%MembershipProjection{
      membership_id: Keyword.get_lazy(attrs, :membership_id, &Ecto.UUID.generate/0),
      club_id: Keyword.fetch!(attrs, :club_id),
      person_id: Keyword.fetch!(attrs, :person_id),
      active: Keyword.get(attrs, :active, true)
    })
  end
end
