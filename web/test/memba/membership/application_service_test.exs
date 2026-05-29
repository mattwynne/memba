defmodule Memba.Membership.ApplicationServiceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  test "creates a person independently and adds them as a member of an existing club" do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreateClub{
               club_id: club_id,
               name: "Kootenay Mountaineering Club"
             })

    assert :ok =
             Membership.dispatch(%CreatePerson{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert %ClubProjection{club_id: ^club_id} = Membership.get_club(club_id)
    assert %PersonProjection{person_id: ^person_id} = Membership.get_person(person_id)

    assert :ok =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: club_id,
               person_id: person_id
             })

    assert Membership.active_member_of_club?(club_id, person_id)

    assert Membership.list_active_members_of_club(club_id) == [
             %{id: person_id, name: "Alice", email: "alice@example.com"}
           ]
  end

  test "rejects adding a member to a missing club" do
    person_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreatePerson{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert {:error, :club_not_found} =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: Ecto.UUID.generate(),
               person_id: person_id
             })
  end

  test "rejects adding a missing person as a member" do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreateClub{
               club_id: club_id,
               name: "Kootenay Mountaineering Club"
             })

    assert {:error, :person_not_found} =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: club_id,
               person_id: Ecto.UUID.generate()
             })
  end

  test "rejects a second active membership for the same club and person" do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()

    assert :ok =
             Membership.dispatch(%CreateClub{
               club_id: club_id,
               name: "Kootenay Mountaineering Club"
             })

    assert :ok =
             Membership.dispatch(%CreatePerson{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })

    assert :ok =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: club_id,
               person_id: person_id
             })

    assert {:error, :already_active_member} =
             Membership.dispatch(%AddMember{
               membership_id: Ecto.UUID.generate(),
               club_id: club_id,
               person_id: person_id
             })
  end
end
