defmodule Memba.Membership.PublicApiTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection

  test "create_club/2 dispatches CreateClub through the Membership context" do
    club_id = Ecto.UUID.generate()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kootenay-mountaineering-club"
                }
              ]
            }} =
             Membership.create_club(
               %{"club_id" => club_id, "name" => " Kootenay Mountaineering Club "},
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{club_id: ^club_id, name: "Kootenay Mountaineering Club"} =
             Membership.get_club(club_id)
  end

  test "create_club/2 allows an address-safe slug override and rejects invalid slugs" do
    club_id = Ecto.UUID.generate()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kmc"
                }
              ]
            }} =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               returning: :execution_result,
               consistency: :strong
             )

    assert {:error, :invalid_format} =
             Membership.create_club(%{
               club_id: Ecto.UUID.generate(),
               name: "Kootenay Mountaineering Club",
               slug: "kmc club!"
             })
  end

  test "update_club/2 edits a projected club name and slug" do
    club_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubUpdated{
                  club_id: ^club_id,
                  name: "KMC Alpine Club",
                  slug: "kmc-alpine"
                }
              ]
            }} =
             Membership.update_club(
               %{
                 "club_id" => club_id,
                 "name" => " KMC Alpine Club ",
                 "slug" => "kmc-alpine"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{
             club_id: ^club_id,
             name: "KMC Alpine Club",
             slug: "kmc-alpine"
           } = Membership.get_club(club_id)
  end

  test "update_club/2 rejects invalid and duplicate slugs" do
    kootenay_id = Ecto.UUID.generate()
    nelson_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: kootenay_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_club(
               %{club_id: nelson_id, name: "Nelson Cycling Club", slug: "nelson-cycling"},
               consistency: :strong
             )

    assert {:error, :invalid_format} =
             Membership.update_club(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "KMC Club!"
             })

    assert {:error, :slug_taken} =
             Membership.update_club(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "nelson-cycling"
             })
  end

  test "create_person/2 dispatches CreatePerson through the Membership context" do
    person_id = Ecto.UUID.generate()

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "alice@example.com"
                }
              ]
            }} =
             Membership.create_person(
               %{person_id: person_id, name: " Alice ", email: " Alice@Example.COM "},
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{person_id: ^person_id, name: "Alice", email: "alice@example.com"} =
             Membership.get_person(person_id)
  end

  test "add_member/2 dispatches AddMember and prevents duplicate active club memberships" do
    club_id = Ecto.UUID.generate()
    person_id = Ecto.UUID.generate()
    membership_id = Ecto.UUID.generate()

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               },
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^membership_id,
              events: [
                %MemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                }
              ]
            }} =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               returning: :execution_result,
               consistency: :strong
             )

    assert Membership.active_member_of_club?(club_id, person_id)

    assert {:error, :already_active_member} =
             Membership.add_member(
               %{
                 membership_id: Ecto.UUID.generate(),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert [%{id: ^person_id}] = Membership.list_active_members_of_club(club_id)
  end
end
