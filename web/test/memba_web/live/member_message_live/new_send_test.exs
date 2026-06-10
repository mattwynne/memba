defmodule MembaWeb.MemberMessageLive.NewSendTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  import ExUnit.CaptureLog

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable
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

  test "submit sends a generated club message as the signed-in member and ignores sender params",
       %{
         conn: conn
       } do
    club_id = Memba.ID.generate(:club)
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", %{club_id: club_id})
      |> live(~p"/messages/new")

    view
    |> element("#member-message-compose-form")
    |> render_submit(%{
      "message" => %{
        "sender_id" => bob.person_id,
        "subject" => "Trip planning night",
        "body" => "Bring route ideas."
      }
    })

    assert [message] = Messaging.list_messages_for_club(club_id)
    assert Memba.ID.valid?(:message, message.message_id)
    assert message.sender_id == alice.person_id
    assert message.subject == "Trip planning night"
    assert message.body == "Bring route ideas."

    assert [
             %{recipient_id: alice_recipient_id, status: "sent"},
             %{recipient_id: bob_recipient_id, status: "sent"}
           ] = Messaging.list_member_email_deliverys(message.message_id)

    assert [alice_recipient_id, bob_recipient_id] == [alice.person_id, bob.person_id]

    assert [
             %{message_id: message_id, club_id: ^club_id, recipient_id: ^alice_recipient_id},
             %{message_id: message_id, club_id: ^club_id, recipient_id: ^bob_recipient_id}
           ] = Fake.deliveries()

    assert message_id == message.message_id

    assert has_element?(
             view,
             "#member-message-compose[data-compose-state='sent'][data-sent-message-id='#{message.message_id}']"
           )

    assert has_element?(view, "#member-compose-success-state", "Your message is being sent.")

    assert has_element?(
             view,
             "#member-compose-success-summary[data-active-member-count='2']",
             "all 2 current members"
           )

    assert has_element?(
             view,
             "#member-compose-see-receipts-link[href='/messages/#{message.message_id}']",
             "Check delivery"
           )

    assert has_element?(
             view,
             "#member-compose-send-another-link[href='/messages/new']",
             "Send another message"
           )

    assert has_element?(
             view,
             "#member-compose-back-home-link[href='/']",
             "Back to club home"
           )

    refute has_element?(view, "#member-message-compose-form")
  end

  test "blank body validation keeps the compose form and does not send", %{conn: conn} do
    club_id = Memba.ID.generate(:club)
    _alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    _bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", %{club_id: club_id})
      |> live(~p"/messages/new")

    view
    |> element("#member-message-compose-form")
    |> render_submit(%{
      "message" => %{
        "subject" => "Trip planning night",
        "body" => "  \n\t "
      }
    })

    assert has_element?(view, "#member-message-compose[data-compose-state='composing']")
    assert has_element?(view, "#member-message-body-error", "Message body can’t be blank.")
    assert render(view) =~ "Trip planning night"
    assert Messaging.list_messages_for_club(club_id) == []
    assert Fake.deliveries() == []
  end

  test "send failure renders an incident state with support guidance and retry actions", %{
    conn: conn
  } do
    Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

    club_id = Memba.ID.generate(:club)
    _alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    _bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", %{club_id: club_id})
      |> live(~p"/messages/new")

    log =
      capture_log(fn ->
        view
        |> element("#member-message-compose-form")
        |> render_submit(%{
          "message" => %{
            "subject" => "Trail notice",
            "body" => "The bridge is out."
          }
        })
      end)

    assert log =~ "Member message send failed"

    assert has_element?(
             view,
             "#member-message-compose[data-compose-state='send_failed']"
           )

    assert has_element?(view, "#member-compose-error-state", "Your message was not sent.")

    assert has_element?(
             view,
             "#member-compose-error-summary",
             "No one received this message."
           )

    assert has_element?(
             view,
             "#member-compose-error-summary",
             "ask a group organizer to contact Memba"
           )

    assert has_element?(
             view,
             "button#member-compose-try-again-button[type='button']",
             "Try again"
           )

    assert has_element?(
             view,
             "#member-compose-back-home-after-error-link[href='/']",
             "Back to club home"
           )

    refute has_element?(view, "#member-compose-success-state")
    refute has_element?(view, "#member-message-compose-form")

    view
    |> element("#member-compose-try-again-button")
    |> render_click()

    assert has_element?(view, "#member-message-compose[data-compose-state='composing']")
    assert has_element?(view, "#member-message-compose-form")
    refute has_element?(view, "#member-compose-error-state")
  end

  defp signed_in_club_host(conn, email, club) do
    conn
    |> club_host(club)
    |> init_test_session(%{IdentityAuth.identity_session_key() => email})
  end

  defp club_host(conn, club) do
    club = Memba.Membership.get_club(club.club_id) || club
    %{host: host} = URI.parse(ClubSite.url(club))
    Map.put(conn, :host, host)
  end

  defp create_active_member(club_id, attrs) do
    person_id = Memba.ID.generate(:person)
    email = Keyword.fetch!(attrs, :email)

    if is_nil(Membership.get_club(club_id)) do
      assert :ok =
               Membership.create_club(
                 membership_club_attrs(club_id: club_id, name: "Kootenay Mountaineering Club"),
                 consistency: :strong
               )
    end

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.fetch!(attrs, :name),
                 email: email,
                 email_addresses: [%{email: email, is_primary: true}]
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Memba.ID.generate(:membership),
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    %{club_id: club_id, person_id: person_id}
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
