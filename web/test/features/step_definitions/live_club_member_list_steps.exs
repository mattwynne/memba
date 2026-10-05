defmodule Memba.Cucumber.LiveClubMemberListSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions
  import Phoenix.ConnTest, only: [get: 2]
  import Phoenix.LiveViewTest, only: [live: 2]

  alias Memba.Accounts
  alias Memba.Membership
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @endpoint MembaWeb.Endpoint
  @club_name "Kootenay Mountaineering Club"
  @viewer_name "Bob"
  @joining_member_name "Alice"

  step "Bob is viewing the Kootenay Mountaineering Club member list", context do
    club_id = fetch_club_id!(context)
    viewer = fetch_person!(context, @viewer_name)
    club = Membership.get_club(club_id) || flunk("Expected #{@club_name} to exist")
    %{host: host} = club |> ClubSite.url() |> URI.parse()

    conn =
      Phoenix.ConnTest.build_conn()
      |> PhoenixTest.put_endpoint(MembaWeb.Endpoint)
      |> Map.put(:host, host)
      |> Plug.Test.init_test_session(%{
        IdentityAuth.identity_session_key() => Accounts.normalize_email(viewer.email)
      })

    assert {:ok, view, _html} = live(conn, "/members")

    assert Phoenix.LiveViewTest.has_element?(
             view,
             "#club-member-#{viewer.person_id}",
             @viewer_name
           )

    refute Phoenix.LiveViewTest.has_element?(
             view,
             "#active-members-list [data-testid='club-member-row']",
             @joining_member_name
           )

    Map.put(context, :live_club_member_list, %{
      club_id: club_id,
      view: view,
      viewer_person_id: viewer.person_id
    })
  end

  step "Alice becomes a member of Kootenay Mountaineering Club", context do
    %{club_id: club_id, view: view} = live_member_list!(context)
    joining_member = fetch_person!(context, @joining_member_name)
    joining_member_selector = "#club-member-#{joining_member.person_id}"

    refute Phoenix.LiveViewTest.has_element?(view, joining_member_selector)

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: joining_member.person_id
               },
               consistency: :strong
             )

    context
    |> update_context_map(
      :memberships,
      {@club_name, @joining_member_name},
      membership_id
    )
    |> Map.update!(:live_club_member_list, fn member_list ->
      Map.merge(member_list, %{
        joining_member_id: joining_member.person_id,
        membership_id: membership_id
      })
    end)
  end

  step "Bob should see Alice appear in the member list automatically", context do
    %{
      view: view,
      joining_member_id: joining_member_id
    } = live_member_list!(context)

    assert Phoenix.LiveViewTest.has_element?(
             view,
             "#club-member-#{joining_member_id}",
             @joining_member_name
           )

    context
  end

  defp fetch_club_id!(context) do
    case get_in(context, [:clubs, @club_name]) do
      club_id when is_binary(club_id) -> club_id
      %{club_id: club_id} when is_binary(club_id) -> club_id
      _missing -> flunk("Expected #{@club_name} to be present in the scenario context")
    end
  end

  defp fetch_person!(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id, email: email} = person
      when is_binary(person_id) and is_binary(email) ->
        person

      _missing ->
        flunk("Expected #{person_name} to be present in the scenario context")
    end
  end

  defp live_member_list!(context) do
    case Map.fetch(context, :live_club_member_list) do
      {:ok, %{view: %Phoenix.LiveViewTest.View{}} = member_list} ->
        member_list

      _missing ->
        flunk("Expected Bob's connected club member list in the scenario context")
    end
  end

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end
end
