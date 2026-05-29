defmodule Memba.Membership.PersonProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.Person, as: PersonProjection

  test "CreatePerson is projected into the public Membership person query API" do
    person_id = Ecto.UUID.generate()

    assert is_nil(Membership.get_person(person_id))

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               },
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             name: "Alice",
             email: "alice@example.com"
           } = Membership.get_person(person_id)
  end

  test "get_person/1 returns nil for missing or invalid person IDs" do
    assert is_nil(Membership.get_person(Ecto.UUID.generate()))
    assert is_nil(Membership.get_person(nil))
    assert is_nil(Membership.get_person("not-a-uuid"))
  end
end
