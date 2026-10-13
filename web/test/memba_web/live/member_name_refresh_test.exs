defmodule MembaWeb.MemberNameRefreshTest do
  use MembaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Memba.Membership.{PersonCommands, CommandDispatch}

  setup do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    :ok
  end

  test "real rename refreshes open cross-club history including inactive root/reply/participant authors",
       %{conn: conn} do
    first = club("History Club", "history")
    second = club("Other History Club", "other-history")
    alice = person("Alice Smith", "alice.history@example.test")
    bob = person("Bob Builder", "bob.history@example.test")
    add_member(first, bob)
    alice_membership = add_member(first, alice)
    add_member(second, alice)
    add_member(second, bob)
    root = message(first, alice, "Earlier Alice root")
    bob_root = message(first, bob, "Earlier Bob root")
    reply = Memba.ID.generate(:message)

    {:ok, command} =
      Memba.Messaging.PostMemberMessageReply.prepare(%{
        message_id: reply,
        conversation_id: bob_root,
        sender_id: alice,
        body: "Earlier Alice reply"
      })

    assert {:ok, :ok} = Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong)

    other_root = message(second, alice, "Other club root")

    {:ok, removal} =
      Memba.Membership.ClubMember.Remove.prepare(%{membership_id: alice_membership})

    assert :ok = CommandDispatch.dispatch(removal, consistency: :strong)

    bob_conn = sign_in(conn, first, "bob.history@example.test")
    alice_conn = sign_in(conn, second, "alice.history@example.test")
    {:ok, dashboard, _} = live(bob_conn, ~p"/conversations")
    {:ok, detail, _} = live(bob_conn, ~p"/messages/#{bob_root}")
    {:ok, other_dashboard, _} = live(alice_conn, ~p"/conversations")
    {:ok, settings, _} = live(alice_conn, ~p"/my/settings")
    assert has_element?(dashboard, "#member-message-#{root}", "Alice Smith")
    settings |> element("#my-settings-edit-name") |> render_click()
    settings |> form("#my-settings-name-form", person: %{name: "Robin Jones"}) |> render_submit()
    assert has_element?(dashboard, "#member-message-#{root}", "Robin Jones")

    assert has_element?(
             dashboard,
             "#member-message-#{bob_root} [data-participant-id='#{alice}'][data-participant-name='Robin Jones']",
             "RJ"
           )

    assert has_element?(other_dashboard, "#member-message-#{other_root}", "Robin Jones")

    assert has_element?(
             other_dashboard,
             "#club-site-identity-menu .app-menu__who-name",
             "Robin Jones"
           )

    %{socket: socket} = :sys.get_state(detail.pid)

    entry =
      Enum.find(
        socket.assigns.message_detail.conversation_entries,
        &(&1.message.message_id == reply)
      )

    assert entry.sender_name == "Robin Jones"
    %{socket: socket} = :sys.get_state(dashboard.pid)
    assert {:person, alice} in MembaWeb.MemberDashboardQuery.interests(socket.assigns.dashboard)
    row = Enum.find(socket.assigns.dashboard.message_rows, &(&1.message_id == bob_root))
    assert row.latest_replier_name == "Robin Jones"
    refute has_element?(dashboard, "#club-member-#{alice}")
  end

  test "open delivery names and initials follow inactive recipients without rewriting snapshots", %{conn: conn} do
    club = club("Recipient History", "recipient-history")
    alice = person("Alice Smith", "alice.recipient@example.test")
    bob = person("Bob Builder", "bob.recipient@example.test")
    add_member(club, bob)
    membership = add_member(club, alice)
    root = message(club, bob, "Earlier recipient")
    records = Memba.Messaging.DeliveryQueries.list_member_email_deliverys(root)
    assert Enum.find(records, &(&1.recipient_id == alice)).recipient_name == "Alice Smith"
    message_before = Memba.Messaging.App.aggregate_state(Memba.Messaging.Message, root)
    artifact_fields = [:delivery_id, :recipient_id, :recipient_name, :recipient_address, :outbound_message_id]
    artifacts_before = Memba.Messaging.DeliveryQueries.list_operator_email_deliveries(root)
      |> Enum.map(&Map.take(&1, artifact_fields))

    {:ok, removal} = Memba.Membership.ClubMember.Remove.prepare(%{membership_id: membership})
    assert :ok = CommandDispatch.dispatch(removal, consistency: :strong)
    {:ok, view, _} = live(sign_in(conn, club, "bob.recipient@example.test"), ~p"/messages/#{root}/delivery")
    assert has_element?(view, "#member-delivery-receipt-#{alice}", "Alice Smith")
    {:ok, rename} = PersonCommands.prepare_rename(%{person_id: alice}, %{
      person_id: alice, name: "Robin Jones", expected_name: "Alice Smith"
    })
    assert :ok = CommandDispatch.dispatch(rename, consistency: :strong)
    assert has_element?(view, "#member-delivery-receipt-#{alice}[data-recipient-name='Robin Jones']", "RJ")
    assert has_element?(view, "#member-delivery-receipt-#{alice} .recipient__name", "Robin Jones")
    assert Memba.Messaging.DeliveryQueries.list_member_email_deliverys(root) == records
    assert Memba.Messaging.App.aggregate_state(Memba.Messaging.Message, root) == message_before
    artifacts_after = Memba.Messaging.DeliveryQueries.list_operator_email_deliveries(root)
      |> Enum.map(&Map.take(&1, artifact_fields))
    assert artifacts_after == artifacts_before
    {:ok, reopened, _} = live(sign_in(conn, club, "bob.recipient@example.test"), ~p"/messages/#{root}/delivery")
    assert has_element?(reopened, "#member-delivery-receipt-#{alice}", "Robin Jones")
  end

  test "other member query shells declare and reread their represented Person names", %{
    conn: _conn
  } do
    club = club("Name Dependencies", "name-dependencies")
    alice = person("Alice Smith", "alice.dependencies@example.test")
    bob = person("Bob Builder", "bob.dependencies@example.test")
    add_member(club, alice)
    add_member(club, bob)
    root = message(club, bob, "Delivery history")

    inputs = %{
      club_id: club.club_id,
      authenticated_email: "alice.dependencies@example.test",
      group_id: nil,
      message_id: root
    }

    queries = [
      MembaWeb.MemberGroupCreationQuery,
      MembaWeb.MemberInvitationQuery,
      MembaWeb.MemberMessageComposeQuery,
      MembaWeb.MemberMessageDeliveryQuery
    ]

    for module <- queries do
      assert {:ok, _result, interests} = LiveQuery.Query.load(module.query(), inputs)
      assert {:person, alice} in interests
    end

    {:ok, _result, interests} =
      LiveQuery.Query.load(MembaWeb.MemberMessageComposeQuery.query(), inputs)

    assert {:person, bob} in interests

    {:ok, _result, interests} =
      LiveQuery.Query.load(MembaWeb.MemberMessageDeliveryQuery.query(), inputs)

    assert {:person, bob} in interests

    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: alice}, %{
        person_id: alice,
        name: "Robin Jones",
        expected_name: "Alice Smith"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    for module <- queries do
      assert {:ok, result, _interests} = LiveQuery.Query.load(module.query(), inputs)
      assert result.current_member.name == "Robin Jones"
    end
  end

  defp club(name, slug) do
    id = Memba.ID.generate(:club)

    {:ok, command} =
      Memba.Membership.ClubCommands.prepare_create(%{club_id: id, name: name, slug: slug})

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    Memba.Membership.ClubGroupQueries.get_club(id)
  end

  defp person(name, email) do
    id = Memba.ID.generate(:person)
    {:ok, command} = PersonCommands.prepare_create(%{person_id: id, name: name, email: email})
    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    id
  end

  defp add_member(club, person_id) do
    id = Memba.ID.generate(:membership)

    {:ok, command} =
      Memba.Membership.AddMember.prepare(%{
        membership_id: id, club_id: club.club_id, person_id: person_id
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    id
  end

  defp message(club, sender_id, subject) do
    id = Memba.ID.generate(:message)

    {:ok, command} =
      Memba.Messaging.SendClubMessage.prepare_current_member(%{
        message_id: id, club_id: club.club_id, sender_id: sender_id,
        subject: subject, body: "History remains unchanged."
      })

    assert {:ok, :ok} = Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong)

    id
  end

  defp sign_in(conn, club, email) do
    %{host: host} = URI.parse(MembaWeb.ClubSite.url(club))

    conn
    |> Map.put(:host, host)
    |> init_test_session(%{MembaWeb.IdentityAuth.identity_session_key() => email})
  end
end
