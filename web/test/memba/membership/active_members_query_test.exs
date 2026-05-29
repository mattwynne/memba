defmodule Memba.Membership.ActiveMembersQueryTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.ActiveMember
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  test "list_active_members_of_club/1 returns active members of the given club only" do
    kootenay_club_id = Ecto.UUID.generate()
    other_club_id = Ecto.UUID.generate()
    alex_id = Ecto.UUID.generate()
    blair_id = Ecto.UUID.generate()
    casey_id = Ecto.UUID.generate()

    create_club(kootenay_club_id, "Kootenay Mountaineering Club")
    create_club(other_club_id, "Other Club")

    create_person(alex_id, "Alex Member", "alex@example.test")
    create_person(blair_id, "Blair Member", "blair@example.test")
    create_person(casey_id, "Casey Other", "casey@example.test")

    add_member(kootenay_club_id, alex_id)
    add_member(kootenay_club_id, blair_id)
    add_member(other_club_id, casey_id)

    assert [
             %ActiveMember{id: ^alex_id, name: "Alex Member", email: "alex@example.test"},
             %ActiveMember{id: ^blair_id, name: "Blair Member", email: "blair@example.test"}
           ] = Membership.list_active_members_of_club(kootenay_club_id)
  end

  test "list_active_members_of_club/1 excludes inactive membership projections" do
    club_id = Ecto.UUID.generate()
    inactive_person_id = Ecto.UUID.generate()

    Repo.insert!(%PersonProjection{
      person_id: inactive_person_id,
      name: "Inactive Member",
      email: "inactive@example.test"
    })

    Repo.insert!(%MembershipProjection{
      membership_id: Ecto.UUID.generate(),
      club_id: club_id,
      person_id: inactive_person_id,
      active?: false
    })

    assert [] = Membership.list_active_members_of_club(club_id)
  end

  test "list_active_members_of_club/1 returns an empty list for missing or invalid club IDs" do
    assert [] = Membership.list_active_members_of_club(Ecto.UUID.generate())
    assert [] = Membership.list_active_members_of_club(nil)
    assert [] = Membership.list_active_members_of_club("not-a-uuid")
  end

  test "active_member_of_club?/2 reports whether a person is an active member of a club" do
    club_id = Ecto.UUID.generate()
    other_club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    create_club(club_id, "Kootenay Mountaineering Club")
    create_club(other_club_id, "Other Club")
    create_person(person_id, "Alex Member", "alex@example.test")
    add_member(club_id, person_id)

    assert Membership.active_member_of_club?(club_id, person_id)
    refute Membership.active_member_of_club?(other_club_id, person_id)
    refute Membership.active_member_of_club?(club_id, Ecto.UUID.generate())
    refute Membership.active_member_of_club?(nil, person_id)
    refute Membership.active_member_of_club?(club_id, "not-a-uuid")
  end

  defp create_club(club_id, name) do
    assert :ok = App.dispatch(%CreateClub{club_id: club_id, name: name}, consistency: :strong)
  end

  defp create_person(person_id, name, email) do
    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: person_id, name: name, email: email},
               consistency: :strong
             )
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
