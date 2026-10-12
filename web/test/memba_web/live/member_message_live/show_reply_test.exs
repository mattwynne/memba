defmodule MembaWeb.MemberMessageLive.ShowReplyTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  alias Memba.Membership.ClubGroupQueries
  alias Memba.Messaging.ConversationFollowQueries
  alias Memba.Messaging.DeliveryQueries
  alias Memba.Messaging.MessageQueries
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)

    Application.put_env(:memba, :messaging_email_delivery_provider, Fake)
    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      Fake.reset()
    end)

    :ok
  end

  test "submit posts a reply as the signed-in member and refreshes the conversation", %{
    conn: conn
  } do
    club_id = Memba.ID.generate(:club)
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.SendClubMessage.prepare(%{
                       message_id: Memba.ID.generate(:message),
                       club_id: club_id,
                       sender_id: alice.person_id,
                       subject: "Trip planning night",
                       body: "Bring your maps."
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert [message] = MessageQueries.list_messages_for_club(club_id)
    refute ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", %{club_id: club_id})
      |> live(~p"/messages/#{message.message_id}")

    refute has_element?(
             view,
             "#member-message-reply-composer",
             "Your reply inherits the subject and is emailed to current followers except you."
           )

    view
    |> element("#member-message-reply-form")
    |> render_submit(%{
      "reply" => %{"sender_id" => alice.person_id, "body" => "I'll bring snacks."}
    })

    assert [root, reply] = MessageQueries.list_conversation_messages(message.message_id)
    assert root.message_id == message.message_id
    assert Memba.ID.valid?(:message, reply.message_id)
    assert reply.sender_id == bob.person_id
    assert reply.conversation_id == message.message_id
    assert reply.reply_to_message_id == message.message_id
    assert reply.subject == "Trip planning night"
    assert reply.body == "I'll bring snacks."

    assert [receipt] = DeliveryQueries.list_member_email_deliverys(reply.message_id)
    assert receipt.recipient_id == alice.person_id
    assert receipt.status == "sent"

    assert has_element?(view, "#member-message-detail[data-reply-state='posted']")

    assert has_element?(
             view,
             "#member-message-reply-success.composer__note",
             "Your reply is being sent."
           )

    success_class =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#member-message-reply-success")
      |> LazyHTML.attribute("class")
      |> List.first()

    assert success_class == "composer__note"
    refute success_class =~ "rounded-2xl"
    refute success_class =~ "border-success"
    refute success_class =~ "bg-success-soft"
    refute success_class =~ "text-success"

    refute has_element?(view, "#member-message-reply-success.bg-success-soft")
    refute has_element?(view, "#member-message-reply-success.text-success")

    refute has_element?(
             view,
             "#member-message-reply-composer",
             "Your reply inherits the subject and is emailed to current followers except you."
           )

    assert ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='true'][data-can-follow='true']",
             "Following"
           )

    assert has_element?(view, "#member-conversation-follow-toggle[type='checkbox'][checked]")

    assert has_element?(
             view,
             "#member-conversation-replies " <>
               "#member-conversation-entry-#{reply.message_id}" <>
               "[data-conversation-kind='reply']" <>
               "[data-sender-id='#{bob.person_id}']",
             "I'll bring snacks."
           )
  end

  test "current member changes follow state with the compact follow toggle", %{conn: conn} do
    club_id = Memba.ID.generate(:club)
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.SendClubMessage.prepare(%{
                       message_id: Memba.ID.generate(:message),
                       club_id: club_id,
                       sender_id: alice.person_id,
                       subject: "Trip planning night",
                       body: "Bring your maps."
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert [message] = MessageQueries.list_messages_for_club(club_id)
    refute ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("bob@example.com", %{club_id: club_id})
      |> live(~p"/messages/#{message.message_id}")

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][phx-change='follow_conversation']"
           )

    refute has_element?(view, "#member-conversation-follow-toggle[checked]")
    refute has_element?(view, "#member-conversation-follow-button")
    refute has_element?(view, "#member-conversation-unfollow-button")

    view
    |> element("#member-conversation-follow-toggle")
    |> render_change()

    assert ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='true'][data-can-follow='true']",
             "Following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][checked][phx-change='unfollow_conversation']"
           )

    view
    |> element("#member-conversation-follow-toggle")
    |> render_change()

    refute ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)

    assert has_element?(
             view,
             "#member-conversation-follow-control.follow-toggle" <>
               "[data-following='false'][data-can-follow='true']",
             "Not following"
           )

    assert has_element?(
             view,
             "#member-conversation-follow-toggle[type='checkbox'][phx-change='follow_conversation']"
           )

    refute has_element?(view, "#member-conversation-follow-toggle[checked]")
    refute has_element?(view, "#member-conversation-follow-button")
    refute has_element?(view, "#member-conversation-unfollow-button")
  end

  test "former members cannot reach the in-app follow control", %{conn: conn} do
    club_id = Memba.ID.generate(:club)
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    assert :ok =
             (with {:ok, command} <-
                     Memba.Messaging.SendClubMessage.prepare(%{
                       message_id: Memba.ID.generate(:message),
                       club_id: club_id,
                       sender_id: alice.person_id,
                       subject: "Trip planning night",
                       body: "Bring your maps."
                     }),
                   {:ok, dispatch_result} <-
                     Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong) do
                dispatch_result
              end)

    assert [message] = MessageQueries.list_messages_for_club(club_id)

    assert :ok =
             (with {:ok, command} <-
                     Memba.Membership.ClubMember.Remove.prepare(%{
                       membership_id: bob.membership_id
                     }) do
                Memba.Membership.CommandDispatch.dispatch(command, consistency: :strong)
              end)

    conn =
      conn
      |> signed_in_club_host("bob@example.com", %{club_id: club_id})
      |> get(~p"/messages/#{message.message_id}")

    assert response(conn, 403) == "Forbidden"
    refute ConversationFollowQueries.following_conversation?(message.message_id, bob.person_id)
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    club = ClubGroupQueries.get_club(club.club_id) || club
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_active_member(club_id, attrs) do
    person_id = Memba.ID.generate(:person)
    email = Keyword.fetch!(attrs, :email)

    if is_nil(ClubGroupQueries.get_club(club_id)) do
      assert :ok =
               (with {:ok, command} <-
                       Memba.Membership.ClubCommands.prepare_create(
                         membership_club_attrs(
                           club_id: club_id,
                           name: "Kootenay Mountaineering Club"
                         )
                       ) do
                  Memba.Membership.CommandDispatch.dispatch(command, consistency: :strong)
                end)
    end

    assert :ok =
             (with {:ok, command} <-
                     Memba.Membership.PersonCommands.prepare_create(%{
                       person_id: person_id,
                       name: Keyword.fetch!(attrs, :name),
                       email: email,
                       email_addresses: [%{email: email, is_primary: true}]
                     }) do
                Memba.Membership.CommandDispatch.dispatch(command, consistency: :strong)
              end)

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             (with {:ok, command} <-
                     Memba.Membership.AddMember.prepare(%{
                       membership_id: membership_id,
                       club_id: club_id,
                       person_id: person_id
                     }) do
                Memba.Membership.CommandDispatch.dispatch(command, consistency: :strong)
              end)

    %{club_id: club_id, person_id: person_id, membership_id: membership_id}
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
