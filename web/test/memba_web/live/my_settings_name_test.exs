defmodule MembaWeb.MySettingsNameTest do
  use MembaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Memba.Membership.{PersonCommands, PersonEmailAddressCommands, CommandDispatch}

  setup %{conn: conn} do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    club = insert_membership_club!(name: "Settings Name Proof", slug: "settings-name-proof")
    id = Memba.ID.generate(:person)

    {:ok, command} =
      PersonCommands.prepare_create(%{
        person_id: id,
        name: "Alice Smith",
        email: "settings.name.proof@example.test"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    Memba.Repo.insert!(%Memba.Membership.Projections.Membership{
      membership_id: Memba.ID.generate(:membership),
      club_id: club.club_id,
      person_id: id,
      active: true
    })

    %{host: host} = URI.parse(MembaWeb.ClubSite.url(club))

    conn =
      conn
      |> Map.put(:host, host)
      |> init_test_session(%{
        MembaWeb.IdentityAuth.identity_session_key() => "settings.name.proof@example.test"
      })

    {:ok, view, _} = live(conn, ~p"/my/settings")
    %{view: view, person_id: id}
  end

  test "posted target IDs cannot rename anyone but the authenticated Person and unrelated email/tab state survives",
       %{view: view, person_id: id} do
    view |> element("#my-settings-edit-name") |> render_click()
    render_change(view, "add_email_address", %{"email_address" => %{"email" => "invalid"}})
    view |> element("#my-settings-tab-emails") |> render_click()

    render_submit(view, "save_name", %{
      "person" => %{
        "name" => " Robin   Jones ",
        "person_id" => Memba.ID.generate(:person),
        "expected_name" => "Client supplied"
      }
    })

    assert Memba.Membership.PersonQueries.get_person(id).name == "Robin Jones"
    assert has_element?(view, "#my-settings[data-active-tab='emails']")
    assert has_element?(view, "#settings-add-email-input[value='invalid']")
  end

  test "editing a rejected raw draft invalidates consent, and Enter/Save cannot confirm", %{
    view: view,
    person_id: id
  } do
    view |> element("#my-settings-edit-name") |> render_click()
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_change()
    rename(id, "Alice Jones", "Alice Smith")
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_submit()
    view |> form("#my-settings-name-form", person: %{name: " Alice Brown "}) |> render_change()
    refute has_element?(view, "#my-settings-name-conflict")
    render_click(view, "confirm_name", %{"expected_name" => "Alice Jones"})
    assert Memba.Membership.PersonQueries.get_person(id).name == "Alice Jones"
    view |> form("#my-settings-name-form", person: %{name: " Alice Brown "}) |> render_submit()
    assert Memba.Membership.PersonQueries.get_person(id).name == "Alice Jones"
    assert has_element?(view, "#my-settings-name-conflict", "Alice Jones")
  end

  test "field errors are cleared when reopening a cancelled editor", %{view: view} do
    view |> element("#my-settings-edit-name") |> render_click()
    view |> form("#my-settings-name-form", person: %{name: "   "}) |> render_submit()
    assert has_element?(view, "#my-settings-name-error")
    view |> element("#my-settings-cancel-name") |> render_click()
    view |> element("#my-settings-edit-name") |> render_click()
    refute has_element?(view, "#my-settings-name-error")
    view |> form("#my-settings-name-form", person: %{name: "   "}) |> render_submit()
    view |> form("#my-settings-name-form", person: %{name: "Robin Jones"}) |> render_change()
    refute has_element?(view, "#my-settings-name-error")
  end

  test "save, eventless save, confirm and cancel reauthorize even a previously bound socket", %{
    view: view,
    person_id: id
  } do
    view |> element("#my-settings-edit-name") |> render_click()
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_change()
    rename(id, "Alice Jones", "Alice Smith")
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_submit()
    %{socket: socket} = :sys.get_state(view.pid)
    GenServer.stop(view.pid)

    {:ok, add} = PersonEmailAddressCommands.prepare_add(%{
      person_id: id, email: "new.identity@example.test"
    })
    assert :ok = CommandDispatch.dispatch(add, consistency: :strong)

    assert :ok = Memba.Membership.PersonEmailVerification.verify(%{
      person_id: id, email: "new.identity@example.test"
    }, consistency: :strong)

    {:ok, replacement, []} = PersonEmailAddressCommands.prepare_replace(%{
      person_id: id,
      email_addresses: [%{email: "new.identity@example.test", is_primary: true}]
    })
    assert :ok = CommandDispatch.dispatch(replacement, consistency: :strong)

    checkpoint = Memba.ProjectionBarrier.current_checkpoint()

    for {event, params} <- [
          {"save_name", %{"person" => %{"name" => "Alice Brown"}}},
          {"save_name", %{"person" => %{"name" => "Alice Jones"}}},
          {"confirm_name", %{}},
          {"cancel_name", %{}}
        ] do
      assert_raise MembaWeb.ForbiddenError, fn ->
        MembaWeb.MySettingsLive.handle_event(event, params, socket)
      end

      assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
    end
  end

  defp rename(id, name, expected) do
    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: id}, %{
        person_id: id,
        name: name,
        expected_name: expected
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
  end
end
