defmodule Memba.Membership.PersonRenameTest do
  use ExUnit.Case, async: true
  alias Memba.Membership.Person
  alias Memba.Membership.Commands.RenamePerson
  alias Memba.Membership.Events.{PersonCreated, PersonRenamed}

  defp person(name \\ "Alice Smith") do
    Person.apply(%Person{}, %PersonCreated{
      person_id: Memba.ID.generate(:person),
      name: name,
      email: "alice@example.test"
    })
  end

  defp rename(person, name, expected \\ "Alice Smith") do
    Person.execute(person, %RenamePerson{
      person_id: person.person_id,
      name: name,
      expected_name: expected
    })
  end

  test "normalizes whitespace in requested, expected and current names" do
    person = person(" Alice   Smith ")

    assert %PersonRenamed{name: "Robin Jones"} =
             rename(person, "  Robin\t Jones\n", "Alice Smith")

    assert [] = rename(person, "Alice Smith", "Other")
  end

  test "validates blank and 100/101 Unicode graphemes without restricting scripts or punctuation" do
    person = person()
    assert {:error, :invalid_name} = rename(person, " \t\n ")
    hundred = String.duplicate("e\u0301", 100)
    assert %PersonRenamed{name: ^hundred} = rename(person, hundred)
    assert {:error, :name_too_long} = rename(person, hundred <> "界")

    for name <- ["Cher", "李 明", "O'Connor-Smith", "🌄"] do
      assert %PersonRenamed{name: ^name} = rename(person, name)
    end
  end

  test "stale attempts and confirmations compare atomically, while same target is eventless" do
    initial = person()
    first = rename(initial, "Alice Jones")
    latest = Person.apply(initial, first)
    assert {:error, {:name_conflict, "Alice Jones"}} = rename(latest, "Alice Brown")
    assert [] = rename(latest, " Alice Jones ")
    assert %PersonRenamed{name: "Alice Brown"} = rename(latest, "Alice Brown", "Alice Jones")
    newer = Person.apply(latest, rename(latest, "Alice Green", "Alice Jones"))
    assert {:error, {:name_conflict, "Alice Green"}} = rename(newer, "Alice Brown", "Alice Jones")
    back = Person.apply(newer, rename(newer, "Alice Smith", "Alice Green"))
    assert %PersonRenamed{name: "Alice Brown"} = rename(back, "Alice Brown")
  end

  test "applying rename preserves identity and all email state and legacy creation stays valid" do
    initial = person(String.duplicate("x", 150))
    event = %PersonRenamed{person_id: initial.person_id, name: "Robin Jones"}
    assert Person.apply(initial, event) == %{initial | name: "Robin Jones"}
    assert {:error, :person_not_created} = rename(%Person{}, "Robin Jones")

    command = %RenamePerson{
      person_id: Memba.ID.generate(:person),
      name: "Robin Jones",
      expected_name: initial.name
    }

    assert {:error, _} = Person.execute(initial, command)
  end
end
