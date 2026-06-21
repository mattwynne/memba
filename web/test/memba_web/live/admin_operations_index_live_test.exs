defmodule MembaWeb.AdminOperationsIndexLiveTest do
  use MembaWeb.FeatureCase, async: false

  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  test "global staff operations indexes require staff sign-in" do
    for path <- ["/admin/people", "/admin/messages"] do
      conn =
        build_conn(:get, path)
        |> get(path)

      assert redirected_to(conn) == ~p"/auth"
      assert Plug.Conn.get_session(conn, MembaWeb.IdentityAuth.return_to_session_key()) == path
    end
  end

  test "live-rendered staff navigation exposes only working operations pages", %{conn: conn} do
    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/people")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)
    nav_selector = "nav[aria-label='Memba staff navigation']"

    assert_selector_exists(html, "#{nav_selector} #admin-nav-clubs[href='/admin/clubs']")
    assert_selector_exists(html, "#{nav_selector} #admin-nav-requests[href='/admin/requests']")
    assert_selector_exists(html, "#{nav_selector} #admin-nav-people[href='/admin/people']")
    assert_selector_exists(html, "#{nav_selector} #admin-nav-messages[href='/admin/messages']")

    assert_selector_exists(
      html,
      "#{nav_selector} #admin-nav-deliveries[href='/admin/deliveries']"
    )

    assert_selector_count(html, "#{nav_selector} a", 5)

    nav_text = text_for(html, nav_selector)
    assert nav_text =~ "Clubs"
    assert nav_text =~ "Requests"
    assert nav_text =~ "People"
    assert nav_text =~ "Messages"
    assert nav_text =~ "Deliveries"
    refute nav_text =~ "Incoming"
    refute nav_text =~ "Roles"
  end

  test "Memba staff can open the read-only global People index", %{conn: conn} do
    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/people")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "People"
    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#admin-people-index")
    assert_selector_exists(html, "#admin-people-read-only-notice")
    assert_selector_exists(html, "#admin-people-table[aria-label='People records']")
    refute_selector_exists(html, "#new-person-form")
    refute_selector_exists(html, "#admin-people-index form")
    refute_selector_exists(html, "#admin-people-index nav[aria-label='Pagination']")
    refute_selector_exists(html, "#admin-people-index [data-admin-person-action='bulk']")
  end

  test "global People index streams deterministic read-only person summaries", %{conn: conn} do
    kootenay = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    nelson = insert_membership_club!(name: "Nelson Paddling Club", slug: "npc")

    alice =
      insert_membership_person!(
        person_id: Memba.ID.deterministic(:person, ["admin-people-index", "alice"]),
        name: "Alice Adams",
        email: "alice@example.com",
        email_addresses: [
          %{email: "alice@example.com", is_primary: true},
          %{email: "alice@work.example", is_primary: false}
        ]
      )

    bob =
      insert_membership_person!(
        person_id: Memba.ID.deterministic(:person, ["admin-people-index", "bob"]),
        name: "Bob Builder",
        email: "bob@example.com"
      )

    staff =
      insert_membership_person!(
        person_id: Memba.ID.deterministic(:person, ["admin-people-index", "staff"]),
        name: "Zz Staff",
        email: "zz-staff@memba.io"
      )

    insert_membership!(kootenay, alice)
    insert_membership!(nelson, alice)
    insert_membership!(kootenay, bob)

    response =
      conn
      |> sign_in_staff(staff.email)
      |> get(~p"/admin/people")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert row_ids(html, "[data-testid='admin-person-row']") == [
             alice.person_id,
             bob.person_id,
             staff.person_id
           ]

    assert text_for(
             html,
             "#person-row-#{alice.person_id} [data-testid='admin-person-primary-email']"
           ) =~
             "alice@example.com"

    assert text_for(
             html,
             "#person-row-#{alice.person_id} [data-testid='admin-person-alternate-emails']"
           ) =~
             "alice@work.example"

    memberships =
      text_for(html, "#person-row-#{alice.person_id} [data-testid='admin-person-memberships']")

    assert memberships =~ "Kootenay Mountaineering Club"
    assert memberships =~ "Nelson Paddling Club"

    refute_selector_exists(html, "#person-row-#{alice.person_id} a")
  end

  test "Memba staff can open the read-only global Messages index", %{conn: conn} do
    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/messages")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert response =~ "Messages"
    assert_selector_exists(html, "#admin-layout[data-surface='admin']")
    assert_selector_exists(html, "#admin-messages-index")
    assert_selector_exists(html, "#admin-messages-read-only-notice")
    assert_selector_exists(html, "#admin-messages-table[aria-label='Messages']")
    refute_selector_exists(html, "#new-message-form")
    refute_selector_exists(html, "[data-admin-message-action='resend']")
    refute_selector_exists(html, "[data-admin-message-action='delete']")
    refute_selector_exists(html, "#admin-messages-index form")
    refute_selector_exists(html, "#admin-messages-index nav[aria-label='Pagination']")
    refute_selector_exists(html, "#admin-messages-index [data-admin-message-action='bulk']")
    refute_selector_exists(html, "#admin-messages-index [data-admin-message-filter]")
  end

  test "global Messages index streams deterministic read-only projected message summaries", %{
    conn: conn
  } do
    club = insert_membership_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
    sender = insert_membership_person!(name: "Alice Adams", email: "alice@example.com")

    older =
      insert_message_projection!(
        club_id: club.club_id,
        sender_id: sender.person_id,
        subject: "Older trip planning note",
        inserted_at: ~U[2026-06-05 10:00:00.000000Z]
      )

    newer =
      insert_message_projection!(
        club_id: club.club_id,
        sender_id: sender.person_id,
        subject: "Newer trip planning note",
        inserted_at: ~U[2026-06-05 12:00:00.000000Z]
      )

    response =
      conn
      |> sign_in_staff()
      |> get(~p"/admin/messages")
      |> html_response(200)

    html = LazyHTML.from_fragment(response)

    assert row_ids(html, "[data-testid='admin-message-row']") == [
             newer.message_id,
             older.message_id
           ]

    assert text_for(html, "#message-row-#{newer.message_id} [data-testid='admin-message-club']") =~
             "Kootenay Mountaineering Club"

    assert text_for(html, "#message-row-#{newer.message_id} [data-testid='admin-message-sender']") =~
             "Alice Adams (alice@example.com)"

    assert text_for(
             html,
             "#message-row-#{newer.message_id} [data-testid='admin-message-projected-at']"
           ) =~
             "2026-06-05 12:00:00 UTC"

    assert_selector_exists(
      html,
      "#message-row-#{newer.message_id} a[href='/admin/messages/#{newer.message_id}']"
    )
  end

  defp insert_membership!(club, person) do
    Repo.insert!(%MembershipProjection{
      membership_id: Memba.ID.generate(:membership),
      club_id: club.club_id,
      person_id: person.person_id,
      active: true
    })
  end

  defp insert_message_projection!(attrs) do
    inserted_at = Keyword.fetch!(attrs, :inserted_at)
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)

    Repo.insert!(%MessageProjection{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body."),
      inserted_at: inserted_at,
      updated_at: Keyword.get(attrs, :updated_at, inserted_at)
    })
  end

  defp row_ids(html, selector) do
    html
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute("data-person-id")
    |> case do
      [] ->
        html
        |> LazyHTML.query(selector)
        |> LazyHTML.attribute("data-message-id")

      ids ->
        ids
    end
  end

  defp text_for(html, selector) do
    html
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp assert_selector_count(html, selector, expected_count) do
    actual_count = html |> LazyHTML.query(selector) |> Enum.count()
    assert actual_count == expected_count, "Expected #{expected_count} matches for #{selector}"
  end

  defp refute_selector_exists(html, selector) do
    refute html |> LazyHTML.query(selector) |> Enum.any?(), "Did not expect selector #{selector}"
  end
end
