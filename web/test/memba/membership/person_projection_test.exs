defmodule Memba.Membership.PersonProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  test "CreatePerson is projected into the public Membership person query API" do
    person_id = Memba.ID.generate(:person)

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
           } = Membership.get_person(person_id)

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
           } = Membership.get_person(person_id)

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
           } = Membership.get_person(person_id)

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

  test "get_person/1 returns nil for missing or invalid person IDs" do
    assert is_nil(Membership.get_person(Memba.ID.generate(:person)))
    assert is_nil(Membership.get_person(nil))
    assert is_nil(Membership.get_person("not-a-uuid"))
  end

  defp email_addresses_for(person_id) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id == ^person_id)
    |> order_by([email_address], asc: email_address.normalized_email)
    |> Repo.all()
  end
end
