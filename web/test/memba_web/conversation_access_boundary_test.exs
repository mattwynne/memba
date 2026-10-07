defmodule MembaWeb.ConversationAccessBoundaryTest do
  use ExUnit.Case, async: true

  @web_root Path.expand("../..", __DIR__)

  @member_conversation_sources [
    "lib/memba_web/member_dashboard_presentation.ex",
    "lib/memba_web/member_dashboard_query.ex",
    "lib/memba_web/member_message_detail.ex",
    "lib/memba_web/member_message_detail_query.ex",
    "lib/memba_web/member_message_compose_query.ex",
    "lib/memba_web/member_message_delivery_query.ex",
    "lib/memba_web/live/member_dashboard_live.ex",
    "lib/memba_web/live/member_message_live/new.ex",
    "lib/memba_web/live/member_message_live/show.ex",
    "lib/memba_web/live/member_message_delivery_live/show.ex"
  ]

  test "member conversation surfaces do not query context projections directly" do
    Enum.each(@member_conversation_sources, fn relative_path ->
      source = read_source!(relative_path)

      refute source =~ "Memba.Membership.Projections",
             "#{relative_path} must use the public Membership API"

      refute source =~ "Memba.Messaging.Projections",
             "#{relative_path} must use the public Messaging API"

      refute source =~ "import Ecto.Query",
             "#{relative_path} must not build projection queries"

      refute source =~ "alias Memba.Repo",
             "#{relative_path} must not access projection storage"

      refute source =~ ~r/\bRepo\./,
             "#{relative_path} must not access projection storage"
    end)
  end

  test "dashboard access keeps discovery and participation as separate public queries" do
    source = read_source!("lib/memba_web/member_dashboard_presentation.ex")

    assert source =~ "ClubGroupQueries.list_discoverable_groups_for_member("

    assert source =~
             "AuthoritativeMembershipQueries.list_active_groups_for_member_authoritatively("

    assert source =~ "AuthoritativeMembershipQueries.active_member_of_group_authoritatively?("
    assert source =~ "ConversationListing.list_for_group("
    assert source =~ "PersonQueries.find_member_for_email("
    refute source =~ "Membership.find_member_for_email("
  end

  test "detail and compose access use public context authorization boundaries" do
    detail_source = read_source!("lib/memba_web/member_message_detail.ex")
    compose_query_source = read_source!("lib/memba_web/member_message_compose_query.ex")
    compose_live_source = read_source!("lib/memba_web/live/member_message_live/new.ex")

    assert detail_source =~ "ConversationGroupAccessQueries.member_has_conversation_access?("
    assert compose_live_source =~ "MemberMessageComposeQuery.query()"
    assert compose_query_source =~ "ClubGroupQueries.list_active_groups_for_member("
  end

  test "stop-follow URL loads the club through the focused read boundary" do
    source = read_source!("lib/memba_web/controllers/conversation_follow_controller.ex")

    assert source =~ "ClubGroupQueries.get_club("
    refute source =~ "Membership.get_club("
  end

  test "scoped email member resolution lives in PersonQueries behind the facade" do
    facade = read_source!("lib/memba/membership.ex")
    query = read_source!("lib/memba/membership/person_queries.ex")

    assert facade =~ "do: PersonQueries.find_member_for_email(members, email)"
    assert query =~ "case get_person_by_email(email) do"
    assert query =~ "Enum.find(members, &(&1.id == person_id))"
  end

  defp read_source!(relative_path) do
    @web_root
    |> Path.join(relative_path)
    |> File.read!()
  end
end
