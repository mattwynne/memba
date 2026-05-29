defmodule Memba.Membership.PersonTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Person

  describe "execute/2 CreatePerson" do
    test "emits PersonCreated using the caller-supplied UUID identity" do
      person_id = Ecto.UUID.generate()

      command = %CreatePerson{
        person_id: person_id,
        name: " Alex Member ",
        email: " alex@example.test "
      }

      assert %PersonCreated{
               person_id: ^person_id,
               name: "Alex Member",
               email: "alex@example.test"
             } = Person.execute(%Person{}, command)
    end

    test "rejects missing or malformed person UUIDs" do
      assert {:error, :invalid_person_id} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: nil,
                 name: "Alex Member",
                 email: "alex@example.test"
               })

      assert {:error, :invalid_person_id} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: "not-a-uuid",
                 name: "Alex Member",
                 email: "alex@example.test"
               })
    end

    test "rejects blank names" do
      assert {:error, :invalid_name} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Ecto.UUID.generate(),
                 name: "  ",
                 email: "alex@example.test"
               })
    end

    test "rejects blank emails" do
      assert {:error, :invalid_email} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Ecto.UUID.generate(),
                 name: "Alex Member",
                 email: "  "
               })
    end

    test "rejects creating the same aggregate twice" do
      person_id = Ecto.UUID.generate()

      person =
        Person.apply(%Person{}, %PersonCreated{
          person_id: person_id,
          name: "Alex Member",
          email: "alex@example.test"
        })

      assert {:error, :already_created} =
               Person.execute(person, %CreatePerson{
                 person_id: person_id,
                 name: "Alex Member",
                 email: "alex@example.test"
               })
    end
  end

  test "apply/2 records the created person identity, name, and email" do
    person_id = Ecto.UUID.generate()

    assert %Person{person_id: ^person_id, name: "Alex Member", email: "alex@example.test"} =
             Person.apply(%Person{}, %PersonCreated{
               person_id: person_id,
               name: "Alex Member",
               email: "alex@example.test"
             })
  end
end
