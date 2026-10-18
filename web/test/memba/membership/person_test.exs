defmodule Memba.Membership.PersonTest do
  use ExUnit.Case, async: true

  alias Memba.Membership.Commands.AddPersonEmailAddress
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Commands.MakePersonEmailAddressPrimary
  alias Memba.Membership.Commands.MergePerson
  alias Memba.Membership.Commands.RemovePersonEmailAddress
  alias Memba.Membership.Commands.RenamePerson
  alias Memba.Membership.Commands.ReplacePersonEmailAddresses
  alias Memba.Membership.Commands.VerifyPersonEmailAddress
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.Events.PersonMerged
  alias Memba.Membership.Events.PersonRenamed
  alias Memba.Membership.Person

  describe "execute/2 CreatePerson" do
    test "emits PersonCreated using the caller-supplied UUID identity" do
      person_id = Memba.ID.generate(:person)

      command = %CreatePerson{
        person_id: person_id,
        name: " Alice ",
        email: " Alice@Example.COM "
      }

      assert %PersonCreated{
               person_id: ^person_id,
               name: "Alice",
               email: "alice@example.com"
             } = Person.execute(%Person{}, command)
    end

    test "accepts a replace-all email-address set and emits the compatibility event followed by the replacement event" do
      person_id = Memba.ID.generate(:person)

      command = %CreatePerson{
        person_id: person_id,
        name: " Alice ",
        email_addresses: [
          %{email: " Alice@Example.COM ", is_primary: true},
          %{email: " alice@work.example ", is_primary: false}
        ]
      }

      assert [
               %PersonCreated{
                 person_id: ^person_id,
                 name: "Alice",
                 email: "Alice@Example.COM"
               },
               %PersonEmailAddressesReplaced{
                 person_id: ^person_id,
                 primary_email: "Alice@Example.COM",
                 email_addresses: [
                   %{
                     email: "Alice@Example.COM",
                     normalized_email: "alice@example.com",
                     is_primary: true
                   },
                   %{
                     email: "alice@work.example",
                     normalized_email: "alice@work.example",
                     is_primary: false
                   }
                 ]
               }
             ] = Person.execute(%Person{}, command)
    end

    test "rejects missing or malformed person UUIDs" do
      assert {:error, :invalid_person_id} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: nil,
                 name: "Alice",
                 email: "alice@example.com"
               })

      assert {:error, :invalid_person_id} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: "not-a-uuid",
                 name: "Alice",
                 email: "alice@example.com"
               })
    end

    test "rejects blank person names" do
      assert {:error, :invalid_name} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "  ",
                 email: "alice@example.com"
               })
    end

    test "rejects blank or malformed email addresses" do
      assert {:error, :invalid_email} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "Alice",
                 email: "  "
               })

      assert {:error, :invalid_email} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "Alice",
                 email: "alice.example.com"
               })
    end

    test "rejects invalid replace-all email-address sets on create" do
      assert {:error, :exactly_one_primary_email_required} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "Alice",
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               })

      assert {:error, :duplicate_email_address} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "Alice",
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: " ALICE@EXAMPLE.COM ", is_primary: false}
                 ]
               })
    end

    test "rejects a legacy email that disagrees with the replace-all primary address" do
      assert {:error, :primary_email_mismatch} =
               Person.execute(%Person{}, %CreatePerson{
                 person_id: Memba.ID.generate(:person),
                 name: "Alice",
                 email: "alice@old.example",
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               })
    end

    test "rejects creating the same aggregate twice" do
      person_id = Memba.ID.generate(:person)

      person =
        Person.apply(%Person{}, %PersonCreated{
          person_id: person_id,
          name: "Alice",
          email: "alice@example.com"
        })

      assert {:error, :already_created} =
               Person.execute(person, %CreatePerson{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               })
    end
  end

  describe "execute/2 ReplacePersonEmailAddresses" do
    test "preserves verification state for existing addresses and makes newly introduced addresses pending" do
      person_id = Memba.ID.generate(:person)

      person =
        Person.apply(%Person{}, %PersonCreated{
          person_id: person_id,
          name: "Alice",
          email: "alice@example.com"
        })

      command = %ReplacePersonEmailAddresses{
        person_id: person_id,
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: " Alice@Work.Example ", is_primary: false}
        ]
      }

      assert %PersonEmailAddressesReplaced{
               person_id: ^person_id,
               primary_email: "alice@example.com",
               email_addresses: [
                 %{
                   email: "alice@example.com",
                   normalized_email: "alice@example.com",
                   is_primary: true,
                   verified_at: %DateTime{}
                 },
                 %{
                   email: "Alice@Work.Example",
                   normalized_email: "alice@work.example",
                   is_primary: false,
                   verified_at: nil
                 }
               ]
             } = Person.execute(person, command)
    end

    test "rejects making a newly introduced pending address primary during replacement" do
      person_id = Memba.ID.generate(:person)

      person =
        Person.apply(%Person{}, %PersonCreated{
          person_id: person_id,
          name: "Alice",
          email: "alice@example.com"
        })

      assert {:error, :primary_email_address_not_verified} =
               Person.execute(person, %ReplacePersonEmailAddresses{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: true}
                 ]
               })
    end

    test "rejects replacement before the person is created" do
      assert {:error, :person_not_created} =
               Person.execute(%Person{}, %ReplacePersonEmailAddresses{
                 person_id: Memba.ID.generate(:person),
                 email_addresses: [%{email: "alice@example.com", is_primary: true}]
               })
    end

    test "rejects invalid person IDs and invalid address sets" do
      person_id = Memba.ID.generate(:person)

      person =
        Person.apply(%Person{}, %PersonCreated{
          person_id: person_id,
          name: "Alice",
          email: "alice@example.com"
        })

      assert {:error, :invalid_person_id} =
               Person.execute(person, %ReplacePersonEmailAddresses{
                 person_id: "not-a-uuid",
                 email_addresses: [%{email: "alice@example.com", is_primary: true}]
               })

      assert {:error, :exactly_one_primary_email_required} =
               Person.execute(person, %ReplacePersonEmailAddresses{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               })
    end
  end

  describe "execute/2 individual email-address commands" do
    test "adds a pending address, verifies it, makes it primary, and removes the old non-primary address" do
      person_id = Memba.ID.generate(:person)
      verified_at = ~U[2026-07-13 18:00:00Z]
      person = created_person(person_id)

      assert %PersonEmailAddressAdded{
               person_id: ^person_id,
               email: "Alice+New@Example.COM",
               normalized_email: "alice+new@example.com"
             } =
               added_event =
               Person.execute(person, %AddPersonEmailAddress{
                 person_id: person_id,
                 email: " Alice+New@Example.COM "
               })

      person = Person.apply(person, added_event)

      assert [
               %{
                 normalized_email: "alice@example.com",
                 is_primary: true,
                 verified_at: %DateTime{}
               },
               %{
                 normalized_email: "alice+new@example.com",
                 is_primary: false,
                 verified_at: nil
               }
             ] = person.email_addresses

      assert {:error, :email_address_not_verified} =
               Person.execute(person, %MakePersonEmailAddressPrimary{
                 person_id: person_id,
                 email: "alice+new@example.com"
               })

      assert %PersonEmailAddressVerified{
               person_id: ^person_id,
               email: "Alice+New@Example.COM",
               normalized_email: "alice+new@example.com",
               verified_at: ^verified_at
             } =
               verified_event =
               Person.execute(person, %VerifyPersonEmailAddress{
                 person_id: person_id,
                 email: " alice+new@example.com ",
                 verified_at: verified_at
               })

      person = Person.apply(person, verified_event)

      assert %PersonPrimaryEmailAddressChanged{
               person_id: ^person_id,
               primary_email: "Alice+New@Example.COM",
               normalized_email: "alice+new@example.com"
             } =
               primary_changed_event =
               Person.execute(person, %MakePersonEmailAddressPrimary{
                 person_id: person_id,
                 email: "alice+new@example.com"
               })

      person = Person.apply(person, primary_changed_event)

      assert %Person{
               email: "Alice+New@Example.COM",
               email_addresses: [
                 %{normalized_email: "alice@example.com", is_primary: false},
                 %{normalized_email: "alice+new@example.com", is_primary: true}
               ]
             } = person

      assert %PersonEmailAddressRemoved{
               person_id: ^person_id,
               email: "alice@example.com",
               normalized_email: "alice@example.com"
             } =
               removed_event =
               Person.execute(person, %RemovePersonEmailAddress{
                 person_id: person_id,
                 email: " alice@example.com "
               })

      assert %Person{
               email: "Alice+New@Example.COM",
               email_addresses: [
                 %{normalized_email: "alice+new@example.com", is_primary: true}
               ]
             } = Person.apply(person, removed_event)
    end

    test "rejects individual email-address commands before the person is created" do
      person_id = Memba.ID.generate(:person)

      assert {:error, :person_not_created} =
               Person.execute(%Person{}, %AddPersonEmailAddress{
                 person_id: person_id,
                 email: "alice+new@example.com"
               })

      assert {:error, :person_not_created} =
               Person.execute(%Person{}, %VerifyPersonEmailAddress{
                 person_id: person_id,
                 email: "alice+new@example.com",
                 verified_at: ~U[2026-07-13 18:00:00Z]
               })

      assert {:error, :person_not_created} =
               Person.execute(%Person{}, %MakePersonEmailAddressPrimary{
                 person_id: person_id,
                 email: "alice+new@example.com"
               })

      assert {:error, :person_not_created} =
               Person.execute(%Person{}, %RemovePersonEmailAddress{
                 person_id: person_id,
                 email: "alice+new@example.com"
               })
    end
  end

  describe "execute/2 RenamePerson" do
    test "normalizes a valid name and emits a JSON-encodable event" do
      person_id = Memba.ID.generate(:person)
      person = created_person(person_id)

      assert %PersonRenamed{person_id: ^person_id, name: "Robin O’Connor"} =
               event =
               Person.execute(person, %RenamePerson{
                 person_id: person_id,
                 name: " \t Robin  \n O’Connor \u00A0",
                 expected_name: " Alice "
               })

      assert Jason.decode!(Jason.encode!(event)) == %{
               "person_id" => person_id,
               "name" => "Robin O’Connor"
             }
    end

    test "rejects blank names and enforces the 100-grapheme boundary" do
      person_id = Memba.ID.generate(:person)
      person = created_person(person_id)

      for invalid_name <- ["", " \t\n ", String.duplicate("é", 101)] do
        assert {:error, :invalid_name} =
                 Person.execute(person, %RenamePerson{
                   person_id: person_id,
                   name: invalid_name,
                   expected_name: "Alice"
                 })
      end

      name_at_limit = String.duplicate("é", 100)

      assert %PersonRenamed{name: ^name_at_limit} =
               Person.execute(person, %RenamePerson{
                 person_id: person_id,
                 name: name_at_limit,
                 expected_name: "Alice"
               })
    end

    test "returns authoritative current name for a stale edit and emits no event for an identical target" do
      person_id = Memba.ID.generate(:person)
      person = %Person{created_person(person_id) | name: " Alice   Jones "}

      assert {:error, {:name_changed, "Alice Jones"}} =
               Person.execute(person, %RenamePerson{
                 person_id: person_id,
                 name: "Alice Brown",
                 expected_name: "Alice Smith"
               })

      assert [] =
               Person.execute(person, %RenamePerson{
                 person_id: person_id,
                 name: " Alice \t Jones ",
                 expected_name: "an older baseline"
               })
    end

    test "confirmation remains conditional and a second intervening change conflicts again" do
      person_id = Memba.ID.generate(:person)
      smith = created_person(person_id)

      jones_event =
        Person.execute(smith, %RenamePerson{
          person_id: person_id,
          name: "Alice Jones",
          expected_name: "Alice"
        })

      jones = Person.apply(smith, jones_event)

      assert {:error, {:name_changed, "Alice Jones"}} =
               Person.execute(jones, %RenamePerson{
                 person_id: person_id,
                 name: "Alice Brown",
                 expected_name: "Alice"
               })

      assert %PersonRenamed{name: "Alice Brown"} =
               Person.execute(jones, %RenamePerson{
                 person_id: person_id,
                 name: "Alice Brown",
                 expected_name: "Alice Jones"
               })

      green_event =
        Person.execute(jones, %RenamePerson{
          person_id: person_id,
          name: "Alice Green",
          expected_name: "Alice Jones"
        })

      green = Person.apply(jones, green_event)

      assert {:error, {:name_changed, "Alice Green"}} =
               Person.execute(green, %RenamePerson{
                 person_id: person_id,
                 name: "Alice Brown",
                 expected_name: "Alice Jones"
               })
    end

    test "rejects missing people, malformed identities, and mismatched aggregate targets" do
      person_id = Memba.ID.generate(:person)

      command = %RenamePerson{
        person_id: person_id,
        name: "Alice Jones",
        expected_name: "Alice"
      }

      assert {:error, :person_not_created} = Person.execute(%Person{}, command)

      assert {:error, :invalid_person_id} =
               Person.execute(created_person(person_id), %{command | person_id: "invalid"})

      assert {:error, :invalid_person_id} =
               Person.execute(created_person(person_id), %{
                 command
                 | person_id: Memba.ID.generate(:person)
               })
    end
  end

  test "apply/2 records the created person identity, name, and email" do
    person_id = Memba.ID.generate(:person)
    legacy_verified_at = ~U[1970-01-01 00:00:00Z]

    assert %Person{
             person_id: ^person_id,
             name: "Alice",
             email: "alice@example.com",
             email_addresses: [
               %{
                 email: "alice@example.com",
                 normalized_email: "alice@example.com",
                 is_primary: true,
                 verified_at: ^legacy_verified_at
               }
             ]
           } =
             Person.apply(%Person{}, %PersonCreated{
               person_id: person_id,
               name: "Alice",
               email: "alice@example.com"
             })
  end

  test "apply/2 records replaced email addresses and primary email" do
    person_id = Memba.ID.generate(:person)
    legacy_verified_at = ~U[1970-01-01 00:00:00Z]

    person =
      Person.apply(%Person{}, %PersonCreated{
        person_id: person_id,
        name: "Alice",
        email: "alice@example.com"
      })

    email_addresses = [
      %{
        email: "alice@example.com",
        normalized_email: "alice@example.com",
        is_primary: false,
        verified_at: legacy_verified_at
      },
      %{
        email: "alice@work.example",
        normalized_email: "alice@work.example",
        is_primary: true,
        verified_at: legacy_verified_at
      }
    ]

    assert %Person{
             person_id: ^person_id,
             name: "Alice",
             email: "alice@work.example",
             email_addresses: ^email_addresses
           } =
             Person.apply(person, %PersonEmailAddressesReplaced{
               person_id: person_id,
               email_addresses: email_addresses,
               primary_email: "alice@work.example"
             })
  end

  test "old PersonCreated history replays and PersonRenamed changes only the name" do
    person_id = Memba.ID.generate(:person)

    replayed =
      Enum.reduce(
        [
          %PersonCreated{
            person_id: person_id,
            name: "Historical Alice",
            email: "alice@example.com"
          }
        ],
        %Person{},
        &Person.apply(&2, &1)
      )

    renamed =
      Person.apply(replayed, %PersonRenamed{
        person_id: person_id,
        name: "Alice Jones"
      })

    assert renamed.name == "Alice Jones"
    assert renamed.person_id == replayed.person_id
    assert renamed.email == replayed.email
    assert renamed.email_addresses == replayed.email_addresses
    assert renamed.merged_source_person_ids == replayed.merged_source_person_ids

    assert %PersonRenamed{name: "Alice Brown"} =
             Person.execute(renamed, %RenamePerson{
               person_id: person_id,
               name: "Alice Brown",
               expected_name: "Alice Jones"
             })
  end

  describe "execute/2 MergePerson" do
    test "preserves the target primary and records imported verified addresses" do
      target_id = Memba.ID.generate(:person)
      source_id = Memba.ID.generate(:person)
      person = created_person(target_id)
      verified_at = ~U[2026-10-13 06:00:00Z]

      command = %MergePerson{
        person_id: target_id,
        source_person_id: source_id,
        email_addresses: [
          hd(person.email_addresses),
          %{
            email: "alice@work.example",
            normalized_email: "alice@work.example",
            is_primary: false,
            verified_at: verified_at
          }
        ]
      }

      assert %PersonMerged{
               person_id: ^target_id,
               source_person_id: ^source_id,
               primary_email: "alice@example.com"
             } = event = Person.execute(person, command)

      merged = Person.apply(person, event)
      assert merged.email == "alice@example.com"
      assert source_id in merged.merged_source_person_ids
      assert Person.execute(merged, command) == []
    end

    test "rejects a pending imported address" do
      target_id = Memba.ID.generate(:person)
      person = created_person(target_id)

      assert {:error, :source_has_pending_email_address} =
               Person.execute(person, %MergePerson{
                 person_id: target_id,
                 source_person_id: Memba.ID.generate(:person),
                 email_addresses: [
                   hd(person.email_addresses),
                   %{
                     email: "pending@example.com",
                     normalized_email: "pending@example.com",
                     is_primary: false,
                     verified_at: nil
                   }
                 ]
               })
    end
  end

  defp created_person(person_id) do
    Person.apply(%Person{}, %PersonCreated{
      person_id: person_id,
      name: "Alice",
      email: "alice@example.com"
    })
  end
end
