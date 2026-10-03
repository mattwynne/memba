defmodule MembaWeb.LiveQuery.MembaReadModelSourceTest do
  use MembaWeb.ConnCase, async: true

  alias LiveQuery.Binding
  alias LiveQuery.Query
  alias LiveQuery.Source

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
  alias Memba.Repo
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.LiveQuery.ReadModelContractViolationError

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

  test "classifies club-member collection entry, relationship, and authority scopes" do
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
    assert {:person_clubs, "person-1"} in invalidations
  end

  test "surfaces malformed Membership events without emitting fallback invalidations" do
    assert_contract_violation(
      Memba.Membership.Projectors.Membership,
      malformed_membership_event(),
      {:missing_required_fields, [:person_id]}
    )
  end

  test "raises the application contract exception through ordinary binding handling" do
    source = MembaReadModelSource.new()
    query = contract_probe_query(fn -> :ok end)

    assert {:ok, socket} = Binding.bind(socket(true), query, :current, source)

    exception =
      assert_raise ReadModelContractViolationError, fn ->
        Binding.handle_notification(socket, malformed_membership_notification())
      end

    assert_contract_exception(exception)
  end

  test "raises the application contract exception during bind-window reconciliation" do
    source = MembaReadModelSource.new()

    query =
      contract_probe_query(fn ->
        send(self(), malformed_membership_notification())
      end)

    exception =
      assert_raise ReadModelContractViolationError, fn ->
        Binding.bind(socket(true), query, :current, source)
      end

    assert_contract_exception(exception)
  end

  test "matches Person changes only to the represented Person" do
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

  test "does not reread a conversation for another member's follow change" do
    {socket, reads} =
      bind_counting_query([
        {:conversation, "conversation-1"},
        {:conversation_follow, "conversation-1", "person-1"}
      ])

    unrelated =
      notification(
        Memba.Messaging.Projectors.ConversationFollow,
        %ConversationFollowed{
          follow_id: "follow-2",
          club_id: "club-1",
          conversation_id: "conversation-1",
          member_id: "person-2"
        }
      )

    assert {:ignored, socket} = Binding.handle_notification(socket, unrelated)
    assert_read_count(reads, 1)

    relevant =
      notification(
        Memba.Messaging.Projectors.ConversationFollow,
        %ConversationFollowed{
          follow_id: "follow-1",
          club_id: "club-1",
          conversation_id: "conversation-1",
          member_id: "person-1"
        }
      )

    assert {:ok, _socket} = Binding.handle_notification(socket, relevant)
    assert_read_count(reads, 2)
  end

  test "does not reread a represented Person for another club's Membership change" do
    {socket, reads} =
      bind_counting_query([
        {:person, "person-1"},
        {:club_members, "club-1"}
      ])

    unrelated =
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberAdded{
          club_id: "club-2",
          membership_id: "membership-2",
          person_id: "person-1"
        }
      )

    assert {:ignored, socket} = Binding.handle_notification(socket, unrelated)
    assert_read_count(reads, 1)

    relevant =
      notification(
        Memba.Membership.Projectors.Membership,
        %ClubMemberAdded{
          club_id: "club-1",
          membership_id: "membership-3",
          person_id: "person-3"
        }
      )

    assert {:ok, _socket} = Binding.handle_notification(socket, relevant)
    assert_read_count(reads, 2)
  end

  test "does not reread a represented Person for another club's GroupMembership change" do
    {socket, reads} =
      bind_counting_query([
        {:person, "person-1"},
        {:group_members, "group-1"},
        {:person_groups, "club-1", "person-1"},
        {:group_participation, "club-1", "group-1", "person-1"}
      ])

    unrelated =
      notification(
        Memba.Membership.Projectors.GroupMembership,
        %GroupMemberAdded{
          club_id: "club-2",
          group_id: "group-2",
          membership_id: "membership-2",
          person_id: "person-1"
        }
      )

    assert {:ignored, socket} = Binding.handle_notification(socket, unrelated)
    assert_read_count(reads, 1)

    relevant =
      notification(
        Memba.Membership.Projectors.GroupMembership,
        %GroupMemberAdded{
          club_id: "club-1",
          group_id: "group-1",
          membership_id: "membership-1",
          person_id: "person-1"
        }
      )

    assert {:ok, _socket} = Binding.handle_notification(socket, relevant)
    assert_read_count(reads, 2)
  end

  test "does not reread for access on an unselected represented group" do
    {socket, reads} =
      bind_counting_query([
        {:group, "group-unselected"},
        {:conversation, "conversation-selected"},
        {:conversation_access, "group-selected", "conversation-selected"}
      ])

    unrelated =
      notification(
        Memba.Messaging.Projectors.ConversationGroupAccess,
        %ConversationAccessGrantedToGroup{
          club_id: "club-1",
          group_id: "group-unselected",
          conversation_id: "conversation-other",
          access_level: "write"
        }
      )

    assert {:ignored, socket} = Binding.handle_notification(socket, unrelated)
    assert_read_count(reads, 1)

    conversation_wide =
      notification(
        Memba.Messaging.Projectors.ConversationGroupAccess,
        %ConversationAccessGrantedToGroup{
          club_id: "club-1",
          group_id: "group-unselected",
          conversation_id: "conversation-selected",
          access_level: "write"
        }
      )

    assert {:ok, _socket} = Binding.handle_notification(socket, conversation_wide)
    assert_read_count(reads, 2)
  end

  test "ignores MessageSent when the conversation-follow projector made no change" do
    source = MembaReadModelSource.new()

    event = %MessageSent{
      message_id: "conversation-2",
      club_id: "club-1",
      sender_id: "person-2",
      conversation_id: nil,
      reply_to_message_id: nil,
      subject: "Plans",
      body: "Meet at eight",
      sender_follows_conversation: false
    }

    assert :ignore =
             Source.classify(
               source,
               notification(Memba.Messaging.Projectors.ConversationFollow, event)
             )
  end

  test "surfaces malformed no-op MessageSent events before ignoring follow invalidation" do
    complete_event = %MessageSent{
      message_id: "conversation-2",
      club_id: "club-1",
      sender_id: "person-2",
      conversation_id: nil,
      reply_to_message_id: nil,
      subject: "Plans",
      body: "Meet at eight",
      sender_follows_conversation: false
    }

    for missing_field <- [:club_id, :message_id, :sender_id] do
      assert_contract_violation(
        Memba.Messaging.Projectors.ConversationFollow,
        Map.put(complete_event, missing_field, nil),
        {:missing_required_fields, [missing_field]}
      )
    end
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
        {:person_clubs, "person-1"}
      ]
    )
  end

  test "recovers genuine legacy MemberRemoved scope from the retained membership row" do
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

  test "surfaces unrecoverable legacy MemberRemoved scope for both publishing projectors" do
    membership_id = Memba.ID.generate(:membership)

    event = %MemberRemoved{
      membership_id: membership_id,
      club_id: nil,
      person_id: nil
    }

    for projector <- [
          Memba.Membership.Projectors.Membership,
          Memba.Membership.Projectors.Role
        ] do
      assert_contract_violation(
        projector,
        event,
        {:missing_required_fields, [:club_id, :person_id]},
        %{
          synthetic_membership_scope: %{
            club_id: "club-from-changes",
            person_id: "person-from-changes"
          }
        }
      )
    end
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
        {:conversation, "conversation-1"}
      ]
    )
  end

  test "covers explicit and automatic conversation-follow families with exact relationship scope" do
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
      [{:conversation_follow, "conversation-1", "person-1"}]
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
      [{:conversation_follow, "conversation-1", "person-1"}]
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
        body: "Meet at eight",
        sender_follows_conversation: true
      },
      [{:conversation_follow, "conversation-1", "person-1"}]
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
      }
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

  test "ignores replay-only EmailDeliveryOpened for both delivery projectors" do
    event = %EmailDeliveryOpened{message_id: "message-1", delivery_id: "delivery-1"}

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      assert :ignore =
               projector
               |> notification(event)
               |> then(&Source.classify(MembaReadModelSource.new(), &1))
    end
  end

  test "surfaces malformed replay-only EmailDeliveryOpened for both delivery projectors" do
    delivery_id = Memba.ID.generate(:delivery)
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%MemberEmailDelivery{
      delivery_id: delivery_id,
      message_id: message_id,
      recipient_id: Memba.ID.generate(:person),
      recipient_name: "Alice",
      status: "sent"
    })

    complete_event = %EmailDeliveryOpened{
      message_id: message_id,
      delivery_id: delivery_id
    }

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ],
        missing_field <- [:message_id, :delivery_id] do
      assert_contract_violation(
        projector,
        Map.put(complete_event, missing_field, nil),
        {:missing_required_fields, [missing_field]},
        %{delivery: %{delivery_id: delivery_id, message_id: message_id}}
      )
    end
  end

  test "does not recover malformed delivery events from committed changes or projection rows" do
    delivery_id = Memba.ID.generate(:delivery)
    message_id = Memba.ID.generate(:message)

    Repo.insert!(%MemberEmailDelivery{
      delivery_id: delivery_id,
      message_id: message_id,
      recipient_id: Memba.ID.generate(:person),
      recipient_name: "Alice",
      status: "sent"
    })

    malformed_event = %EmailDeliveryDelivered{
      message_id: nil,
      delivery_id: delivery_id
    }

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      assert_contract_violation(
        projector,
        malformed_event,
        {:missing_required_fields, [:message_id]},
        %{delivery: %{delivery_id: delivery_id, message_id: message_id}}
      )
    end
  end

  test "surfaces unsupported pairings and missing required identities without fallbacks" do
    assert_contract_violation(
      Memba.Membership.Projectors.Club,
      %ClubUpdated{club_id: nil, name: "Updated", slug: "updated"},
      {:missing_required_fields, [:club_id]}
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Club,
      %ClubMemberRemoved{
        club_id: "club-1",
        membership_id: "membership-1",
        person_id: "person-1"
      },
      :unsupported_projector_event
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Club,
      %MemberRemoved{
        membership_id: "membership-1",
        club_id: "club-1",
        person_id: "person-1"
      },
      :unsupported_projector_event
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Club,
      %PersonCreated{
        person_id: "person-1",
        name: "Alice",
        email: "alice@example.com"
      },
      :unsupported_projector_event
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Person,
      %PersonCreated{
        person_id: nil,
        name: "Alice",
        email: "alice@example.com"
      },
      {:missing_required_fields, [:person_id]}
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Group,
      %GroupCreated{
        club_id: nil,
        group_id: "group-1",
        group_key: "group-1",
        name: "Group"
      },
      {:missing_required_fields, [:club_id]}
    )

    assert_contract_violation(
      Memba.Membership.Projectors.GroupMembership,
      %GroupMemberAdded{
        club_id: "club-1",
        group_id: "group-1",
        membership_id: "membership-1",
        person_id: nil
      },
      {:missing_required_fields, [:person_id]}
    )

    assert_contract_violation(
      Memba.Membership.Projectors.Role,
      %ClubRoleDefined{
        club_id: "club-1",
        role_id: nil,
        role_key: "admin",
        name: "Admin"
      },
      {:missing_required_fields, [:role_id]}
    )

    assert_contract_violation(
      Memba.Messaging.Projectors.ConversationGroupAccess,
      %ConversationAccessGrantedToGroup{
        club_id: "club-1",
        group_id: nil,
        conversation_id: "conversation-1",
        access_level: "write"
      },
      {:missing_required_fields, [:group_id]}
    )

    assert_contract_violation(
      Memba.Messaging.Projectors.ConversationFollow,
      %ConversationFollowed{
        follow_id: "follow-1",
        club_id: "club-1",
        conversation_id: "conversation-1",
        member_id: nil
      },
      {:missing_required_fields, [:member_id]}
    )

    assert_contract_violation(
      Memba.Messaging.Projectors.Message,
      %MessageSent{
        message_id: "message-1",
        club_id: nil,
        sender_id: "person-1",
        conversation_id: nil,
        reply_to_message_id: nil,
        subject: "Plans",
        body: "Meet at eight"
      },
      {:missing_required_fields, [:club_id]}
    )

    assert_contract_violation(
      Memba.Messaging.Projectors.MemberEmailDelivery,
      %MessageSent{
        message_id: "message-1",
        club_id: "club-1",
        sender_id: "person-1",
        conversation_id: nil,
        reply_to_message_id: nil,
        subject: "Plans",
        body: "Meet at eight"
      },
      :unsupported_projector_event
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

    exception =
      assert_raise ReadModelContractViolationError, fn ->
        Source.classify(
          source,
          notification(Memba.Membership.Projectors.Person, %{person_id: "person-1"})
        )
      end

    assert exception.projector == Memba.Membership.Projectors.Person
    assert exception.source_event == :unstructured
    assert exception.reason == :unsupported_projector_event

    assert :ignore = Source.classify(source, {:read_model_changed, %{}})
    assert :ignore = Source.classify(source, {:read_model_changed, "malformed"})
    assert :ignore = Source.classify(source, :unrelated)
  end

  test "ignores incomplete or mistyped outer envelopes before recognized-projector dispatch" do
    source = MembaReadModelSource.new()

    {:read_model_changed, envelope} =
      notification(
        Memba.Membership.Projectors.Person,
        %ClubUpdated{club_id: "club-1", name: "Updated", slug: "updated"}
      )

    for malformed_envelope <- [
          Map.delete(envelope, :metadata),
          Map.delete(envelope, :changes),
          %{envelope | metadata: :not_a_map},
          %{envelope | changes: :not_a_map}
        ] do
      assert :ignore = Source.classify(source, {:read_model_changed, malformed_envelope})
    end
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

  defp assert_contract_violation(projector, event, reason, changes \\ %{}) do
    event_module = event.__struct__

    exception =
      assert_raise ReadModelContractViolationError, fn ->
        Source.classify(
          MembaReadModelSource.new(),
          notification(projector, event, changes)
        )
      end

    assert exception.projector == projector
    assert exception.source_event == event_module
    assert exception.reason == reason

    assert Exception.message(exception) ==
             contract_exception_message(projector, event_module, reason)
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

  defp malformed_membership_event do
    %ClubMemberAdded{
      club_id: "club-1",
      membership_id: "membership-1",
      person_id: nil
    }
  end

  defp malformed_membership_notification do
    notification(
      Memba.Membership.Projectors.Membership,
      malformed_membership_event()
    )
  end

  defp contract_probe_query(before_result) do
    Query.new!(
      id: :contract_probe,
      assign: :contract_probe,
      load: fn :current ->
        before_result.()
        {:ok, :loaded, [{:club_members, "club-1"}]}
      end
    )
  end

  defp bind_counting_query(interests) do
    child_spec = Supervisor.child_spec({Agent, fn -> 0 end}, id: make_ref())
    reads = start_supervised!(child_spec)

    query =
      Query.new!(
        id: make_ref(),
        assign: :counting_probe,
        load: fn :current ->
          read_count = Agent.get_and_update(reads, fn count -> {count + 1, count + 1} end)
          {:ok, read_count, interests}
        end
      )

    assert {:ok, socket} =
             Binding.bind(socket(true), query, :current, MembaReadModelSource.new())

    assert_read_count(reads, 1)
    {socket, reads}
  end

  defp assert_read_count(reads, expected) do
    assert Agent.get(reads, & &1) == expected
  end

  defp assert_contract_exception(exception) do
    assert exception.projector == Memba.Membership.Projectors.Membership
    assert exception.source_event == ClubMemberAdded
    assert exception.reason == {:missing_required_fields, [:person_id]}

    assert Exception.message(exception) ==
             contract_exception_message(
               Memba.Membership.Projectors.Membership,
               ClubMemberAdded,
               {:missing_required_fields, [:person_id]}
             )
  end

  defp contract_exception_message(projector, source_event, reason) do
    "read-model contract violation for projector #{inspect(projector)}, " <>
      "source event #{inspect(source_event)}: #{inspect(reason)}"
  end

  defp socket(connected?) do
    %Phoenix.LiveView.Socket{
      transport_pid: if(connected?, do: self()),
      assigns: %{__changed__: %{}}
    }
  end
end
