defmodule Memba.Membership.PersonEmailAddressProjectionTest do
  use Memba.DataCase, async: true

  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress

  @backfill_migration Memba.Repo.Migrations.BackfillMembershipPersonEmailAddresses
  @backfill_migration_path Path.expand(
                             "../../../priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs",
                             __DIR__
                           )

  test "backfill migration creates one primary address row for each existing person email" do
    alice_id = Ecto.UUID.generate()
    bob_id = Ecto.UUID.generate()

    Repo.insert!(%Person{
      person_id: alice_id,
      name: "Alice",
      email: " Alice@Example.COM "
    })

    Repo.insert!(%Person{
      person_id: bob_id,
      name: "Bob",
      email: "bob@example.com"
    })

    assert Repo.all(PersonEmailAddress) == []

    Repo.query!(backfill_sql())

    assert Repo.get!(Person, alice_id).email == " Alice@Example.COM "
    assert Repo.get!(Person, bob_id).email == "bob@example.com"

    assert [
             %PersonEmailAddress{
               person_id: ^alice_id,
               email: "Alice@Example.COM",
               normalized_email: "alice@example.com",
               is_primary: true
             },
             %PersonEmailAddress{
               person_id: ^bob_id,
               email: "bob@example.com",
               normalized_email: "bob@example.com",
               is_primary: true
             }
           ] =
             PersonEmailAddress
             |> order_by([email_address], asc: email_address.normalized_email)
             |> Repo.all()
  end

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

  defp backfill_sql do
    unless Code.ensure_loaded?(@backfill_migration) do
      Code.compile_file(@backfill_migration_path)
    end

    apply(@backfill_migration, :backfill_sql, [])
  end
end
