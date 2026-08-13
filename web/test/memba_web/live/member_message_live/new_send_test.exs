defmodule MembaWeb.MemberMessageLive.NewSendTest do
  use MembaWeb.FeatureCase, async: false

  import Phoenix.LiveViewTest

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

    await_delivery_projection!()

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

    delivery_statuses =
      message.message_id
      |> Messaging.list_recipient_deliveries()
      |> Enum.map(& &1.status)

    assert length(delivery_statuses) == 2
    assert Enum.all?(delivery_statuses, &(&1 in ["pending", "dispatching", "sent"]))

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
             "#member-compose-see-receipts-link.btn.btn-primary.btn-lg[href='/messages/#{message.message_id}']",
             "Check delivery"
           )

    assert has_element?(
             view,
             "#member-compose-send-another-link.btn.btn-soft.btn-lg[href='/messages/new']",
             "Send another message"
           )

    assert has_element?(
             view,
             "#member-compose-back-home-link.btn.btn-ghost.btn-lg[href='/conversations']",
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

  test "submit accepts the message without waiting for every delivery diagnostics projector", %{
    conn: conn
  } do
    club_id = Memba.ID.generate(:club)
    alice = create_active_member(club_id, name: "Alice Adams", email: "alice@example.com")
    _bob = create_active_member(club_id, name: "Bob Builder", email: "bob@example.com")

    stop_projector!(Memba.Messaging.Projectors.MembaStaffEmailDelivery)

    {:ok, view, _html} =
      conn
      |> signed_in_club_host("alice@example.com", %{club_id: club_id})
      |> live(~p"/messages/new")

    view
    |> element("#member-message-compose-form")
    |> render_submit(%{
      "message" => %{
        "subject" => "Trip planning night",
        "body" => "Bring route ideas."
      }
    })

    await_delivery_projection!()

    assert [message] = Messaging.list_messages_for_club(club_id)
    assert message.sender_id == alice.person_id

    assert has_element?(
             view,
             "#member-message-compose[data-compose-state='sent'][data-sent-message-id='#{message.message_id}']"
           )

    refute has_element?(view, "#member-compose-error-state")
  end

  test "provider failure still accepts the message and renders the success state", %{
    conn: conn
  } do
    Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

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
        "subject" => "Trail notice",
        "body" => "The bridge is out."
      }
    })

    assert has_element?(
             view,
             "#member-message-compose[data-compose-state='sent']"
           )

    assert has_element?(view, "#member-compose-success-state", "Your message is being sent.")
    refute has_element?(view, "#member-compose-error-state")
    refute has_element?(view, "#member-message-compose-form")

    await_delivery_projection!()

    assert [message] = Messaging.list_messages_for_club(club_id)

    assert [
             %{recipient_id: alice_recipient_id, status: "sent"},
             %{recipient_id: bob_recipient_id, status: "sent"}
           ] = Messaging.list_member_email_deliverys(message.message_id)

    assert [alice_recipient_id, bob_recipient_id] == [alice.person_id, bob.person_id]

    delivery_statuses =
      message.message_id
      |> Messaging.list_recipient_deliveries()
      |> Enum.map(& &1.status)

    assert length(delivery_statuses) == 2
    assert Enum.all?(delivery_statuses, &(&1 in ["pending", "dispatching", "failed"]))

    assert Fake.deliveries() == []
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

  defp await_delivery_projection! do
    Memba.ProjectionBarrier.await!(
      [
        Memba.Messaging.Projectors.EmailDelivery,
        Memba.Messaging.Projectors.MemberEmailDelivery
      ],
      timeout: 1_000
    )
  end

  defp stop_projector!(projector) do
    child_id = projector_child_id!(projector)

    case Supervisor.terminate_child(Memba.Supervisor, child_id) do
      :ok ->
        on_exit(fn -> restart_projector!(child_id) end)
        :ok

      {:error, :not_found} ->
        flunk("Expected #{inspect(projector)} to be supervised")
    end
  end

  defp projector_child_id!(projector) do
    Supervisor.which_children(Memba.Supervisor)
    |> Enum.find_value(fn
      {child_id, _pid, :worker, [module]} when module == projector -> child_id
      _child -> nil
    end)
    |> case do
      nil -> flunk("Expected #{inspect(projector)} to be supervised")
      child_id -> child_id
    end
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
      {:error, :not_found} -> :ok
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
