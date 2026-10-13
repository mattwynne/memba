defmodule Memba.Membership.PersonRenameReadbackTest do
  use MembaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  alias Memba.Membership.{CommandDispatch, PersonCommands}
  alias Memba.Membership.Projectors.Person, as: PersonProjector

  setup %{conn: conn} do
    Memba.EventSourcedCase.reset_event_sourced_system!()
    club = insert_membership_club!(name: "Readback Club", slug: "readback")
    id = Memba.ID.generate(:person)

    {:ok, command} =
      PersonCommands.prepare_create(%{
        person_id: id,
        name: "Alice Smith",
        email: "readback@example.test"
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
        MembaWeb.IdentityAuth.identity_session_key() => "readback@example.test"
      })

    {:ok, view, _} = live(conn, ~p"/my/settings")
    view |> element("#my-settings-edit-name") |> render_click()
    %{view: view, person_id: id}
  end

  test "eventless identical-target success waits for the earlier winning projection and preserves draft on timeout",
       %{view: view, person_id: id} do
    projector = suspend_projector()
    winner(id)
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    assert Memba.Membership.get_person(id).name == "Alice Smith"
    view |> form("#my-settings-name-form", person: %{name: "Alice Jones"}) |> render_submit()
    assert has_element?(view, "#my-settings-name-input[value='Alice Jones']")
    assert has_element?(view, "#flash-error", "latest name")
    assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
    :ok = :sys.resume(projector)
    Memba.ProjectionBarrier.await!([PersonProjector])
    view |> form("#my-settings-name-form", person: %{name: "Alice Jones"}) |> render_submit()
    refute has_element?(view, "#my-settings-name-form")
    assert has_element?(view, "#my-settings-profile-name", "Alice Jones")
    assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
  end

  test "lagging conflict displays authoritative value and cancellation cannot discard until readback succeeds",
       %{view: view, person_id: id} do
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_change()
    projector = suspend_projector()
    winner(id)
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_submit()
    assert Memba.Membership.get_person(id).name == "Alice Smith"
    assert has_element?(view, "#my-settings-name-conflict", "Alice Jones")
    view |> element("#my-settings-name-cancel-changes") |> render_click()
    assert has_element?(view, "#my-settings-name-input[value='Alice Brown']")
    assert has_element?(view, "#my-settings-name-conflict", "Alice Jones")
    :ok = :sys.resume(projector)
    Memba.ProjectionBarrier.await!([PersonProjector])
    view |> element("#my-settings-name-cancel-changes") |> render_click()
    refute has_element?(view, "#my-settings-name-form")
    assert has_element?(view, "#my-settings-profile-name", "Alice Jones")
    assert Memba.ProjectionBarrier.current_checkpoint() == checkpoint
  end

  test "eventless confirmed success also retains draft while the earlier winner is unprojected",
       %{view: view, person_id: id} do
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_change()
    winner(id)
    Memba.ProjectionBarrier.await!([PersonProjector])
    view |> form("#my-settings-name-form", person: %{name: "Alice Brown"}) |> render_submit()
    projector = suspend_projector()

    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: id}, %{
        person_id: id,
        name: "Alice Brown",
        expected_name: "Alice Jones"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :eventual)
    view |> element("#my-settings-name-save-anyway") |> render_click()
    assert has_element?(view, "#my-settings-name-input[value='Alice Brown']")
    :ok = :sys.resume(projector)
    Memba.ProjectionBarrier.await!([PersonProjector])
    view |> element("#my-settings-name-save-anyway") |> render_click()
    refute has_element?(view, "#my-settings-name-form")
    assert has_element?(view, "#my-settings-profile-name", "Alice Brown")
  end

  defp winner(id) do
    {:ok, command} =
      PersonCommands.prepare_rename(%{person_id: id}, %{
        person_id: id,
        name: "Alice Jones",
        expected_name: "Alice Smith"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :eventual)
  end

  defp suspend_projector do
    {_child, pid, :worker, _modules} =
      Enum.find(Supervisor.which_children(Memba.Supervisor), fn
        {{PersonProjector, _opts}, _pid, :worker, _modules} -> true
        _ -> false
      end)

    :ok = :sys.suspend(pid)

    on_exit(fn ->
      try do
        :sys.resume(pid)
      catch
        :exit, _ -> :ok
      end
    end)

    pid
  end
end
