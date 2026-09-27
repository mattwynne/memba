defmodule MembaWeb.MemberDashboardGroupTabsTest do
  use MembaWeb.ConnCase, async: true

  import MembaWeb.CoreComponents
  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.MemberDashboardGroupTabs

  test "renders the conversations section action as the only active contextual action" do
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
      "nav#member-section-tabs-list.section-tabs__list[aria-label='Group sections']"
    )

    assert_selector(
      html,
      "#member-section-tab-conversations.section-tab.is-active" <>
        "[href='/groups/grp_123'][data-phx-link='patch']" <>
        "[data-tab='conversations'][aria-current='page']"
    )

    assert_selector(
      html,
      "#member-section-tab-members.section-tab" <>
        "[href='/groups/grp_123/members'][data-phx-link='patch']" <>
        "[data-tab='members']"
    )

    refute_selector(html, "#member-section-tabs-list[role='tablist']")
    refute_selector(html, "#member-section-tabs-list[phx-hook]")
    refute_selector(html, "#member-section-tab-conversations[role='tab']")
    refute_selector(html, "#member-section-tab-conversations[aria-selected]")
    refute_selector(html, "#member-section-tab-conversations[aria-controls]")
    refute_selector(html, "#member-section-tab-members[aria-current]")
    refute_selector(html, "#member-section-tab-members[role='tab']")
    refute_selector(html, "#member-section-tab-members[aria-selected]")
    refute_selector(html, "#member-section-tab-members[aria-controls]")
    refute_selector(html, "#member-section-tab-members[tabindex]")

    assert_selector(
      html,
      "#member-section-tabs-action.section-tabs__action " <>
        "#member-section-action-new-message.btn.btn-primary.btn-sm" <>
        "[data-section-action='conversations'][href='/messages/new?group_id=grp_123']"
    )

    refute_selector(html, "#member-section-action-invite-member")
  end

  test "renders the members section action only when the members section is active" do
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
      "#member-section-tab-members.section-tab.is-active[aria-current='page']"
    )

    assert_selector(
      html,
      "#member-section-tabs-action.section-tabs__action " <>
        "#member-section-action-invite-member.btn.btn-primary.btn-sm" <>
        "[data-section-action='members'][href='/members/invitations/new']"
    )

    refute_selector(html, "#member-section-action-new-message")
  end

  test "keeps the single action container empty when the active section has no permitted action" do
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

  test "renders the Members-only section composition when conversations are unavailable" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <MemberDashboardGroupTabs.group_tabs
        active_tab="members"
        conversations_path="/groups/grp_123"
        members_path="/groups/grp_123/members"
        show_conversations={false}
      />
      """)

    assert_selector(
      html,
      "nav#member-section-tabs-list[aria-label='Group sections'] " <>
        "#member-section-tab-members[href='/groups/grp_123/members']" <>
        "[aria-current='page']"
    )

    refute_selector(html, "#member-section-tab-members[role='tab']")
    refute_selector(html, "#member-section-tab-members[aria-selected]")
    refute_selector(html, "#member-section-tab-members[aria-controls]")
    refute_selector(html, "#member-section-tab-members[tabindex]")
    refute_selector(html, "#member-section-tab-conversations")
    assert_selector(html, "#member-section-tabs-action.section-tabs__action")
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
