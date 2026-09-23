defmodule MembaWeb.ConversationAccessBoundaryTest do
  use ExUnit.Case, async: true

  @web_root Path.expand("../..", __DIR__)

  @member_conversation_sources [
    "lib/memba_web/member_dashboard_presentation.ex",
    "lib/memba_web/member_message_detail.ex",
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

    assert source =~ "Membership.list_discoverable_groups_for_member("
    assert source =~ "Membership.list_active_groups_for_member_authoritatively("
    assert source =~ "Messaging.list_conversations_for_group("
  end

  test "detail and compose access use public context authorization boundaries" do
    detail_source = read_source!("lib/memba_web/member_message_detail.ex")
    compose_source = read_source!("lib/memba_web/live/member_message_live/new.ex")

    assert detail_source =~ "Messaging.member_has_conversation_access?("
    assert compose_source =~ "Membership.list_active_groups_for_member("
  end

  defp read_source!(relative_path) do
    @web_root
    |> Path.join(relative_path)
    |> File.read!()
  end
end
