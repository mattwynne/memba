defmodule Memba.Membership.PersonEmailAddressProjectionTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress

  test "person email address projection rows can be persisted and read" do
    person_id = Ecto.UUID.generate()

    Repo.insert!(%Person{
      person_id: person_id,
      name: "Alice",
      email: "alice@example.com"
    })

    projection =
      Repo.insert!(%PersonEmailAddress{
        person_id: person_id,
        email: "alice@example.com",
        normalized_email: "alice@example.com",
        is_primary: true
      })

    assert %PersonEmailAddress{
             id: id,
             person_id: ^person_id,
             email: "alice@example.com",
             normalized_email: "alice@example.com",
             is_primary: true
           } = Repo.get!(PersonEmailAddress, projection.id)

    assert Ecto.UUID.cast(id) != :error
    assert %DateTime{} = projection.inserted_at
    assert %DateTime{} = projection.updated_at
  end

  test "is_primary defaults to false and is not nullable" do
    person_id = Ecto.UUID.generate()
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert!(%Person{
      person_id: person_id,
      name: "Alice",
      email: "alice@example.com"
    })

    Repo.insert_all(PersonEmailAddress, [
      %{
        id: Ecto.UUID.generate(),
        person_id: person_id,
        email: "alice@example.com",
        normalized_email: "alice@example.com",
        inserted_at: now,
        updated_at: now
      }
    ])

    assert [%PersonEmailAddress{is_primary: false}] = Repo.all(PersonEmailAddress)

    assert_raise Postgrex.Error, ~r/null value in column "is_primary"/, fn ->
      Repo.insert_all(PersonEmailAddress, [
        %{
          id: Ecto.UUID.generate(),
          person_id: person_id,
          email: "other@example.com",
          normalized_email: "other@example.com",
          is_primary: nil,
          inserted_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "person email address rows are deleted when the person projection is deleted" do
    person_id = Ecto.UUID.generate()

    person =
      Repo.insert!(%Person{
        person_id: person_id,
        name: "Alice",
        email: "alice@example.com"
      })

    email_address =
      Repo.insert!(%PersonEmailAddress{
        person_id: person_id,
        email: "alice@example.com",
        normalized_email: "alice@example.com"
      })

    assert Repo.get!(PersonEmailAddress, email_address.id)

    Repo.delete!(person)

    assert Repo.get(PersonEmailAddress, email_address.id) == nil
  end
end
