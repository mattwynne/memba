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

  describe "prepare_rename/3" do
    test "prepares a self-targeted rename without dispatching it" do
      person_id = Memba.ID.generate(:person)
      actor = %{person_id: person_id}
      editable_attrs = %{"name" => " Alice Jones ", "expected_name" => "Alice"}

      assert {:ok,
              %RenamePerson{
                person_id: ^person_id,
                name: " Alice Jones ",
                expected_name: "Alice"
              }} = PersonCommands.prepare_rename(actor, person_id, editable_attrs)

      assert is_nil(PersonQueries.get_person(person_id))
    end

    test "rejects malformed actors and any other target before dispatch" do
      actor_person_id = Memba.ID.generate(:person)
      other_person_id = Memba.ID.generate(:person)

      for {actor, target_person_id, editable_attrs} <- [
            {%{}, actor_person_id, %{name: "Alice", expected_name: "Alice"}},
            {%{"person_id" => actor_person_id}, actor_person_id,
             %{name: "Alice", expected_name: "Alice"}},
            {%{person_id: "not-a-person-id"}, "not-a-person-id",
             %{name: "Alice", expected_name: "Alice"}},
            {%{person_id: actor_person_id}, "not-a-person-id",
             %{name: "Alice", expected_name: "Alice"}},
            {%{person_id: actor_person_id}, other_person_id,
             %{name: "Alice", expected_name: "Alice"}},
            {%{person_id: actor_person_id}, other_person_id,
             %{name: "Alice Jones", expected_name: "Alice"}},
            {%{person_id: actor_person_id}, other_person_id,
             %{name: "Alice Brown", expected_name: "Alice Jones"}}
          ] do
        assert {:error, :unauthorized} =
                 PersonCommands.prepare_rename(actor, target_person_id, editable_attrs)
      end

      assert is_nil(PersonQueries.get_person(actor_person_id))
      assert is_nil(PersonQueries.get_person(other_person_id))
    end
  end
end
