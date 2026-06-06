defmodule MembaWeb.Admin.RequestsLive.IndexTest do
  use MembaWeb.FeatureCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  alias Memba.Membership
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Onboarding
  alias Memba.Onboarding.Request
  alias Memba.Repo

  setup context do
    set_swoosh_global(context)
  end

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

  test "staff can reject an active request with required internal notes and no requester email",
       %{
         conn: conn
       } do
    request = request_fixture("Rejectable Paddlers", requester_name: "Robin Requester")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff("pat@memba.io")
      |> live(~p"/admin/requests")

    assert has_element?(view, "#request-row-#{request.request_id}")
    assert has_element?(view, "#admin-requests-active-count", "1")
    refute has_element?(view, "#reject-request-panel-#{request.request_id}")

    view
    |> element("#reject-request-#{request.request_id}")
    |> render_click()

    assert has_element?(view, "#reject-request-panel-#{request.request_id}")
    assert has_element?(view, "#reject-request-form-#{request.request_id}")

    blank_notes_html =
      view
      |> form("#reject-request-form-#{request.request_id}",
        rejection: %{internal_rejection_notes: " "}
      )
      |> render_submit()

    assert blank_notes_html =~ "can&#39;t be blank"
    assert has_element?(view, "#request-row-#{request.request_id}")
    assert Repo.get!(Request, request.request_id).status == "active"

    view
    |> form("#reject-request-form-#{request.request_id}",
      rejection: %{internal_rejection_notes: " Not a real club. "}
    )
    |> render_submit()

    refute has_element?(view, "#request-row-#{request.request_id}")
    refute has_element?(view, "#reject-request-panel-#{request.request_id}")
    assert has_element?(view, "#admin-requests-active-count", "0")

    rejected = Repo.get!(Request, request.request_id)

    assert rejected.status == "rejected"
    assert rejected.internal_rejection_notes == "Not a real club."
    assert rejected.triaged_by_staff_email == "pat@memba.io"
    assert %DateTime{} = rejected.triaged_at
    assert is_nil(rejected.converted_club_id)

    assert_no_email_sent()
  end

  test "staff can prepare conversion with a generated editable slug using shared club rules", %{
    conn: conn
  } do
    request = request_fixture("West Coast Paddlers", requester_name: "Robin Requester")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    view
    |> element("#convert-request-#{request.request_id}")
    |> render_click()

    assert has_element?(view, "#convert-request-panel-#{request.request_id}")
    assert has_element?(view, "#convert-request-form-#{request.request_id}")

    html = render(view)

    assert input_value(html, "#convert-request-club-name-#{request.request_id}") ==
             "West Coast Paddlers"

    assert input_value(html, "#convert-request-club-slug-#{request.request_id}") ==
             "west-coast-paddlers"

    assert feedback_status(html, "#convert-request-club-slug-feedback-#{request.request_id}") ==
             "available"

    override_html =
      view
      |> form("#convert-request-form-#{request.request_id}",
        club: %{name: "West Coast Paddlers", slug: "wcp"}
      )
      |> render_change()

    assert input_value(override_html, "#convert-request-club-slug-#{request.request_id}") == "wcp"

    preserved_override_html =
      view
      |> form("#convert-request-form-#{request.request_id}",
        club: %{name: "West Coast Paddle Collective", slug: "wcp"}
      )
      |> render_change()

    assert input_value(
             preserved_override_html,
             "#convert-request-club-slug-#{request.request_id}"
           ) ==
             "wcp"

    invalid_html =
      view
      |> form("#convert-request-form-#{request.request_id}",
        club: %{name: "West Coast Paddle Collective", slug: "West-Coast"}
      )
      |> render_change()

    assert feedback_status(
             invalid_html,
             "#convert-request-club-slug-feedback-#{request.request_id}"
           ) ==
             "invalid"

    assert attribute_value(
             invalid_html,
             "#confirm-convert-request-#{request.request_id}",
             "disabled"
           ) ==
             ""

    assert input_value(invalid_html, "#convert-request-club-slug-#{request.request_id}") ==
             "West-Coast"

    view
    |> element("#cancel-convert-request-#{request.request_id}")
    |> render_click()

    refute has_element?(view, "#convert-request-panel-#{request.request_id}")
  end

  test "conversion preparation reports taken slugs with the same availability rule as club creation",
       %{conn: conn} do
    assert :ok =
             Membership.create_club(
               %{
                 club_id: Memba.ID.generate(:club),
                 name: "Existing West Coast Paddlers",
                 slug: "west-coast-paddlers"
               },
               consistency: :strong
             )

    request = request_fixture("West Coast Paddlers", requester_name: "Robin Requester")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    view
    |> element("#convert-request-#{request.request_id}")
    |> render_click()

    html = render(view)

    assert input_value(html, "#convert-request-club-slug-#{request.request_id}") ==
             "west-coast-paddlers"

    assert feedback_status(html, "#convert-request-club-slug-feedback-#{request.request_id}") ==
             "taken"

    assert attribute_value(html, "#confirm-convert-request-#{request.request_id}", "disabled") ==
             ""
  end

  test "staff can convert an active request into a club and active first member", %{conn: conn} do
    request = request_fixture("Convertible Paddlers", requester_name: "Robin Requester")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff("pat@memba.io")
      |> live(~p"/admin/requests")

    assert has_element?(view, "#request-row-#{request.request_id}")
    assert has_element?(view, "#admin-requests-active-count", "1")

    view
    |> element("#convert-request-#{request.request_id}")
    |> render_click()

    view
    |> form("#convert-request-form-#{request.request_id}",
      club: %{name: "Convertible Paddlers", slug: "convertible-paddlers"}
    )
    |> render_submit()

    refute has_element?(view, "#request-row-#{request.request_id}")
    refute has_element?(view, "#convert-request-panel-#{request.request_id}")
    assert has_element?(view, "#admin-requests-active-count", "0")
    assert has_element?(view, "#flash-info", "Converted request for Convertible Paddlers.")

    converted_request = Repo.get!(Request, request.request_id)
    assert converted_request.status == "converted"
    assert converted_request.triaged_by_staff_email == "pat@memba.io"
    assert %DateTime{} = converted_request.triaged_at

    club = Membership.get_club(converted_request.converted_club_id)
    person = Membership.get_person(converted_request.converted_person_id)
    membership = Repo.get!(MembershipProjection, converted_request.converted_membership_id)

    assert club.name == "Convertible Paddlers"
    assert club.slug == "convertible-paddlers"
    assert person.name == "Robin Requester"
    assert person.email == request.requester_email
    assert membership.club_id == club.club_id
    assert membership.person_id == person.person_id
    assert membership.active
  end

  test "conversion preparation refreshes the inbox when the request is no longer active", %{
    conn: conn
  } do
    request = request_fixture("Already Converted Paddlers", requester_name: "Robin Requester")

    {:ok, view, _initial_html} =
      conn
      |> sign_in_staff()
      |> live(~p"/admin/requests")

    assert has_element?(view, "#request-row-#{request.request_id}")

    assert {:ok, %Request{status: "converted"}} =
             Onboarding.convert_request(request.request_id, %{
               converted_club_id: Memba.ID.generate(:club),
               converted_person_id: Memba.ID.generate(:person),
               converted_membership_id: Memba.ID.generate(:membership)
             })

    view
    |> element("#convert-request-#{request.request_id}")
    |> render_click()

    refute has_element?(view, "#convert-request-panel-#{request.request_id}")
    refute has_element?(view, "#request-row-#{request.request_id}")
    assert has_element?(view, "#admin-requests-active-count", "0")
    assert has_element?(view, "#flash-error", "That request is no longer active.")
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

  defp input_value(html, selector) do
    assert [value] = attributes(html, selector, "value")
    value
  end

  defp feedback_status(html, selector) do
    assert [status] = attributes(html, selector, "data-status")
    status
  end

  defp attribute_value(html, selector, attribute) do
    assert [value] = attributes(html, selector, attribute)
    value
  end

  defp attributes(html, selector, attribute) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(attribute)
  end

  defp assert_selector_exists(html, selector) do
    assert html |> LazyHTML.query(selector) |> Enum.any?(), "Expected selector #{selector}"
  end

  defp refute_selector_exists(html, selector) do
    refute html |> LazyHTML.query(selector) |> Enum.any?(), "Did not expect selector #{selector}"
  end
end
