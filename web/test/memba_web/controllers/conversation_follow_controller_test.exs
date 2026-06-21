defmodule MembaWeb.ConversationFollowControllerTest do
  use MembaWeb.ConnCase, async: false

  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Messaging
  alias Memba.Messaging.ConversationStopFollowToken

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    :ok
  end

  test "a valid stop-follow link unfollows the intended recipient and halts future reply email",
       %{conn: conn} do
    club = create_club!()
    alice = create_person!(name: "Alice Sender", email: "alice@example.com")
    bob = create_person!(name: "Bob Replier", email: "bob@example.com")

    add_member!(club.club_id, alice.person_id)
    add_member!(club.club_id, bob.person_id)

    conversation_id = send_root_message!(club.club_id, alice.person_id)
    assert Messaging.following_conversation?(conversation_id, alice.person_id)

    token = stop_follow_token!(club.club_id, conversation_id, alice.person_id)

    conn = get(conn, ~p"/messages/conversations/stop-following/#{token}")

    assert html_response(conn, 200) =~ "You’ve stopped following this conversation"
    refute Messaging.following_conversation?(conversation_id, alice.person_id)

    reuse_conn = get(build_conn(), ~p"/messages/conversations/stop-following/#{token}")
    assert html_response(reuse_conn, 200) =~ "You’ve stopped following this conversation"
    refute Messaging.following_conversation?(conversation_id, alice.person_id)

    reply_message_id = post_reply!(conversation_id, bob.person_id)
    assert Messaging.list_recipient_deliveries(reply_message_id) == []
  end

  test "an invalid stop-follow link changes nothing and shows a generic failure", %{conn: conn} do
    club = create_club!()
    alice = create_person!(name: "Alice Sender", email: "alice@example.com")

    add_member!(club.club_id, alice.person_id)

    conversation_id = send_root_message!(club.club_id, alice.person_id)
    token = stop_follow_token!(club.club_id, conversation_id, alice.person_id)

    conn = get(conn, ~p"/messages/conversations/stop-following/#{token <> "tampered"}")

    assert html_response(conn, 422) =~ "This stop-follow link isn’t valid"
    refute html_response(conn, 422) =~ club.name
    assert Messaging.following_conversation?(conversation_id, alice.person_id)
  end

  test "a valid token with the wrong club scope changes nothing", %{conn: conn} do
    club = create_club!()
    other_club_id = Memba.ID.generate(:club)
    alice = create_person!(name: "Alice Sender", email: "alice@example.com")

    add_member!(club.club_id, alice.person_id)

    conversation_id = send_root_message!(club.club_id, alice.person_id)
    token = stop_follow_token!(other_club_id, conversation_id, alice.person_id)

    conn = get(conn, ~p"/messages/conversations/stop-following/#{token}")

    assert html_response(conn, 422) =~ "This stop-follow link isn’t valid"
    assert Messaging.following_conversation?(conversation_id, alice.person_id)
  end

  defp create_club!(attrs \\ []) do
    club_id = Keyword.get_lazy(attrs, :club_id, fn -> Memba.ID.generate(:club) end)
    name = Keyword.get(attrs, :name, "Kootenay Mountaineering Club")
    slug = Keyword.get(attrs, :slug, "kmc")

    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{club_id: club_id, name: name, slug: slug},
               consistency: :strong
             )

    Memba.Membership.get_club(club_id)
  end

  defp create_person!(attrs) do
    person = %{
      person_id: Memba.ID.generate(:person),
      name: Keyword.fetch!(attrs, :name),
      email: Keyword.fetch!(attrs, :email)
    }

    assert :ok =
             MembershipApp.dispatch(
               %CreatePerson{
                 person_id: person.person_id,
                 name: person.name,
                 email: person.email
               },
               consistency: :strong
             )

    person
  end

  defp add_member!(club_id, person_id) do
    assert :ok =
             MembershipApp.dispatch(
               %AddMember{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )
  end

  defp send_root_message!(club_id, sender_id) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas."
               },
               consistency: :strong
             )

    message_id
  end

  defp post_reply!(conversation_id, sender_id) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: message_id,
                 conversation_id: conversation_id,
                 sender_id: sender_id,
                 body: "I can bring maps."
               },
               consistency: :strong
             )

    message_id
  end

  defp stop_follow_token!(club_id, conversation_id, member_id) do
    assert {:ok, token} =
             ConversationStopFollowToken.sign(%{
               club_id: club_id,
               conversation_id: conversation_id,
               member_id: member_id
             })

    token
  end
end
