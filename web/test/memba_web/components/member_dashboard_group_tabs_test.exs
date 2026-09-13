defmodule MembaWeb.MemberDashboardGroupTabsTest do
  use MembaWeb.ConnCase, async: true

  import MembaWeb.CoreComponents
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.MemberDashboardGroupTabs

  test "renders the conversations tab action as the only active contextual action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <MemberDashboardGroupTabs.group_tabs
        active_tab="conversations"
        conversations_path="/groups/grp_123"
        members_path="/groups/grp_123/members"
      >
        <:conversations_action>
          <.button
            id="member-section-action-new-message"
            href="/messages/new?group_id=grp_123"
            variant="primary"
            size="sm"
            data-section-action="conversations"
          >
            New message
          </.button>
        </:conversations_action>
        <:members_action>
          <.button
            id="member-section-action-invite-member"
            href="/members/invitations/new?group_id=grp_123"
            variant="primary"
            size="sm"
            data-section-action="members"
          >
            Invite member
          </.button>
        </:members_action>
      </MemberDashboardGroupTabs.group_tabs>
      """)

    assert_selector(html, "#member-section-tabs.section-tabs")

    assert_selector(
      html,
      "#member-section-tabs-list[role='tablist'][aria-orientation='horizontal']" <>
        "[phx-hook='MembaWeb.MemberDashboardGroupTabs.SectionTabs']"
    )

    assert_selector(
      html,
      "#member-section-tab-conversations.section-tab.is-active" <>
        "[href='/groups/grp_123'][data-phx-link='patch']" <>
        "[data-tab='conversations'][role='tab'][aria-selected='true']" <>
        "[aria-controls='member-section-panel-conversations'][tabindex='0']"
    )

    assert_selector(
      html,
      "#member-section-tab-members.section-tab" <>
        "[href='/groups/grp_123/members'][data-phx-link='patch']" <>
        "[data-tab='members'][role='tab'][aria-selected='false']" <>
        "[aria-controls='member-section-panel-members'][tabindex='-1']"
    )

    assert_selector(
      html,
      "#member-section-tabs-action.section-tabs__action " <>
        "#member-section-action-new-message.btn.btn-primary.btn-sm" <>
        "[data-section-action='conversations'][href='/messages/new?group_id=grp_123']"
    )

    refute_selector(html, "#member-section-action-invite-member")
  end

  test "renders the members tab action only when the members tab is active" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <MemberDashboardGroupTabs.group_tabs
        active_tab="members"
        conversations_path="/conversations"
        members_path="/members"
      >
        <:conversations_action>
          <.button id="member-section-action-new-message" href="/messages/new">
            New message
          </.button>
        </:conversations_action>
        <:members_action>
          <.button
            id="member-section-action-invite-member"
            href="/members/invitations/new"
            variant="primary"
            size="sm"
            data-section-action="members"
          >
            Invite member
          </.button>
        </:members_action>
      </MemberDashboardGroupTabs.group_tabs>
      """)

    assert_selector(
      html,
      "#member-section-tab-members.section-tab.is-active[aria-selected='true'][tabindex='0']"
    )

    assert_selector(
      html,
      "#member-section-tabs-action.section-tabs__action " <>
        "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
        "[data-section-action='members'][href='/members/invitations/new']"
    )

    refute_selector(html, "#member-section-action-new-message")
  end

  test "keeps the single action container empty when the active tab has no permitted action" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <MemberDashboardGroupTabs.group_tabs
        active_tab="members"
        conversations_path="/conversations"
        members_path="/members"
      >
        <:conversations_action>
          <.button id="member-section-action-new-message" href="/messages/new">
            New message
          </.button>
        </:conversations_action>
      </MemberDashboardGroupTabs.group_tabs>
      """)

    assert_selector(html, "#member-section-tabs-action.section-tabs__action")
    refute_selector(html, "#member-section-action-new-message")
    refute_selector(html, "#member-section-action-invite-member")
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component not to include selector #{inspect(selector)}"
  end
end
