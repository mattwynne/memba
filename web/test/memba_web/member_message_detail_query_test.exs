defmodule MembaWeb.MemberMessageDetailQueryTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias LiveQuery.Query
  alias MembaWeb.MemberMessageDetailQuery

  test "describes one coherent message-detail result assign" do
    query = MemberMessageDetailQuery.query()

    assert query.id == :member_message_detail
    assert query.assign == :message_detail
    assert is_function(query.load, 1)
  end

  test "derives collection, represented identity, follow, delivery and authority interests" do
    detail = %{
      selected_club: %{club_id: "club-1"},
      current_member: %{
        id: "person-current",
        membership_id: "membership-current"
      },
      conversation_audience: %{
        conversation_id: "message-root",
        group_id: "group-1"
      },
      message: %{
        message_id: "message-root",
        conversation_id: "message-root",
        sender_id: "person-author-1"
      },
      conversation_entries: [
        %{
          message: %{
            message_id: "message-root",
            conversation_id: "message-root",
            sender_id: "person-author-1"
          }
        },
        %{
          message: %{
            message_id: "message-reply",
            conversation_id: "message-root",
            sender_id: "person-author-2"
          }
        }
      ],
      member_email_deliverys: [
        %{delivery_id: "delivery-1"},
        %{delivery_id: "delivery-2"}
      ],
      member_email_delivery_ids: ["delivery-1", "delivery-2"]
    }

    interests = MemberMessageDetailQuery.interests(detail)

    for interest <- [
          {:club, "club-1"},
          {:club_members, "club-1"},
          {:membership, "membership-current"},
          {:person, "person-current"},
          {:person_clubs, "person-current"},
          {:group_members, "group-1"},
          {:group_participation, "club-1", "group-1", "person-current"},
          {:conversation, "message-root"},
          {:conversation_messages, "message-root"},
          {:conversation_access, "group-1", "message-root"},
          {:message, "message-root"},
          {:message, "message-reply"},
          {:person, "person-author-1"},
          {:person, "person-author-2"},
          {:conversation_follow, "message-root", "person-current"},
          {:message_deliveries, "message-root"},
          {:delivery, "delivery-1"},
          {:delivery, "delivery-2"}
        ] do
      assert interest in interests
    end

    refute {:person, "person-not-represented"} in interests
    refute {:conversation_follows, "message-root"} in interests
    refute {:member_conversation_follows, "person-current"} in interests

    refute Enum.any?(interests, fn interest ->
             match?({:fallback, _family}, interest) or
               match?({:fallback, _family, _club_id}, interest)
           end)
  end

  test "descriptor returns complete replacement interests with each successful read" do
    query = MemberMessageDetailQuery.query()

    assert %Query{} = query
  end

  test "loads from normalized email and freshly resolved active-club authority" do
    alice = create_active_member("alice@example.com", "Alice Adams")
    bob = create_active_member("bob@example.com", "Bob Builder", alice.club_id)
    message = create_message(alice, "Fresh authority")

    assert {:ok, detail} =
             MemberMessageDetailQuery.load(
               alice.club_id,
               message.message_id,
               "  BOB@EXAMPLE.COM "
             )

    assert detail.current_member.id == bob.person_id

    assert :ok =
             Membership.remove_member(
               %{membership_id: bob.membership_id},
               consistency: :strong
             )

    assert {:error, :forbidden} =
             MemberMessageDetailQuery.load(
               alice.club_id,
               message.message_id,
               "bob@example.com"
             )
  end

  test "a new reply replaces interests with its newly represented author" do
    alice = create_active_member("alice@example.com", "Alice Adams")
    bob = create_active_member("bob@example.com", "Bob Builder", alice.club_id)
    carol = create_active_member("carol@example.com", "Carol Clark", alice.club_id)
    message = create_message(alice, "Replacement interests")

    assert {:ok, before_detail} =
             MemberMessageDetailQuery.load(
               alice.club_id,
               message.message_id,
               bob.email
             )

    before_interests = MemberMessageDetailQuery.interests(before_detail)
    refute {:person, carol.person_id} in before_interests

    assert :ok =
             Messaging.post_message_reply(
               %{
                 "message_id" => Memba.ID.generate(:message),
                 "conversation_id" => message.message_id,
                 "sender_id" => carol.person_id,
                 "body" => "I can bring the route notes."
               },
               consistency: :strong
             )

    assert {:ok, after_detail} =
             MemberMessageDetailQuery.load(
               alice.club_id,
               message.message_id,
               bob.email
             )

    after_interests = MemberMessageDetailQuery.interests(after_detail)
    assert {:person, carol.person_id} in after_interests
    assert length(after_detail.conversation_entries) == 2
  end

  defp create_active_member(email, name, club_id \\ Memba.ID.generate(:club)) do
    unless Membership.get_club(club_id) do
      assert :ok =
               Membership.create_club(
                 membership_club_attrs(
                   club_id: club_id,
                   name: "Alpine Club"
                 ),
                 consistency: :strong
               )
    end

    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    %{
      club_id: club_id,
      person_id: person_id,
      membership_id: membership_id,
      email: email
    }
  end

  defp create_message(member, subject) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message_as_current_member(
               %{
                 message_id: message_id,
                 club_id: member.club_id,
                 sender_id: member.person_id,
                 audience_group_id: SystemGroups.everyone_group_id(member.club_id),
                 subject: subject,
                 body: "Bring your maps."
               },
               consistency: :strong
             )

    Messaging.get_message(message_id)
  end
end
