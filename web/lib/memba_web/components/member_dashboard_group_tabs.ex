defmodule MembaWeb.MemberDashboardGroupTabs do
  @moduledoc """
  Tab navigation for the member dashboard group view.

  The component owns the relationship between the active tab and the contextual
  action shown beside the tab list. Group metadata stays in the page header;
  tab-scoped calls to action live here.
  """
  use Phoenix.Component

  attr :active_tab, :string, required: true, values: ~w(conversations members)
  attr :conversations_path, :string, required: true
  attr :members_path, :string, required: true

  slot :conversations_action, doc: "action rendered only when the conversations tab is active"
  slot :members_action, doc: "action rendered only when the members tab is active"

  def group_tabs(assigns) do
    assigns = assign(assigns, :active_action, active_action(assigns))

    ~H"""
    <div id="member-section-tabs" class="section-tabs">
      <div
        id="member-section-tabs-list"
        class="section-tabs__list"
        role="tablist"
        aria-label="Club home sections"
        aria-orientation="horizontal"
        phx-hook=".SectionTabs"
      >
        <.link
          id="member-section-tab-conversations"
          patch={@conversations_path}
          class={tab_class(@active_tab, "conversations")}
          data-tab="conversations"
          role="tab"
          aria-selected={tab_selected(@active_tab, "conversations")}
          aria-controls="member-section-panel-conversations"
          tabindex={tab_index(@active_tab, "conversations")}
        >
          Conversations
        </.link>
        <.link
          id="member-section-tab-members"
          patch={@members_path}
          class={tab_class(@active_tab, "members")}
          data-tab="members"
          role="tab"
          aria-selected={tab_selected(@active_tab, "members")}
          aria-controls="member-section-panel-members"
          tabindex={tab_index(@active_tab, "members")}
        >
          Members
        </.link>
      </div>
      <div id="member-section-tabs-action" class="section-tabs__action">
        {render_slot(@active_action)}
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".SectionTabs">
      export default {
        mounted() {
          this.handleKeydown = event => {
            if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return

            const tabs = Array.from(this.el.querySelectorAll("[role='tab']"))
            const currentIndex = tabs.indexOf(event.target)

            if (currentIndex === -1) return

            let nextIndex

            switch (event.key) {
              case "ArrowRight":
                nextIndex = (currentIndex + 1) % tabs.length
                break
              case "ArrowLeft":
                nextIndex = (currentIndex - 1 + tabs.length) % tabs.length
                break
              case "Home":
                nextIndex = 0
                break
              case "End":
                nextIndex = tabs.length - 1
                break
              default:
                return
            }

            event.preventDefault()
            tabs[nextIndex].click()
            tabs[nextIndex].focus()
          }

          this.el.addEventListener("keydown", this.handleKeydown)
        },

        destroyed() {
          this.el.removeEventListener("keydown", this.handleKeydown)
        }
      }
    </script>
    """
  end

  defp active_action(%{active_tab: "conversations", conversations_action: action}), do: action
  defp active_action(%{active_tab: "members", members_action: action}), do: action

  defp tab_class(active_tab, tab) do
    ["section-tab", active_tab == tab && "is-active"]
  end

  defp tab_selected(active_tab, tab), do: to_string(active_tab == tab)

  defp tab_index(active_tab, tab) do
    if active_tab == tab, do: "0", else: "-1"
  end
end
