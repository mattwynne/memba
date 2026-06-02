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
  alias Memba.Membership.Slug

  describe "get_club_by_slug/1" do
    test "returns the projected club for a valid slug" do
      club = create_club("Kootenay Mountaineering Club", slug: "kmc")

      assert %ClubProjection{
               club_id: club_id,
               name: "Kootenay Mountaineering Club",
               slug: "kmc"
             } = Membership.get_club_by_slug("kmc")

      assert club_id == club.club_id
    end

    test "uses safe lookup normalization for casing and surrounding whitespace" do
      club = create_club("Kootenay Mountaineering Club", slug: "kmc")

      assert %ClubProjection{club_id: club_id, slug: "kmc"} =
               Membership.get_club_by_slug(" KMC ")

      assert club_id == club.club_id
    end

    test "returns nil for invalid, unknown, or non-string slugs" do
      _club = create_club("Kootenay Mountaineering Club", slug: "kmc")

      assert is_nil(Membership.get_club_by_slug("unknown"))
      assert is_nil(Membership.get_club_by_slug("kmc club"))
      assert is_nil(Membership.get_club_by_slug("kmc_club"))
      assert is_nil(Membership.get_club_by_slug("kmc.club"))
      assert is_nil(Membership.get_club_by_slug("-kmc"))
      assert is_nil(Membership.get_club_by_slug(nil))
    end
  end

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
    test "returns active clubs for a member email and excludes inactive or other memberships" do
      kootenay = create_club("Kootenay Mountaineering Club")
      nelson = create_club("Nelson Cycling Club")
      other_club = create_club("Other Club")
      inactive_club_id = Ecto.UUID.generate()

      alice = create_person(name: "Alice", email: "alice@example.com")
      other_person = create_person(name: "Other", email: "other@example.com")

      add_member(kootenay.club_id, alice.person_id)
      add_member(nelson.club_id, alice.person_id)
      add_member(other_club.club_id, other_person.person_id)

      insert_membership_club!(club_id: inactive_club_id, name: "Inactive Club")

      Repo.insert!(%MembershipProjection{
        membership_id: Ecto.UUID.generate(),
        club_id: inactive_club_id,
        person_id: alice.person_id,
        active: false
      })

      assert [
               %ClubProjection{club_id: kootenay_id, name: "Kootenay Mountaineering Club"},
               %ClubProjection{club_id: nelson_id, name: "Nelson Cycling Club"}
             ] = Membership.list_active_clubs_for_member_email(" ALICE@EXAMPLE.COM ")

      assert kootenay_id == kootenay.club_id
      assert nelson_id == nelson.club_id
    end

    test "returns an empty list for blank, nil, or unknown email addresses" do
      assert Membership.list_active_clubs_for_member_email("unknown@example.com") == []
      assert Membership.list_active_clubs_for_member_email("   ") == []
      assert Membership.list_active_clubs_for_member_email(nil) == []
    end
  end

  describe "active_member_of_club_by_email?/2" do
    test "returns true only when a normalized email has an active membership in the club" do
      club = create_club("Kootenay Mountaineering Club")
      other_club = create_club("Other Club")
      alice = create_person(name: "Alice", email: "Alice@Example.COM")
      other_person = create_person(name: "Other", email: "other@example.com")

      add_member(club.club_id, alice.person_id)
      add_member(other_club.club_id, other_person.person_id)

      assert Membership.active_member_of_club_by_email?(club.club_id, " alice@example.com ")

      refute Membership.active_member_of_club_by_email?(club.club_id, "other@example.com")
      refute Membership.active_member_of_club_by_email?(other_club.club_id, "alice@example.com")
      refute Membership.active_member_of_club_by_email?(Ecto.UUID.generate(), "alice@example.com")
      refute Membership.active_member_of_club_by_email?("not-a-uuid", "alice@example.com")
      refute Membership.active_member_of_club_by_email?(club.club_id, "   ")
      refute Membership.active_member_of_club_by_email?(club.club_id, nil)
    end
  end

  defp create_club(name, opts \\ []) do
    club = %{
      club_id: Ecto.UUID.generate(),
      name: name,
      slug: Keyword.get_lazy(opts, :slug, fn -> slug_for(name) end)
    }

    assert :ok =
             App.dispatch(
               %CreateClub{
                 club_id: club.club_id,
                 name: club.name,
                 slug: club.slug
               },
               consistency: :strong
             )

    club
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

  defp slug_for(name) do
    Slug.default_from_name(name)
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
end
