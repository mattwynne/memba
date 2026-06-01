defmodule MembaWeb.MemberMessageLive.NewSendTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

  import ExUnit.CaptureLog

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryProviders.Unavailable
  alias MembaWeb.UserAuth

  setup do
    original_provider = Application.get_env(:memba, :messaging_delivery_provider)

    Application.put_env(:memba, :messaging_delivery_provider, Fake)
    Fake.reset()

    on_exit(fn ->
      restore_env(:messaging_delivery_provider, original_provider)
      Fake.reset()
    end)

    :ok
  end

  test "submit sends a generated club message as the signed-in member and ignores sender params",
       %{
         conn: conn
       } do
    club_id = Ecto.UUID.generate()
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/new?club_id=#{club_id}")

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
    assert Ecto.UUID.cast(message.message_id) != :error
    assert message.sender_id == alice.person_id
    assert message.subject == "Trip planning night"
    assert message.body == "Bring route ideas."

    assert [
             %{recipient_id: alice_recipient_id, receipt_status: "sent"},
             %{recipient_id: bob_recipient_id, receipt_status: "sent"}
           ] = Messaging.list_member_receipts(message.message_id)

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

    assert has_element?(view, "#member-compose-success-state", "Message sent.")

    assert has_element?(
             view,
             "#member-compose-success-summary[data-active-member-count='2']",
             "all 2 active members"
           )

    assert has_element?(
             view,
             "#member-compose-see-receipts-link[href='/messages/#{message.message_id}?club_id=#{club_id}']",
             "See who got it"
           )

    assert has_element?(
             view,
             "#member-compose-send-another-link[href='/messages/new?club_id=#{club_id}']",
             "Send another message"
           )

    assert has_element?(
             view,
             "#member-compose-back-home-link[href='/?club_id=#{club_id}']",
             "Back to home"
           )

    refute has_element?(view, "#member-message-compose-form")
  end

  test "send failure renders an incident state with support guidance and retry actions", %{
    conn: conn
  } do
    Application.put_env(:memba, :messaging_delivery_provider, Unavailable)

    club_id = Ecto.UUID.generate()
    _alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    _bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    {:ok, view, _html} =
      conn
      |> init_test_session(%{UserAuth.identity_session_key() => "alice@example.com"})
      |> live(~p"/messages/new?club_id=#{club_id}")

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

    assert has_element?(view, "#member-compose-error-state", "That didn’t send.")

    assert has_element?(
             view,
             "#member-compose-error-summary",
             "Your message was not sent to anyone."
           )

    assert has_element?(view, "#member-compose-error-summary", "contact support")

    assert has_element?(
             view,
             "button#member-compose-try-again-button[type='button']",
             "Try again"
           )

    assert has_element?(
             view,
             "#member-compose-back-home-after-error-link[href='/?club_id=#{club_id}']",
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

  defp create_active_member(club_id, attrs) do
    person_id = Ecto.UUID.generate()

    if is_nil(Membership.get_club(club_id)) do
      assert :ok =
               Membership.create_club(
                 %{club_id: club_id, name: "Kootenay Mountaineering Club"},
                 consistency: :strong
               )
    end

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: Keyword.fetch!(attrs, :name),
                 email: Keyword.fetch!(attrs, :email)
               },
               consistency: :strong
             )

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: Ecto.UUID.generate(),
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
