defmodule Memba.Membership.PersonProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership.PersonQueries
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.MergePerson
  alias Memba.Membership.Commands.RenamePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  test "CreatePerson is projected into the public Membership person query API" do
    person_id = Memba.ID.generate(:person)

    assert is_nil(PersonQueries.get_person(person_id))

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
           } = PersonQueries.get_person(person_id)
  end

  test "legacy CreatePerson projects one primary email-address row" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: "Alice",
                 email: " Alice@Example.COM "
               },
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             email: "alice@example.com"
           } = PersonQueries.get_person(person_id)

    assert [
             %PersonEmailAddress{
               person_id: ^person_id,
               email: "alice@example.com",
               normalized_email: "alice@example.com",
               is_primary: true
             }
           ] = email_addresses_for(person_id)
  end

  test "CreatePerson with multiple email addresses replaces the legacy primary projection" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: "Alice",
                 email_addresses: [
                   %{email: " Alice@Example.COM ", is_primary: true},
                   %{email: " Alice@Work.Example ", is_primary: false}
                 ]
               },
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             email: "Alice@Example.COM"
           } = PersonQueries.get_person(person_id)

    assert [
             %PersonEmailAddress{
               person_id: ^person_id,
               email: "Alice@Example.COM",
               normalized_email: "alice@example.com",
               is_primary: true
             },
             %PersonEmailAddress{
               person_id: ^person_id,
               email: "Alice@Work.Example",
               normalized_email: "alice@work.example",
               is_primary: false
             }
           ] = email_addresses_for(person_id)
  end

  test "ReplacePersonEmailAddresses atomically replaces rows and updates denormalized primary email" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: "Alice",
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %ReplacePersonEmailAddresses{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: true}
                 ]
               },
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             email: "alice@work.example"
           } = PersonQueries.get_person(person_id)

    assert [
             %PersonEmailAddress{
               person_id: ^person_id,
               email: "alice@example.com",
               normalized_email: "alice@example.com",
               is_primary: false
             },
             %PersonEmailAddress{
               person_id: ^person_id,
               email: "alice@work.example",
               normalized_email: "alice@work.example",
               is_primary: true
             }
           ] = email_addresses_for(person_id)
  end

  test "RenamePerson updates only the matching projected person's name" do
    person_id = Memba.ID.generate(:person)
    other_person_id = Memba.ID.generate(:person)

    for {id, name, email} <- [
          {person_id, "Alice Smith", "alice@example.com"},
          {other_person_id, "Bob Brown", "bob@example.com"}
        ] do
      assert :ok =
               App.dispatch(
                 %CreatePerson{person_id: id, name: name, email: email},
                 consistency: :strong
               )
    end

    email_addresses_before = email_addresses_for(person_id)

    assert :ok =
             App.dispatch(
               %RenamePerson{
                 person_id: person_id,
                 name: "Alice Jones",
                 expected_name: "Alice Smith"
               },
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             name: "Alice Jones",
             email: "alice@example.com",
             merged_into_person_id: nil
           } = PersonQueries.get_person(person_id)

    assert %PersonProjection{name: "Bob Brown", email: "bob@example.com"} =
             PersonQueries.get_person(other_person_id)

    assert email_addresses_for(person_id) == email_addresses_before
  end

  test "PersonMerged moves email ownership and hides the source from active people" do
    target_id = Memba.ID.generate(:person)
    source_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-10-13 06:00:00Z]

    assert :ok =
             App.dispatch(
               %CreatePerson{person_id: target_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %CreatePerson{
                 person_id: source_id,
                 name: "Duplicate Alice",
                 email: "alice@work.example"
               },
               consistency: :strong
             )

    assert :ok =
             App.dispatch(
               %MergePerson{
                 person_id: target_id,
                 source_person_id: source_id,
                 email_addresses: [
                   %{
                     email: "alice@example.com",
                     normalized_email: "alice@example.com",
                     is_primary: true,
                     verified_at: verified_at
                   },
                   %{
                     email: "alice@work.example",
                     normalized_email: "alice@work.example",
                     is_primary: false,
                     verified_at: verified_at
                   }
                 ]
               },
               consistency: :strong
             )

    assert %{merged_into_person_id: ^target_id} = PersonQueries.get_person(source_id)
    refute Enum.any?(PersonQueries.list_people(), &(&1.person_id == source_id))
    assert %{person_id: ^target_id} = PersonQueries.get_person_by_email("alice@work.example")
    assert email_addresses_for(source_id) == []
    assert length(email_addresses_for(target_id)) == 2
  end

  test "get_person/1 returns nil for missing or invalid person IDs" do
    assert is_nil(PersonQueries.get_person(Memba.ID.generate(:person)))
    assert is_nil(PersonQueries.get_person(nil))
    assert is_nil(PersonQueries.get_person("not-a-uuid"))
  end

  defp email_addresses_for(person_id) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id == ^person_id)
    |> order_by([email_address], asc: email_address.normalized_email)
    |> Repo.all()
  end
end
