defmodule Memba.Membership.PersonCommandsTest do
  use Memba.DataCase, async: false

  alias Memba.Membership.CommandDispatch, as: MembershipCommandDispatch
  alias Memba.Membership.PersonCommands

  alias Memba.Membership.PersonQueries
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.RenamePerson

  test "prepares a legacy email command without dispatching or changing its input" do
    person_id = Memba.ID.generate(:person)
    attrs = %{"person_id" => person_id, "name" => " Alice ", "email" => " Alice@Example.COM "}

    assert {:ok,
            %CreatePerson{
              person_id: ^person_id,
              name: " Alice ",
              email: " Alice@Example.COM ",
              email_addresses: nil
            } = command} =
             PersonCommands.prepare_create(attrs)

    assert {:ok, ^command} = PersonCommands.prepare_create(attrs)
    assert is_nil(PersonQueries.get_person(person_id))
  end

  test "prepares a multi-address command with both email fields intact" do
    person_id = Memba.ID.generate(:person)
    addresses = [%{email: "Alice@Example.COM", is_primary: true}]

    assert {:ok,
            %CreatePerson{
              person_id: ^person_id,
              email: "legacy@example.com",
              email_addresses: ^addresses
            }} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: "Alice",
               email: "legacy@example.com",
               email_addresses: addresses
             })

    assert is_nil(PersonQueries.get_person(person_id))
  end

  test "preserves missing, invalid set, and invalid person identity errors" do
    attrs = %{person_id: Memba.ID.generate(:person), name: "Alice"}

    assert {:error, {:missing_required_attribute, :email}} = PersonCommands.prepare_create(attrs)

    assert {:error, :email_address_required} =
             PersonCommands.prepare_create(Map.put(attrs, :email_addresses, []))

    assert {:error, :invalid_person_id} =
             PersonCommands.prepare_create(
               attrs
               |> Map.put(:person_id, "invalid")
               |> Map.put(:email, "alice@example.com")
             )
  end

  test "rejects projected ownership of primary or alternate email before dispatch" do
    assert :ok =
             (with {:ok, command} <-
                     PersonCommands.prepare_create(%{
                       person_id: Memba.ID.generate(:person),
                       name: "Existing",
                       email: "Alice@Example.COM"
                     }) do
                MembershipCommandDispatch.dispatch(command, consistency: :strong)
              end)

    attrs = %{person_id: Memba.ID.generate(:person), name: "New"}

    assert {:error, :email_address_taken} =
             PersonCommands.prepare_create(Map.put(attrs, :email, " alice@example.com "))

    assert {:error, :email_address_taken} =
             PersonCommands.prepare_create(
               Map.put(attrs, :email_addresses, [
                 %{email: "new@example.com", is_primary: true},
                 %{email: " ALICE@EXAMPLE.COM ", is_primary: false}
               ])
             )

    assert is_nil(PersonQueries.get_person(attrs.person_id))
  end

  describe "prepare_rename/2" do
    test "derives the target from trusted actor context and preserves raw editable values" do
      person_id = Memba.ID.generate(:person)

      assert {:ok,
              %RenamePerson{
                person_id: ^person_id,
                name: " Alice   Jones ",
                expected_name: " Alice Smith "
              }} =
               PersonCommands.prepare_rename(
                 %{person_id: person_id},
                 %{"name" => " Alice   Jones ", "expected_name" => " Alice Smith "}
               )

      assert {:ok, %RenamePerson{person_id: ^person_id}} =
               PersonCommands.prepare_rename(
                 %{person_id: person_id},
                 %{
                   person_id: person_id,
                   name: "Alice Jones",
                   expected_name: "Alice Smith"
                 }
               )
    end

    test "rejects forged targets for ordinary, no-op, and confirmation-shaped attempts" do
      actor_person_id = Memba.ID.generate(:person)
      forged_person_id = Memba.ID.generate(:person)

      attempts = [
        %{name: "Alice Jones", expected_name: "Alice Smith"},
        %{name: "Alice Smith", expected_name: "stale baseline"},
        %{name: "Alice Brown", expected_name: "Alice Jones"}
      ]

      for attrs <- attempts do
        assert {:error, :unauthorized} =
                 PersonCommands.prepare_rename(
                   %{person_id: actor_person_id},
                   Map.put(attrs, :person_id, forged_person_id)
                 )
      end
    end

    test "requires a valid trusted actor and both editable fields" do
      person_id = Memba.ID.generate(:person)
      actor = %{person_id: person_id}

      assert {:error, :invalid_actor} =
               PersonCommands.prepare_rename(%{}, %{
                 name: "Alice Jones",
                 expected_name: "Alice"
               })

      assert {:error, {:missing_required_attribute, :name}} =
               PersonCommands.prepare_rename(actor, %{expected_name: "Alice"})

      assert {:error, {:missing_required_attribute, :expected_name}} =
               PersonCommands.prepare_rename(actor, %{name: "Alice Jones"})
    end
  end
end
