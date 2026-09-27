defmodule MembaWeb.MemberDashboardGroupTabs do
  @moduledoc """
  Section navigation for the member dashboard group view.

  The component owns the relationship between the active section link and the
  contextual action shown beside the section navigation. Group metadata stays in
  the page header; section-scoped calls to action live here.
  """
  use Phoenix.Component

  attr :active_tab, :string, required: true, values: ~w(conversations members)
  attr :conversations_path, :string, required: true
  attr :members_path, :string, required: true
  attr :show_conversations, :boolean, default: true

  slot :conversations_action, doc: "action rendered only when the conversations tab is active"
  slot :members_action, doc: "action rendered only when the members tab is active"

  def group_tabs(assigns) do
    assigns = assign(assigns, :active_action, active_action(assigns))

    ~H"""
    <div id="member-section-tabs" class="section-tabs">
      <nav
        id="member-section-tabs-list"
        class="section-tabs__list"
        aria-label="Group sections"
      >
        <.link
          :if={@show_conversations}
          id="member-section-tab-conversations"
          patch={@conversations_path}
          class={tab_class(@active_tab, "conversations")}
          data-tab="conversations"
          aria-current={current_section(@active_tab, "conversations")}
        >
          Conversations
        </.link>
        <.link
          id="member-section-tab-members"
          patch={@members_path}
          class={tab_class(@active_tab, "members")}
          data-tab="members"
          aria-current={current_section(@active_tab, "members")}
        >
          Members
        </.link>
      </nav>
      <div id="member-section-tabs-action" class="section-tabs__action">
        {render_slot(@active_action)}
      </div>
    </div>
    """
  end

  defp active_action(%{active_tab: "conversations", conversations_action: action}), do: action
  defp active_action(%{active_tab: "members", members_action: action}), do: action

  defp tab_class(active_tab, tab) do
    ["section-tab", active_tab == tab && "is-active"]
  end

  defp current_section(active_tab, tab) do
    if active_tab == tab, do: "page"
  end
end
