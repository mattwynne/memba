defmodule Memba.Membership.PublicApiTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Membership
  alias Memba.Membership.App
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Commands.RemoveMemberRole
  alias Memba.Membership.Events.ClubCreated
  alias Memba.Membership.Events.ClubMemberInvitationAccepted
  alias Memba.Membership.Events.ClubMemberInvitationResent
  alias Memba.Membership.Events.ClubMemberInvited
  alias Memba.Membership.Events.ClubRoleDefined
  alias Memba.Membership.Events.ClubRolePermissionGranted
  alias Memba.Membership.Events.ClubUpdated
  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.MemberAdded
  alias Memba.Membership.Events.MemberRemoved
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.EmailAddressVerificationToken
  alias Memba.Membership.InvitationToken
  alias Memba.Membership.Permissions
  alias Memba.Membership.Projections.Club, as: ClubProjection
  alias Memba.Membership.Projections.ClubInvitation, as: ClubInvitationProjection
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Roles
  alias Memba.Membership.SystemGroups

  test "create_club/2 dispatches CreateClub through the Membership context" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kootenay-mountaineering-club"
                },
                %ClubRoleDefined{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  role_key: "admin",
                  name: "Admin"
                },
                %ClubRolePermissionGranted{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  permission: "club.manage_members"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^everyone_group_id,
                  group_key: "everyone",
                  name: "Everyone"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  group_key: "admin",
                  name: "Admin"
                }
              ]
            }} =
             Membership.create_club(
               %{"club_id" => club_id, "name" => " Kootenay Mountaineering Club "},
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{club_id: ^club_id, name: "Kootenay Mountaineering Club"} =
             Membership.get_club(club_id)
  end

  test "create_club/2 allows an address-safe slug override and rejects invalid slugs" do
    club_id = Memba.ID.generate(:club)
    role_id = Roles.membership_administrator_role_id(club_id)
    everyone_group_id = SystemGroups.everyone_group_id(club_id)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubCreated{
                  club_id: ^club_id,
                  name: "Kootenay Mountaineering Club",
                  slug: "kmc"
                },
                %ClubRoleDefined{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  role_key: "admin",
                  name: "Admin"
                },
                %ClubRolePermissionGranted{
                  club_id: ^club_id,
                  role_id: ^role_id,
                  permission: "club.manage_members"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^everyone_group_id,
                  group_key: "everyone",
                  name: "Everyone"
                },
                %GroupCreated{
                  club_id: ^club_id,
                  group_id: ^admin_group_id,
                  group_key: "admin",
                  name: "Admin"
                }
              ]
            }} =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               returning: :execution_result,
               consistency: :strong
             )

    assert {:error, :invalid_format} =
             Membership.create_club(%{
               club_id: Memba.ID.generate(:club),
               name: "Kootenay Mountaineering Club",
               slug: "kmc club!"
             })
  end

  test "create_club/2 rejects duplicate slugs before dispatching a new club" do
    existing_club_id = Memba.ID.generate(:club)
    duplicate_club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: existing_club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert {:error, :slug_taken} =
             Membership.create_club(
               %{
                 club_id: duplicate_club_id,
                 name: "KMC Duplicate Club",
                 slug: "kmc"
               },
               consistency: :strong
             )

    assert %ClubProjection{club_id: ^existing_club_id, slug: "kmc"} =
             Membership.get_club_by_slug("kmc")

    assert is_nil(Membership.get_club(duplicate_club_id))
  end

  test "update_club/2 edits a projected club name and slug" do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^club_id,
              events: [
                %ClubUpdated{
                  club_id: ^club_id,
                  name: "KMC Alpine Club",
                  slug: "kmc-alpine"
                }
              ]
            }} =
             Membership.update_club(
               %{
                 "club_id" => club_id,
                 "name" => " KMC Alpine Club ",
                 "slug" => "kmc-alpine"
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %ClubProjection{
             club_id: ^club_id,
             name: "KMC Alpine Club",
             slug: "kmc-alpine"
           } = Membership.get_club(club_id)
  end

  test "update_club/2 rejects invalid and duplicate slugs" do
    kootenay_id = Memba.ID.generate(:club)
    nelson_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: kootenay_id, name: "Kootenay Mountaineering Club", slug: "kmc"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_club(
               %{club_id: nelson_id, name: "Nelson Cycling Club", slug: "nelson-cycling"},
               consistency: :strong
             )

    assert {:error, :invalid_format} =
             Membership.update_club(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "KMC Club!"
             })

    assert {:error, :slug_taken} =
             Membership.update_club(%{
               club_id: kootenay_id,
               name: "Kootenay Mountaineering Club",
               slug: "nelson-cycling"
             })
  end

  test "create_person/2 dispatches CreatePerson through the Membership context" do
    person_id = Memba.ID.generate(:person)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonCreated{
                  person_id: ^person_id,
                  name: "Alice",
                  email: "alice@example.com"
                }
              ]
            }} =
             Membership.create_person(
               %{person_id: person_id, name: " Alice ", email: " Alice@Example.COM "},
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{person_id: ^person_id, name: "Alice", email: "alice@example.com"} =
             Membership.get_person(person_id)

    assert %PersonEmailAddress{
             person_id: ^person_id,
             normalized_email: "alice@example.com",
             is_primary: true,
             verified_at: %DateTime{}
           } = Repo.get_by(PersonEmailAddress, person_id: person_id)
  end

  test "create_person/2 accepts an email-address set for new staff create flows" do
    person_id = Memba.ID.generate(:person)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
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
              ]
            }} =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: " Alice ",
                 email_addresses: [
                   %{email: " Alice@Example.COM ", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@work.example"
             )
  end

  test "create_person/2 rejects globally duplicate normalized email addresses before dispatch" do
    existing_person_id = Memba.ID.generate(:person)
    duplicate_person_id = Memba.ID.generate(:person)
    duplicate_alternate_person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: existing_person_id,
                 name: "Alice",
                 email: "Alice@Example.COM"
               },
               consistency: :strong
             )

    assert {:error, :email_address_taken} =
             Membership.create_person(
               %{
                 person_id: duplicate_person_id,
                 name: "Duplicate Alice",
                 email: " alice@example.com "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert {:error, :email_address_taken} =
             Membership.create_person(
               %{
                 person_id: duplicate_alternate_person_id,
                 name: "Duplicate Alternate Alice",
                 email_addresses: [
                   %{email: "duplicate@example.com", is_primary: true},
                   %{email: " ALICE@EXAMPLE.COM ", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert is_nil(Membership.get_person(duplicate_person_id))
    assert is_nil(Membership.get_person(duplicate_alternate_person_id))
  end

  test "replace_person_email_addresses/2 keeps staff-added alternate addresses pending" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressesReplaced{
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
                      email: "alice@work.example",
                      normalized_email: "alice@work.example",
                      is_primary: false,
                      verified_at: nil
                    }
                  ]
                }
              ]
            }} =
             Membership.replace_person_email_addresses(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "alice@work.example", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com",
               is_primary: true
             )

    assert %PersonEmailAddress{verified_at: nil} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@work.example",
               is_primary: false
             )
  end

  test "replace_person_email_addresses/2 rejects a newly introduced primary address" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert {:error, :primary_email_address_not_verified} =
             Membership.replace_person_email_addresses(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: false},
                   %{email: "alice@work.example", is_primary: true}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  test "replace_person_email_addresses/2 rejects addresses already attached to another person" do
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: alice_id, name: "Alice", email: "Alice@Example.COM"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{person_id: bob_id, name: "Bob", email: "bob@example.com"},
               consistency: :strong
             )

    assert {:error, :email_address_taken} =
             Membership.replace_person_email_addresses(
               %{
                 person_id: bob_id,
                 email_addresses: [
                   %{email: "bob@example.com", is_primary: true},
                   %{email: " alice@example.com ", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert [
             %{
               email: "bob@example.com",
               normalized_email: "bob@example.com",
               primary?: true,
               verified_at: %DateTime{}
             }
           ] = Membership.list_person_email_addresses(bob_id)
  end

  test "replace_person_email_addresses/2 preserves verified addresses and revokes removed pending verification tokens" do
    person_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-07-13 20:00:00.000000Z]
    parent = self()

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: " Alice+Verified@Example.COM "},
               consistency: :strong
             )

    assert :ok =
             Membership.verify_person_email_address(
               %{
                 person_id: person_id,
                 email: "alice+verified@example.com",
                 verified_at: verified_at
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: " Alice+Stale@Example.COM "},
               consistency: :strong
             )

    verification_revoker = fn request ->
      send(parent, {:verification_revoked, request})
      :ok
    end

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressesReplaced{
                  person_id: ^person_id,
                  primary_email: "alice@example.com",
                  email_addresses: [
                    %{
                      normalized_email: "alice@example.com",
                      is_primary: true,
                      verified_at: %DateTime{}
                    },
                    %{
                      normalized_email: "alice+verified@example.com",
                      is_primary: false,
                      verified_at: ^verified_at
                    }
                  ]
                }
              ]
            }} =
             Membership.replace_person_email_addresses(
               %{
                 person_id: person_id,
                 email_addresses: [
                   %{email: "alice@example.com", is_primary: true},
                   %{email: "Alice+Verified@Example.COM", is_primary: false}
                 ]
               },
               returning: :execution_result,
               consistency: :strong,
               verification_revoker: verification_revoker
             )

    assert_received {:verification_revoked,
                     %{
                       person_id: ^person_id,
                       email: "Alice+Stale@Example.COM",
                       normalized_email: "alice+stale@example.com"
                     }}

    assert %PersonEmailAddress{verified_at: ^verified_at} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+verified@example.com"
             )

    refute Repo.get_by(PersonEmailAddress,
             person_id: person_id,
             normalized_email: "alice+stale@example.com"
           )
  end

  test "person email-address lifecycle APIs dispatch commands and update the read model" do
    person_id = Memba.ID.generate(:person)
    verified_at = ~U[2026-07-13 19:00:00.000000Z]

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressAdded{
                  person_id: ^person_id,
                  email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             Membership.add_person_email_address(
               %{person_id: person_id, email: " Alice+New@Example.COM "},
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{
             person_id: ^person_id,
             email: "Alice+New@Example.COM",
             normalized_email: "alice+new@example.com",
             is_primary: false,
             verified_at: nil
           } =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressVerified{
                  person_id: ^person_id,
                  normalized_email: "alice+new@example.com",
                  verified_at: ^verified_at
                }
              ]
            }} =
             Membership.verify_person_email_address(
               %{person_id: person_id, email: "alice+new@example.com", verified_at: verified_at},
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: ^verified_at} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonPrimaryEmailAddressChanged{
                  person_id: ^person_id,
                  primary_email: "Alice+New@Example.COM",
                  normalized_email: "alice+new@example.com"
                }
              ]
            }} =
             Membership.make_person_email_address_primary(
               %{person_id: person_id, email: "alice+new@example.com"},
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{email: "Alice+New@Example.COM"} = Membership.get_person(person_id)

    assert %PersonEmailAddress{is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )

    assert %PersonEmailAddress{is_primary: true} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^person_id,
              events: [
                %PersonEmailAddressRemoved{
                  person_id: ^person_id,
                  email: "alice@example.com",
                  normalized_email: "alice@example.com"
                }
              ]
            }} =
             Membership.remove_person_email_address(
               %{person_id: person_id, email: "alice@example.com"},
               returning: :execution_result,
               consistency: :strong
             )

    assert is_nil(
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice@example.com"
             )
           )
  end

  test "person email-address lifecycle APIs enforce pending, primary, removal, and duplicate rules" do
    alice_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: alice_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{person_id: bob_id, name: "Bob", email: "bob@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: alice_id, email: " Alice.Pending@Example.COM "},
               consistency: :strong
             )

    assert {:error, :email_address_not_verified} =
             Membership.make_person_email_address_primary(
               %{person_id: alice_id, email: "alice.pending@example.com"},
               consistency: :strong
             )

    assert {:error, :primary_email_address_cannot_be_removed} =
             Membership.remove_person_email_address(
               %{person_id: alice_id, email: "alice@example.com"},
               consistency: :strong
             )

    assert {:error, :email_address_taken} =
             Membership.add_person_email_address(
               %{person_id: bob_id, email: " ALICE.PENDING@example.com "},
               consistency: :strong
             )

    assert [
             %{
               normalized_email: "alice@example.com",
               primary?: true,
               verified_at: %DateTime{}
             },
             %{
               normalized_email: "alice.pending@example.com",
               primary?: false,
               verified_at: nil
             }
           ] = Membership.list_person_email_addresses(alice_id)

    assert [
             %{
               normalized_email: "bob@example.com",
               primary?: true,
               verified_at: %DateTime{}
             }
           ] = Membership.list_person_email_addresses(bob_id)
  end

  test "verify_pending_person_email_address_for_sign_in/2 verifies a pending known address without making it primary" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice.primary@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: "Alice.Pending@Example.COM"},
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: nil, is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.pending@example.com"
             )

    assert :ok =
             Membership.verify_pending_person_email_address_for_sign_in(
               " ALICE.PENDING@example.com ",
               consistency: :strong
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}, is_primary: false} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.pending@example.com"
             )

    assert %PersonEmailAddress{verified_at: %DateTime{}, is_primary: true} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice.primary@example.com"
             )

    assert %PersonProjection{email: "alice.primary@example.com"} =
             Membership.get_person(person_id)

    events_after_verification = count_events()

    assert :ok =
             Membership.verify_pending_person_email_address_for_sign_in(
               "alice.pending@example.com",
               consistency: :strong
             )

    assert :ok =
             Membership.verify_pending_person_email_address_for_sign_in(
               "unknown@example.com",
               consistency: :strong
             )

    assert count_events() == events_after_verification
  end

  test "resend_person_email_address_verification/2 issues for pending address without appending a domain event" do
    person_id = Memba.ID.generate(:person)
    parent = self()

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: " Alice+New@Example.COM "},
               consistency: :strong
             )

    events_before = count_events()

    verification_issuer = fn request ->
      send(parent, {:verification_issued, request})
      {:ok, %{verification_token: "fresh-token"}}
    end

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com",
              issuer_result: %{verification_token: "fresh-token"}
            }} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: " alice+new@example.com "},
               verification_issuer: verification_issuer
             )

    assert_received {:verification_issued,
                     %{
                       person_id: ^person_id,
                       email: "Alice+New@Example.COM",
                       normalized_email: "alice+new@example.com"
                     }}

    assert count_events() == events_before

    assert %PersonEmailAddress{verified_at: nil} =
             Repo.get_by(PersonEmailAddress,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )
  end

  test "resend_person_email_address_verification/2 rejects non-pending addresses before issuing" do
    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    verification_issuer = fn _request ->
      flunk("verified primary addresses must not receive verification email")
    end

    assert {:error, :email_address_already_verified} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: "alice@example.com"},
               verification_issuer: verification_issuer
             )
  end

  test "resend_person_email_address_verification/2 stores a scoped 15-minute one-use token" do
    person_id = Memba.ID.generate(:person)
    now = ~U[2026-07-13 21:00:00.000000Z]
    consumed_at = DateTime.add(now, 60, :second)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: " Alice+New@Example.COM "},
               consistency: :strong
             )

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com",
              issuer_result: %{
                token: token,
                expires_at: expires_at
              }
            }} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: now
             )

    assert is_binary(token)
    assert expires_at == DateTime.add(now, 15 * 60, :second)

    assert %EmailAddressVerificationToken{
             person_id: ^person_id,
             normalized_email: "alice+new@example.com",
             token_hash: token_hash,
             expires_at: ^expires_at,
             consumed_at: nil,
             revoked_at: nil
           } =
             Repo.get_by(EmailAddressVerificationToken,
               person_id: person_id,
               normalized_email: "alice+new@example.com"
             )

    assert token_hash == :crypto.hash(:sha256, token)
    refute token_hash == token

    assert {:ok,
            %{
              person_id: ^person_id,
              email: "Alice+New@Example.COM",
              normalized_email: "alice+new@example.com"
            }} =
             Membership.consume_person_email_address_verification_token(token, now: consumed_at)

    assert %EmailAddressVerificationToken{consumed_at: ^consumed_at} =
             Repo.get_by(EmailAddressVerificationToken, token_hash: token_hash)

    assert {:error, :consumed} =
             Membership.consume_person_email_address_verification_token(token,
               now: DateTime.add(consumed_at, 1, :second)
             )
  end

  test "consume_person_email_address_verification_token/2 rejects expired and non-pending tokens" do
    person_id = Memba.ID.generate(:person)
    issued_at = ~U[2026-07-13 21:30:00.000000Z]

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: "alice+new@example.com"},
               consistency: :strong
             )

    assert {:ok, %{issuer_result: %{token: expired_token}}} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: issued_at
             )

    assert {:error, :expired} =
             Membership.consume_person_email_address_verification_token(expired_token,
               now: DateTime.add(issued_at, 15 * 60, :second)
             )

    assert {:ok, %{issuer_result: %{token: verified_token}}} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: "alice+new@example.com"},
               now: issued_at
             )

    assert :ok =
             Membership.verify_person_email_address(
               %{person_id: person_id, email: "alice+new@example.com"},
               consistency: :strong
             )

    assert {:error, :email_address_already_verified} =
             Membership.consume_person_email_address_verification_token(verified_token,
               now: DateTime.add(issued_at, 60, :second)
             )
  end

  test "old verification tokens cannot verify removed and re-added pending addresses" do
    person_id = Memba.ID.generate(:person)
    now = ~U[2026-07-13 22:00:00.000000Z]

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: "alice+stale@example.com"},
               consistency: :strong
             )

    assert {:ok, %{issuer_result: %{token: stale_token}}} =
             Membership.resend_person_email_address_verification(
               %{person_id: person_id, email: "alice+stale@example.com"},
               now: now
             )

    stale_token_hash = :crypto.hash(:sha256, stale_token)

    assert :ok =
             Membership.remove_person_email_address(
               %{person_id: person_id, email: "alice+stale@example.com"},
               consistency: :strong
             )

    assert %EmailAddressVerificationToken{revoked_at: %DateTime{}} =
             Repo.get_by(EmailAddressVerificationToken, token_hash: stale_token_hash)

    assert :ok =
             Membership.add_person_email_address(
               %{person_id: person_id, email: "alice+stale@example.com"},
               consistency: :strong
             )

    assert {:error, :revoked} =
             Membership.consume_person_email_address_verification_token(stale_token,
               now: DateTime.add(now, 60, :second)
             )
  end

  test "add_member/2 dispatches AddMember and prevents duplicate active club memberships" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Alice",
                 email: "alice@example.com"
               },
               consistency: :strong
             )

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^membership_id,
              events: [
                %MemberAdded{
                  membership_id: ^membership_id,
                  club_id: ^club_id,
                  person_id: ^person_id
                }
              ]
            }} =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               returning: :execution_result,
               consistency: :strong
             )

    assert Membership.active_member_of_club?(club_id, person_id)

    assert {:error, :already_active_member} =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    assert [%{id: ^person_id, membership_id: ^membership_id}] =
             Membership.list_active_members_of_club(club_id)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^membership_id,
              events: [%MemberRemoved{membership_id: ^membership_id}]
            }} =
             Membership.remove_member(%{membership_id: membership_id},
               returning: :execution_result,
               consistency: :strong
             )

    refute Membership.active_member_of_club?(club_id, person_id)
    assert [] = Membership.list_active_members_of_club(club_id)
  end

  test "invite_club_member/2 preserves Staff/system invitations without requiring a club-member actor" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              invitation_token: invitation_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvited{
                    invitation_id: ^invitation_id,
                    club_id: ^club_id,
                    email: "Robin@Example.COM",
                    normalized_email: "robin@example.com",
                    token_hash: token_hash
                  }
                ]
              }
            }} =
             Membership.invite_club_member(
               %{
                 invitation_id: invitation_id,
                 club_id: club_id,
                 email: " Robin@Example.COM "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert is_binary(invitation_token)
    refute invitation_token == token_hash
    assert InvitationToken.hash_token(invitation_token) == token_hash

    assert %ClubInvitationProjection{
             invitation_id: ^invitation_id,
             club_id: ^club_id,
             email: "Robin@Example.COM",
             normalized_email: "robin@example.com",
             token_hash: ^token_hash,
             status: "pending",
             resend_count: 0
           } = Membership.get_club_member_invitation(invitation_id)

    assert [] = Membership.list_active_members_of_club(club_id)
  end

  test "invite_club_member/2 rejects an active club member by normalized email" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    invitation_id = Memba.ID.generate(:club_invitation)

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: "Robin",
                 email_addresses: [
                   %{email: "robin@example.com", is_primary: true},
                   %{email: "Robin@Work.Example", is_primary: false}
                 ]
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    assert {:error, :already_active_member} =
             Membership.invite_club_member(
               %{invitation_id: invitation_id, club_id: club_id, email: " robin@work.example "},
               returning: :execution_result,
               consistency: :strong
             )

    assert is_nil(Membership.get_club_member_invitation(invitation_id))
  end

  test "invite_club_member/2 resends a pending invitation by normalized club email" do
    club_id = Memba.ID.generate(:club)
    original_invitation_id = Memba.ID.generate(:club_invitation)
    duplicate_invitation_id = Memba.ID.generate(:club_invitation)

    assert {:ok, %{invitation_token: first_token}} =
             Membership.invite_club_member(
               %{
                 invitation_id: original_invitation_id,
                 club_id: club_id,
                 email: "Robin@Example.COM"
               },
               consistency: :strong
             )

    first_hash = InvitationToken.hash_token(first_token)

    assert {:ok,
            %{
              invitation_id: ^original_invitation_id,
              invitation_token: second_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^original_invitation_id,
                events: [
                  %ClubMemberInvitationResent{
                    invitation_id: ^original_invitation_id,
                    token_hash: second_hash
                  }
                ]
              }
            }} =
             Membership.invite_club_member(
               %{
                 invitation_id: duplicate_invitation_id,
                 club_id: club_id,
                 email: " robin@example.com "
               },
               returning: :execution_result,
               consistency: :strong
             )

    refute second_token == first_token
    refute second_hash == first_hash
    assert InvitationToken.hash_token(second_token) == second_hash

    assert is_nil(Membership.get_club_member_invitation(duplicate_invitation_id))

    assert %ClubInvitationProjection{
             invitation_id: ^original_invitation_id,
             normalized_email: "robin@example.com",
             token_hash: ^second_hash,
             resend_count: 1,
             status: "pending"
           } =
             Membership.get_pending_club_member_invitation_by_email(club_id, "ROBIN@example.com")
  end

  test "resend_club_member_invitation/2 rotates the token for the pending club email" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)

    assert {:ok, %{invitation_token: first_token}} =
             Membership.invite_club_member(
               %{invitation_id: invitation_id, club_id: club_id, email: "robin@example.com"},
               consistency: :strong
             )

    first_hash = InvitationToken.hash_token(first_token)

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              invitation_token: second_token,
              execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationResent{
                    invitation_id: ^invitation_id,
                    token_hash: second_hash
                  }
                ]
              }
            }} =
             Membership.resend_club_member_invitation(
               %{club_id: club_id, email: " ROBIN@example.com "},
               returning: :execution_result,
               consistency: :strong
             )

    refute second_token == first_token
    refute second_hash == first_hash
    assert InvitationToken.hash_token(second_token) == second_hash

    assert %ClubInvitationProjection{
             invitation_id: ^invitation_id,
             token_hash: ^second_hash,
             resend_count: 1,
             status: "pending"
           } =
             Membership.get_pending_club_member_invitation_by_email(club_id, "robin@example.com")
  end

  test "accept_club_member_invitation_for_existing_person/2 creates membership and accepts" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "Alice@Example.COM"},
               consistency: :strong
             )

    assert {:ok, %{invitation_token: _token}} =
             Membership.invite_club_member(
               %{invitation_id: invitation_id, club_id: club_id, email: " alice@example.com "},
               consistency: :strong
             )

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              club_id: ^club_id,
              person_id: ^person_id,
              membership_id: ^membership_id,
              membership_execution_result: %ExecutionResult{
                aggregate_uuid: ^membership_id,
                events: [
                  %MemberAdded{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id
                  }
                ]
              },
              invitation_execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationAccepted{
                    invitation_id: ^invitation_id,
                    person_id: ^person_id,
                    membership_id: ^membership_id
                  }
                ]
              }
            }} =
             Membership.accept_club_member_invitation_for_existing_person(
               %{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert Membership.active_member_of_club?(club_id, person_id)

    assert %ClubInvitationProjection{
             status: "accepted",
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = Membership.get_club_member_invitation(invitation_id)
  end

  test "complete_invited_club_member_profile/2 creates person, membership, and acceptance" do
    club_id = Memba.ID.generate(:club)
    invitation_id = Memba.ID.generate(:club_invitation)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)

    assert {:ok, %{invitation_token: _token}} =
             Membership.invite_club_member(
               %{invitation_id: invitation_id, club_id: club_id, email: " Robin@Example.COM "},
               consistency: :strong
             )

    assert is_nil(Membership.get_person(person_id))

    assert {:ok,
            %{
              invitation_id: ^invitation_id,
              club_id: ^club_id,
              person_id: ^person_id,
              membership_id: ^membership_id,
              person_execution_result: %ExecutionResult{
                aggregate_uuid: ^person_id,
                events: [
                  %PersonCreated{
                    person_id: ^person_id,
                    name: "Robin"
                  },
                  %PersonEmailAddressesReplaced{
                    person_id: ^person_id,
                    primary_email: "Robin@Example.COM"
                  }
                ]
              },
              membership_execution_result: %ExecutionResult{
                aggregate_uuid: ^membership_id,
                events: [
                  %MemberAdded{
                    membership_id: ^membership_id,
                    club_id: ^club_id,
                    person_id: ^person_id
                  }
                ]
              },
              invitation_execution_result: %ExecutionResult{
                aggregate_uuid: ^invitation_id,
                events: [
                  %ClubMemberInvitationAccepted{
                    invitation_id: ^invitation_id,
                    person_id: ^person_id,
                    membership_id: ^membership_id
                  }
                ]
              }
            }} =
             Membership.complete_invited_club_member_profile(
               %{
                 invitation_id: invitation_id,
                 person_id: person_id,
                 membership_id: membership_id,
                 name: " Robin "
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert %PersonProjection{
             person_id: ^person_id,
             name: "Robin",
             email: "Robin@Example.COM"
           } = Membership.get_person(person_id)

    assert [%{email: "Robin@Example.COM", normalized_email: "robin@example.com", primary?: true}] =
             Membership.list_person_email_addresses(person_id)

    assert %MembershipProjection{
             membership_id: ^membership_id,
             club_id: ^club_id,
             person_id: ^person_id,
             active: true
           } = Repo.get(MembershipProjection, membership_id)

    assert %ClubInvitationProjection{
             status: "accepted",
             accepted_person_id: ^person_id,
             accepted_membership_id: ^membership_id
           } = Membership.get_club_member_invitation(invitation_id)
  end

  test "person_has_club_permission?/3 checks backend projected member permissions" do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    role_id = Roles.membership_administrator_role_id(club_id)
    permission = Permissions.club_manage_members()

    assert :ok =
             Membership.create_club(
               membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
               consistency: :strong
             )

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: "Alice", email: "alice@example.com"},
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    refute Membership.person_has_club_permission?(club_id, person_id, permission)

    assert :ok =
             App.dispatch(
               %AssignMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    assert Membership.person_has_club_permission?(club_id, person_id, permission)
    refute Membership.person_has_club_permission?("not-a-club-id", person_id, permission)
    refute Membership.person_has_club_permission?(club_id, "not-a-person-id", permission)
    refute Membership.person_has_club_permission?(club_id, person_id, "club.manage_trips")

    assert :ok =
             App.dispatch(
               %RemoveMemberRole{
                 club_id: club_id,
                 membership_id: membership_id,
                 person_id: person_id,
                 role_id: role_id
               },
               consistency: :strong
             )

    refute Membership.person_has_club_permission?(club_id, person_id, permission)
  end

  defp count_events do
    %{rows: [[count]]} = Repo.query!(~S|SELECT count(*) FROM "event_store"."events"|)

    count
  end
end
