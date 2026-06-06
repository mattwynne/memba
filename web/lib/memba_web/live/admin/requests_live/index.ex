defmodule MembaWeb.Admin.RequestsLive.Index do
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main id="admin-requests-index" data-admin-page="requests" class="space-y-6 p-6">
        <.admin_page_header
          eyebrow="Requests"
          title="Requests"
          description="Review account requests from club organisers before creating clubs, memberships, or sign-in access."
        />

        <section
          id="admin-requests-route-ready"
          class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm"
        >
          <h2 class="text-base font-semibold text-[#15201c]">Staff request triage</h2>
          <p class="mt-2 text-sm leading-6 text-[#4b5a55]">
            This staff-only page is ready for the active request inbox and review actions.
          </p>
        </section>
      </main>
    </Layouts.admin>
    """
  end
end
