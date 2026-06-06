defmodule MembaWeb.Admin.RequestsLive.IndexTest do
  use MembaWeb.FeatureCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Memba.Onboarding
  alias Memba.Onboarding.Request
  alias Memba.Repo

  test "staff requests index uses the operations page treatment", %{conn: conn} do
    {:ok, _view, initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    html = LazyHTML.from_fragment(initial_html)

    assert_selector_exists(html, "#admin-requests-index[data-admin-page='requests']")
    assert_selector_exists(html, "#admin-requests-summary")
    assert_selector_exists(html, "#admin-requests-toolbar")
    assert_selector_exists(html, "#admin-requests-inbox-card")
    assert_selector_exists(html, "#admin-requests-table[aria-label='Active onboarding requests']")
    assert_selector_exists(html, "#admin-requests-empty")
    assert_selector_exists(html, "#admin-nav-requests[href='/admin/requests']")
    refute initial_html =~ "Browser acceptance harness"
  end

  test "staff requests index lists active requests with details and triage actions", %{conn: conn} do
    newest = request_fixture("Newest Paddlers", requester_name: "Newer Requester")
    oldest = request_fixture("Oldest Canoe Club", requester_name: "Older Applicant")
    rejected = request_fixture("Rejected Paddlers")
    converted = request_fixture("Converted Paddlers")

    update_inserted_at(newest, ~U[2026-06-01 12:00:00.000000Z])
    update_inserted_at(oldest, ~U[2026-06-01 10:00:00.000000Z])
    update_inserted_at(rejected, ~U[2026-06-01 09:00:00.000000Z])
    update_inserted_at(converted, ~U[2026-06-01 08:00:00.000000Z])

    assert {:ok, %Request{status: "rejected"}} =
             Onboarding.reject_request(rejected.request_id, %{
               internal_rejection_notes: "Not a fit."
             })

    assert {:ok, %Request{status: "converted"}} =
             Onboarding.convert_request(converted.request_id, %{
               converted_club_id: Memba.ID.generate(:club),
               converted_person_id: Memba.ID.generate(:person),
               converted_membership_id: Memba.ID.generate(:membership)
             })

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    assert has_element?(view, "#admin-requests-active-count", "2")

    html =
      view
      |> render()
      |> LazyHTML.from_fragment()

    assert row_ids(html) == [oldest.request_id, newest.request_id]

    assert text_for(
             html,
             "#request-row-#{oldest.request_id} [data-testid='admin-request-requester']"
           ) =~
             "Older Applicant"

    assert text_for(html, "#request-row-#{oldest.request_id}") =~
             oldest.requester_email

    assert text_for(html, "#request-row-#{oldest.request_id} [data-testid='admin-request-club']") =~
             "Oldest Canoe Club"

    assert text_for(html, "#request-row-#{oldest.request_id} [data-testid='admin-request-note']") =~
             oldest.note

    assert text_for(
             html,
             "#request-row-#{oldest.request_id} [data-testid='admin-request-submitted-at']"
           ) =~ "2026-06-01 10:00:00 UTC"

    assert_selector_exists(
      html,
      "#reject-request-#{oldest.request_id}[type='button'][data-admin-request-action='reject'][data-request-id='#{oldest.request_id}']"
    )

    assert_selector_exists(
      html,
      "#convert-request-#{oldest.request_id}[type='button'][data-admin-request-action='convert'][data-request-id='#{oldest.request_id}']"
    )

    refute_selector_exists(html, "#request-row-#{rejected.request_id}")
    refute_selector_exists(html, "#request-row-#{converted.request_id}")
  end

  defp request_fixture(club_name, opts \\ []) do
    unique = System.unique_integer([:positive])
    requester_name = Keyword.get(opts, :requester_name, "Requester #{unique}")

    {:ok, request} =
      Onboarding.create_request(%{
        requester_name: requester_name,
        requester_email: "requester-#{unique}@example.com",
        requested_club_name: club_name,
        note: "Please onboard #{club_name}."
      })

    request
  end

  defp update_inserted_at(%Request{} = request, inserted_at) do
    Repo.update_all(
      from(onboarding_request in Request,
        where: onboarding_request.request_id == ^request.request_id
      ),
      set: [inserted_at: inserted_at, updated_at: inserted_at]
    )
  end

  defp row_ids(html) do
    html
    |> LazyHTML.query("[data-testid='admin-request-row']")
    |> LazyHTML.attribute("data-request-id")
  end

  defp text_for(html, selector) do
    html
    |> LazyHTML.query(selector)
    |> LazyHTML.text()
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp refute_selector_exists(html, selector) do
    refute html |> LazyHTML.query(selector) |> Enum.any?(), "Did not expect selector #{selector}"
  end
end
