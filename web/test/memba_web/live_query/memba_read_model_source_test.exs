defmodule MembaWeb.LiveQuery.MembaReadModelSourceTest do
  use MembaWeb.ConnCase, async: true

  alias Memba.Membership.Events.{
    ClubCreated,
    ClubMemberAdded,
    ClubMemberRemoved,
    ClubRoleAssignedToMember,
    ClubRoleDefined,
    ClubRolePermissionGranted,
    ClubRoleRemovedFromMember,
    ClubUpdated,
    GroupCreated,
    GroupEmailSlugAssigned,
    GroupMemberAdded,
    GroupMemberRemoved,
    MemberAdded,
    MemberRemoved,
    MemberRoleAssigned,
    MemberRoleRemoved,
    PersonCreated,
    PersonEmailAddressAdded,
    PersonEmailAddressRemoved,
    PersonEmailAddressVerified,
    PersonEmailAddressesReplaced,
    PersonPrimaryEmailAddressChanged
  }

  alias Memba.Membership.Projections.Membership, as: MembershipProjection

  alias Memba.Messaging.Events.{
    ConversationAccessGrantedToGroup,
    ConversationAccessRevokedFromGroup,
    ConversationFollowed,
    ConversationUnfollowed,
    EmailDeliveryBounced,
    EmailDeliveryCreated,
    EmailDeliveryDelayed,
    EmailDeliveryDelivered,
    EmailDeliveryOpened,
    EmailDeliverySpamComplaint,
    MessageSent
  }

  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias Memba.Repo
  alias LiveQuery.Source
  alias MembaWeb.LiveQuery.MembaReadModelSource

  test "subscribes to the shared committed read-model topic" do
    source = MembaReadModelSource.new()

    assert :ok = Source.subscribe(source)

    notification =
      {:read_model_changed,
       %{
         projector: Memba.Membership.Projectors.Person,
         source_event: %PersonEmailAddressAdded{
           person_id: "person-1",
           email: "alice@example.com",
           normalized_email: "alice@example.com"
         },
         metadata: %{},
         changes: %{}
       }}

    Phoenix.PubSub.broadcast(Memba.PubSub, Memba.ReadModelChanges.topic(), notification)

    assert_receive ^notification
  end

  test "classifies club-member collection entry and exact represented identities" do
    source = MembaReadModelSource.new()

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Membership,
                 %ClubMemberAdded{
                   club_id: "club-1",
                   membership_id: "membership-1",
                   person_id: "person-1"
                 }
               )
             )

    assert {:club_members, "club-1"} in invalidations
    assert {:membership, "membership-1"} in invalidations
    assert {:person, "person-1"} in invalidations
    assert {:person_clubs, "person-1"} in invalidations
  end

  test "matches Person changes only to the represented Person unless scope is unavailable" do
    source = MembaReadModelSource.new()

    assert {:ok, [{:person, "person-1"}, {:person_emails, "person-1"}]} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Person,
                 %PersonEmailAddressAdded{
                   person_id: "person-1",
                   email: "alice@example.com",
                   normalized_email: "alice@example.com"
                 }
               )
             )

    assert Source.matches?(source, {:person, "person-1"}, {:person, "person-1"})
    refute Source.matches?(source, {:person, "person-2"}, {:person, "person-1"})

    assert {:ok, [{:fallback, :person}]} =
             Source.classify(
               source,
               notification(Memba.Membership.Projectors.Person, %{})
             )
  end

  test "keeps represented role badges distinct from current-actor permissions" do
    source = MembaReadModelSource.new()

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Role,
                 %ClubRoleAssignedToMember{
                   club_id: "club-1",
                   membership_id: "membership-1",
                   person_id: "person-1",
                   role_id: "role-1"
                 }
               )
             )

    assert {:member_roles, "club-1", "membership-1", "person-1"} in invalidations
    assert {:member_permissions, "club-1", "membership-1", "person-1"} in invalidations
    assert {:role, "role-1"} in invalidations
  end

  test "uses club-conversation invalidation for root messages and replies" do
    source = MembaReadModelSource.new()

    event = %MessageSent{
      message_id: "message-2",
      club_id: "club-1",
      sender_id: "person-1",
      conversation_id: "message-1",
      reply_to_message_id: "message-1",
      subject: "Re: Plans",
      body: "Count me in"
    }

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.Message, event)
             )

    assert {:message, "message-2"} in invalidations
    assert {:conversation, "message-1"} in invalidations
    assert {:conversation_messages, "message-1"} in invalidations
    assert {:club_conversations, "club-1"} in invalidations
  end

  test "classifies Club, Group, GroupMembership and conversation access scopes" do
    source = MembaReadModelSource.new()

    assert {:ok, [{:club, "club-1"}]} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Club,
                 %ClubUpdated{club_id: "club-1", name: "Updated", slug: "updated"}
               )
             )

    assert {:ok, group_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.Group,
                 %GroupEmailSlugAssigned{
                   club_id: "club-1",
                   group_id: "group-1",
                   email_slug: "planning"
                 }
               )
             )

    assert {:club_groups, "club-1"} in group_invalidations
    assert {:group, "group-1"} in group_invalidations
    refute Source.matches?(source, {:club_groups, "club-2"}, {:club_groups, "club-1"})

    assert {:ok, membership_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %GroupMemberAdded{
                   club_id: "club-1",
                   group_id: "group-1",
                   membership_id: "membership-1",
                   person_id: "person-1"
                 }
               )
             )

    assert {:group_members, "group-1"} in membership_invalidations
    assert {:person, "person-1"} in membership_invalidations
    assert {:person_groups, "club-1", "person-1"} in membership_invalidations
    assert {:group_participation, "club-1", "group-1", "person-1"} in membership_invalidations

    assert {:ok, access_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationGroupAccess,
                 %ConversationAccessGrantedToGroup{
                   club_id: "club-1",
                   group_id: "group-1",
                   conversation_id: "conversation-1",
                   access_level: "write"
                 }
               )
             )

    assert {:group_conversations, "group-1"} in access_invalidations
    assert {:conversation_access, "group-1", "conversation-1"} in access_invalidations
  end

  test "uses club and global conservative fallbacks when exact scope is missing" do
    source = MembaReadModelSource.new()

    assert {:ok, membership_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %{club_id: "club-1", group_id: "group-1"}
               )
             )

    assert {:group_members, "group-1"} in membership_invalidations
    assert {:fallback, :group_membership, "club-1"} in membership_invalidations

    assert {:ok, [{:fallback, :role, "club-1"}]} =
             Source.classify(
               source,
               notification(Memba.Membership.Projectors.Role, %{club_id: "club-1"})
             )

    assert {:ok, [{:fallback, :conversation_access}]} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.ConversationGroupAccess, %{})
             )
  end

  test "retains role identity and adds a global fallback when club scope is missing" do
    source = MembaReadModelSource.new()

    for event <- [
          %ClubRoleDefined{
            club_id: nil,
            role_id: "role-1",
            role_key: "trip_lead",
            name: "Trip Lead"
          },
          %ClubRolePermissionGranted{
            club_id: nil,
            role_id: "role-1",
            permission: "club.manage_members"
          }
        ] do
      assert {:ok, invalidations} =
               Source.classify(
                 source,
                 notification(Memba.Membership.Projectors.Role, event)
               )

      assert {:role, "role-1"} in invalidations
      assert {:fallback, :role} in invalidations
    end
  end

  test "retains Message identities and adds a global fallback when club scope is missing" do
    source = MembaReadModelSource.new()

    event = %MessageSent{
      message_id: "message-2",
      club_id: nil,
      sender_id: "person-1",
      conversation_id: "message-1",
      reply_to_message_id: "message-1",
      subject: "Re: Plans",
      body: "Count me in"
    }

    assert {:ok, invalidations} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.Message, event)
             )

    assert {:message, "message-2"} in invalidations
    assert {:conversation, "message-1"} in invalidations
    assert {:conversation_messages, "message-1"} in invalidations
    assert {:fallback, :message} in invalidations
  end

  test "retains partial GroupMembership scopes and adds participation fallbacks" do
    source = MembaReadModelSource.new()

    assert {:ok, missing_group} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %{club_id: "club-1", person_id: "person-1"}
               )
             )

    assert {:person, "person-1"} in missing_group
    assert {:person_groups, "club-1", "person-1"} in missing_group
    assert {:fallback, :group_membership, "club-1"} in missing_group

    assert {:ok, missing_person} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %{club_id: "club-1", group_id: "group-1"}
               )
             )

    assert {:group_members, "group-1"} in missing_person
    assert {:fallback, :group_membership, "club-1"} in missing_person

    assert {:ok, missing_club} =
             Source.classify(
               source,
               notification(
                 Memba.Membership.Projectors.GroupMembership,
                 %{group_id: "group-1", person_id: "person-1"}
               )
             )

    assert {:group_members, "group-1"} in missing_club
    assert {:person, "person-1"} in missing_club
    assert {:fallback, :group_membership} in missing_club
  end

  test "classifies explicit and MessageSent conversation follows by conversation and member" do
    source = MembaReadModelSource.new()

    assert {:ok, explicit_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationFollow,
                 %ConversationFollowed{
                   follow_id: "follow-1",
                   club_id: "club-1",
                   conversation_id: "conversation-1",
                   member_id: "person-1"
                 }
               )
             )

    assert {:conversation_follow, "conversation-1", "person-1"} in explicit_invalidations

    assert {:ok, sent_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationFollow,
                 %MessageSent{
                   message_id: "conversation-2",
                   club_id: "club-1",
                   sender_id: "person-2",
                   conversation_id: nil,
                   reply_to_message_id: nil,
                   subject: "Plans",
                   body: "Meet at eight"
                 }
               )
             )

    assert {:conversation_follow, "conversation-2", "person-2"} in sent_invalidations
    refute {:conversation_follow, "conversation-2", "person-1"} in sent_invalidations
  end

  test "retains partial conversation-follow scope with a conservative fallback" do
    source = MembaReadModelSource.new()

    assert {:ok, conversation_scoped} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationFollow,
                 %{conversation_id: "conversation-1"}
               )
             )

    assert {:conversation_follows, "conversation-1"} in conversation_scoped
    refute {:fallback, :conversation_follow} in conversation_scoped

    assert {:ok, member_scoped} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.ConversationFollow,
                 %{member_id: "person-1"}
               )
             )

    assert {:member_conversation_follows, "person-1"} in member_scoped

    assert {:ok, [{:fallback, :conversation_follow}]} =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.ConversationFollow, %{})
             )
  end

  test "classifies both delivery contributors with exact message and delivery scope" do
    source = MembaReadModelSource.new()

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      event = %EmailDeliveryDelivered{
        message_id: "message-1",
        delivery_id: "delivery-1"
      }

      assert {:ok, invalidations} =
               Source.classify(source, notification(projector, event))

      assert {:message_deliveries, "message-1"} in invalidations
      assert {:delivery, "delivery-1"} in invalidations
    end
  end

  test "recovers delivery message scope from committed changes and projection rows" do
    source = MembaReadModelSource.new()
    delivery_id = Memba.ID.generate(:delivery)
    message_id = Memba.ID.generate(:message)

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      assert {:ok, changes_invalidations} =
               Source.classify(
                 source,
                 notification(
                   projector,
                   %{delivery_id: delivery_id},
                   %{
                     messaging_member_email_delivery: %{
                       delivery_id: delivery_id,
                       message_id: message_id
                     }
                   }
                 )
               )

      assert {:message_deliveries, message_id} in changes_invalidations
      assert {:delivery, delivery_id} in changes_invalidations
    end

    Repo.insert!(%MemberEmailDelivery{
      delivery_id: delivery_id,
      message_id: message_id,
      recipient_id: Memba.ID.generate(:person),
      recipient_name: "Alice",
      status: "sent"
    })

    assert {:ok, row_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.MembaStaffEmailDelivery,
                 %{delivery_id: delivery_id}
               )
             )

    assert {:message_deliveries, message_id} in row_invalidations
    assert {:delivery, delivery_id} in row_invalidations

    staff_delivery_id = Memba.ID.generate(:delivery)
    staff_message_id = Memba.ID.generate(:message)

    Repo.insert!(%MembaStaffEmailDelivery{
      delivery_id: staff_delivery_id,
      message_id: staff_message_id,
      recipient_id: Memba.ID.generate(:person),
      recipient_name: "Bob",
      recipient_address: "bob@example.com",
      channel: "email",
      status: "delayed",
      reason: "Retrying"
    })

    assert {:ok, staff_row_invalidations} =
             Source.classify(
               source,
               notification(
                 Memba.Messaging.Projectors.MemberEmailDelivery,
                 %{delivery_id: staff_delivery_id}
               )
             )

    assert {:message_deliveries, staff_message_id} in staff_row_invalidations
    assert {:delivery, staff_delivery_id} in staff_row_invalidations
  end

  test "retains exact delivery identity alongside fallback when message scope is unavailable" do
    source = MembaReadModelSource.new()

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      assert {:ok, invalidations} =
               Source.classify(
                 source,
                 notification(
                   projector,
                   %{delivery_id: Memba.ID.generate(:delivery)}
                 )
               )

      assert Enum.any?(invalidations, &match?({:delivery, _delivery_id}, &1))
      assert {:fallback, :delivery} in invalidations
    end
  end

  test "covers every Club projector event family including group and role compatibility events" do
    assert_family_invalidations(
      Memba.Membership.Projectors.Club,
      [
        %ClubCreated{club_id: "club-1", name: "Club", slug: "club"},
        %ClubUpdated{club_id: "club-1", name: "Updated Club", slug: "updated-club"}
      ],
      [{:club, "club-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Club,
      [
        %GroupCreated{
          club_id: "club-1",
          group_id: "group-1",
          group_key: "group-1",
          name: "Group"
        },
        %GroupEmailSlugAssigned{
          club_id: "club-1",
          group_id: "group-1",
          email_slug: "group"
        }
      ],
      [{:club_groups, "club-1"}, {:group, "group-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Club,
      [
        %ClubRoleDefined{
          club_id: "club-1",
          role_id: "role-1",
          role_key: "admin",
          name: "Admin"
        }
      ],
      [{:role, "role-1"}, {:club_roles, "club-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Club,
      [
        %ClubRolePermissionGranted{
          club_id: "club-1",
          role_id: "role-1",
          permission: "club.manage_members"
        }
      ],
      [{:role, "role-1"}, {:club_permissions, "club-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Club,
      exact_role_events(),
      [
        {:member_roles, "club-1", "membership-1", "person-1"},
        {:member_permissions, "club-1", "membership-1", "person-1"},
        {:role, "role-1"}
      ]
    )
  end

  test "covers current and legacy Membership entry and exit with symmetric exact scope" do
    assert_family_invalidations(
      Memba.Membership.Projectors.Membership,
      [
        %ClubMemberAdded{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        },
        %ClubMemberRemoved{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        },
        %MemberAdded{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        },
        %MemberRemoved{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        }
      ],
      [
        {:club_members, "club-1"},
        {:membership, "membership-1"},
        {:person, "person-1"},
        {:person_clubs, "person-1"}
      ]
    )
  end

  test "recovers legacy membership-removal scope from committed changes and the membership row" do
    changes_event = %MemberRemoved{
      membership_id: "membership-from-changes",
      club_id: nil,
      person_id: nil
    }

    assert_invalidations(
      Memba.Membership.Projectors.Membership,
      changes_event,
      [
        {:club_members, "club-from-changes"},
        {:membership, "membership-from-changes"},
        {:person, "person-from-changes"},
        {:person_clubs, "person-from-changes"}
      ],
      %{
        membership_scope: %{
          club_id: "club-from-changes",
          person_id: "person-from-changes"
        }
      }
    )

    assert_invalidations(
      Memba.Membership.Projectors.Role,
      changes_event,
      [
        {:member_roles, "club-from-changes", "membership-from-changes", "person-from-changes"},
        {:member_permissions, "club-from-changes", "membership-from-changes",
         "person-from-changes"},
        {:club_permissions, "club-from-changes"}
      ],
      %{
        membership_scope: %{
          club_id: "club-from-changes",
          person_id: "person-from-changes"
        }
      }
    )

    membership_id = Memba.ID.generate(:membership)
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)

    Repo.insert!(%MembershipProjection{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id,
      active: false
    })

    row_event = %MemberRemoved{
      membership_id: membership_id,
      club_id: nil,
      person_id: nil
    }

    expected = [
      {:club_members, club_id},
      {:membership, membership_id},
      {:person, person_id},
      {:person_clubs, person_id}
    ]

    assert_invalidations(Memba.Membership.Projectors.Membership, row_event, expected)

    assert_invalidations(
      Memba.Membership.Projectors.Role,
      row_event,
      [
        {:member_roles, club_id, membership_id, person_id},
        {:member_permissions, club_id, membership_id, person_id},
        {:club_permissions, club_id}
      ]
    )
  end

  test "covers every Person projector event family with exact Person and email scope" do
    events = [
      %PersonCreated{
        person_id: "person-1",
        name: "Alice",
        email: "alice@example.com"
      },
      %PersonEmailAddressAdded{
        person_id: "person-1",
        email: "alice+new@example.com",
        normalized_email: "alice+new@example.com"
      },
      %PersonEmailAddressVerified{
        person_id: "person-1",
        email: "alice+new@example.com",
        normalized_email: "alice+new@example.com",
        verified_at: DateTime.utc_now()
      },
      %PersonEmailAddressesReplaced{
        person_id: "person-1",
        email_addresses: [],
        primary_email: "alice@example.com"
      },
      %PersonPrimaryEmailAddressChanged{
        person_id: "person-1",
        primary_email: "alice+new@example.com",
        normalized_email: "alice+new@example.com"
      },
      %PersonEmailAddressRemoved{
        person_id: "person-1",
        email: "alice+old@example.com",
        normalized_email: "alice+old@example.com"
      }
    ]

    assert_family_invalidations(
      Memba.Membership.Projectors.Person,
      events,
      [{:person, "person-1"}, {:person_emails, "person-1"}]
    )
  end

  test "covers Group and GroupMembership entry and exit event families" do
    assert_family_invalidations(
      Memba.Membership.Projectors.Group,
      [
        %GroupCreated{
          club_id: "club-1",
          group_id: "group-1",
          group_key: "group-1",
          name: "Group"
        },
        %GroupEmailSlugAssigned{
          club_id: "club-1",
          group_id: "group-1",
          email_slug: "group"
        }
      ],
      [{:club_groups, "club-1"}, {:group, "group-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.GroupMembership,
      [
        %GroupMemberAdded{
          club_id: "club-1",
          group_id: "group-1",
          membership_id: "membership-1",
          person_id: "person-1"
        },
        %GroupMemberRemoved{
          club_id: "club-1",
          group_id: "group-1",
          membership_id: "membership-1",
          person_id: "person-1"
        }
      ],
      [
        {:group_members, "group-1"},
        {:person, "person-1"},
        {:person_groups, "club-1", "person-1"},
        {:group_participation, "club-1", "group-1", "person-1"}
      ]
    )
  end

  test "covers all Role projector definition, permission, assignment and removal families" do
    assert_family_invalidations(
      Memba.Membership.Projectors.Role,
      [
        %ClubRoleDefined{
          club_id: "club-1",
          role_id: "role-1",
          role_key: "admin",
          name: "Admin"
        }
      ],
      [{:role, "role-1"}, {:club_roles, "club-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Role,
      [
        %ClubRolePermissionGranted{
          club_id: "club-1",
          role_id: "role-1",
          permission: "club.manage_members"
        }
      ],
      [{:role, "role-1"}, {:club_permissions, "club-1"}]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Role,
      exact_role_events(),
      [
        {:member_roles, "club-1", "membership-1", "person-1"},
        {:member_permissions, "club-1", "membership-1", "person-1"},
        {:role, "role-1"}
      ]
    )

    assert_family_invalidations(
      Memba.Membership.Projectors.Role,
      [
        %ClubMemberRemoved{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        },
        %MemberRemoved{
          club_id: "club-1",
          membership_id: "membership-1",
          person_id: "person-1"
        }
      ],
      [
        {:member_roles, "club-1", "membership-1", "person-1"},
        {:member_permissions, "club-1", "membership-1", "person-1"},
        {:club_permissions, "club-1"}
      ]
    )
  end

  test "covers root and reply Message events with exact and club collection scope" do
    root = %MessageSent{
      message_id: "message-1",
      club_id: "club-1",
      sender_id: "person-1",
      conversation_id: nil,
      reply_to_message_id: nil,
      subject: "Plans",
      body: "Meet at eight"
    }

    reply = %MessageSent{
      message_id: "message-2",
      club_id: "club-1",
      sender_id: "person-1",
      conversation_id: "message-1",
      reply_to_message_id: "message-1",
      subject: "Re: Plans",
      body: "Count me in"
    }

    assert_invalidations(
      Memba.Messaging.Projectors.Message,
      root,
      [
        {:message, "message-1"},
        {:conversation, "message-1"},
        {:conversation_messages, "message-1"},
        {:club_conversations, "club-1"}
      ]
    )

    assert_invalidations(
      Memba.Messaging.Projectors.Message,
      reply,
      [
        {:message, "message-2"},
        {:conversation, "message-1"},
        {:conversation_messages, "message-1"},
        {:club_conversations, "club-1"}
      ]
    )
  end

  test "covers conversation access grant and revoke with exact collection and identities" do
    events = [
      %ConversationAccessGrantedToGroup{
        club_id: "club-1",
        group_id: "group-1",
        conversation_id: "conversation-1",
        access_level: "write"
      },
      %ConversationAccessRevokedFromGroup{
        club_id: "club-1",
        group_id: "group-1",
        conversation_id: "conversation-1",
        access_level: "write"
      }
    ]

    assert_family_invalidations(
      Memba.Messaging.Projectors.ConversationGroupAccess,
      events,
      [
        {:group_conversations, "group-1"},
        {:conversation_access, "group-1", "conversation-1"},
        {:conversation, "conversation-1"},
        {:group, "group-1"}
      ]
    )
  end

  test "covers explicit and automatic conversation-follow families with conversation identity" do
    assert_family_invalidations(
      Memba.Messaging.Projectors.ConversationFollow,
      [
        %ConversationFollowed{
          follow_id: "follow-1",
          club_id: "club-1",
          conversation_id: "conversation-1",
          member_id: "person-1"
        },
        %ConversationUnfollowed{
          follow_id: "follow-1",
          club_id: "club-1",
          conversation_id: "conversation-1",
          member_id: "person-1"
        }
      ],
      [
        {:conversation_follow, "conversation-1", "person-1"},
        {:conversation, "conversation-1"}
      ]
    )

    assert_invalidations(
      Memba.Messaging.Projectors.ConversationFollow,
      %MessageSent{
        message_id: "conversation-1",
        club_id: "club-1",
        sender_id: "person-1",
        conversation_id: nil,
        reply_to_message_id: nil,
        subject: "Plans",
        body: "Meet at eight"
      },
      [
        {:conversation_follow, "conversation-1", "person-1"},
        {:conversation, "conversation-1"}
      ]
    )
  end

  test "covers every delivery event family identically for both independent projectors" do
    events = [
      %EmailDeliveryCreated{
        message_id: "message-1",
        delivery_id: "delivery-1",
        recipient_id: "person-1",
        recipient_name: "Alice",
        recipient_email: "alice@example.com"
      },
      %EmailDeliveryDelivered{message_id: "message-1", delivery_id: "delivery-1"},
      %EmailDeliveryDelayed{
        message_id: "message-1",
        delivery_id: "delivery-1",
        reason: "Retrying"
      },
      %EmailDeliveryBounced{
        message_id: "message-1",
        delivery_id: "delivery-1",
        reason: "Mailbox unavailable"
      },
      %EmailDeliverySpamComplaint{
        message_id: "message-1",
        delivery_id: "delivery-1",
        reason: "Complaint"
      },
      %EmailDeliveryOpened{message_id: "message-1", delivery_id: "delivery-1"}
    ]

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      assert_family_invalidations(
        projector,
        events,
        [{:message_deliveries, "message-1"}, {:delivery, "delivery-1"}]
      )
    end
  end

  test "retains useful partial scope and adds matrix fallbacks for missing scope" do
    assert_invalidations(
      Memba.Membership.Projectors.Group,
      %{group_id: "group-1"},
      [{:group, "group-1"}, {:fallback, :group}]
    )

    assert_invalidations(
      Memba.Membership.Projectors.Membership,
      %{club_id: "club-1", membership_id: "membership-1"},
      [
        {:club_members, "club-1"},
        {:membership, "membership-1"},
        {:fallback, :membership}
      ]
    )

    assert_invalidations(
      Memba.Messaging.Projectors.Message,
      %{club_id: "club-1"},
      [{:club_conversations, "club-1"}, {:fallback, :message, "club-1"}]
    )

    assert_invalidations(
      Memba.Messaging.Projectors.ConversationGroupAccess,
      %{conversation_id: "conversation-1"},
      [{:conversation, "conversation-1"}, {:fallback, :conversation_access}]
    )
  end

  test "uses exact tuple equality across every scoped identity and ignores unrelated input" do
    source = MembaReadModelSource.new()

    for {left, right} <- [
          {{:club, "club-1"}, {:club, "club-2"}},
          {{:group, "group-1"}, {:group, "group-2"}},
          {{:conversation, "conversation-1"}, {:conversation, "conversation-2"}},
          {{:person, "person-1"}, {:person, "person-2"}},
          {{:message, "message-1"}, {:message, "message-2"}},
          {{:delivery, "delivery-1"}, {:delivery, "delivery-2"}}
        ] do
      assert Source.matches?(source, left, left)
      refute Source.matches?(source, left, right)
    end

    assert :ignore =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.EmailDelivery, %{
                 message_id: "message-1",
                 delivery_id: "delivery-1"
               })
             )

    assert :ignore = Source.classify(source, {:read_model_changed, %{}})
    assert :ignore = Source.classify(source, {:read_model_changed, "malformed"})
    assert :ignore = Source.classify(source, :unrelated)
  end

  defp exact_role_events do
    [
      %ClubRoleAssignedToMember{
        club_id: "club-1",
        membership_id: "membership-1",
        person_id: "person-1",
        role_id: "role-1"
      },
      %ClubRoleRemovedFromMember{
        club_id: "club-1",
        membership_id: "membership-1",
        person_id: "person-1",
        role_id: "role-1"
      },
      %MemberRoleAssigned{
        club_id: "club-1",
        membership_id: "membership-1",
        person_id: "person-1",
        role_id: "role-1"
      },
      %MemberRoleRemoved{
        club_id: "club-1",
        membership_id: "membership-1",
        person_id: "person-1",
        role_id: "role-1"
      }
    ]
  end

  defp assert_family_invalidations(projector, events, expected) do
    Enum.each(events, &assert_invalidations(projector, &1, expected))
  end

  defp assert_invalidations(projector, event, expected, changes \\ %{}) do
    source = MembaReadModelSource.new()

    assert {:ok, actual} =
             Source.classify(source, notification(projector, event, changes))

    assert MapSet.new(actual) == MapSet.new(expected)
  end

  defp notification(projector, source_event, changes \\ %{}) do
    {:read_model_changed,
     %{
       projector: projector,
       source_event: source_event,
       metadata: %{},
       changes: changes
     }}
  end
end
