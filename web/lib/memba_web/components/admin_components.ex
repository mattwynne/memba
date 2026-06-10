defmodule MembaWeb.AdminComponents do
  @moduledoc """
  Shared presentation components for the Memba staff operations area.
  """

  use Phoenix.Component

  import MembaWeb.CoreComponents

  attr :eyebrow, :string, default: nil
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :breadcrumb
  slot :actions

  def admin_page_header(assigns) do
    ~H"""
    <header class="-mx-6 -mt-6 border-b border-[#e6e3dc] bg-white px-6 py-6 sm:px-8">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div class="min-w-0 space-y-1.5">
          <div
            :if={@breadcrumb != []}
            class="mb-2 flex flex-wrap items-center gap-2 text-sm text-[#7d877f]"
          >
            {render_slot(@breadcrumb)}
          </div>
          <p :if={@eyebrow} class="text-sm font-medium text-[#15201c]">{@eyebrow}</p>
          <h1 class="text-3xl font-bold tracking-[-0.035em] text-[#15201c]">{@title}</h1>
          <p :if={@description} class="max-w-3xl text-sm leading-6 text-[#4b5a55]">
            {@description}
          </p>
        </div>
        <div :if={@actions != []} class="flex shrink-0 flex-wrap items-center gap-3">
          {render_slot(@actions)}
        </div>
      </div>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :search_placeholder, :string, default: nil
  attr :summary_label, :string, default: nil
  attr :summary_count, :any, default: nil
  attr :meta, :string, default: nil
  slot :chips
  slot :actions

  def admin_toolbar(assigns) do
    ~H"""
    <section id={@id} class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <div class="flex flex-1 flex-col gap-3 sm:flex-row sm:items-center">
        <div
          :if={@search_placeholder}
          class="flex h-10 w-full items-center gap-2 rounded-lg border border-[#d6d2c8] bg-white px-3 text-sm text-[#7d877f] shadow-sm sm:max-w-sm"
          aria-hidden="true"
        >
          <.icon name="hero-magnifying-glass" class="size-4 bg-[#7d877f]" />
          <span>{@search_placeholder}</span>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span
            :if={@summary_label}
            class="inline-flex h-9 items-center gap-1 rounded-full bg-[#1f4842] px-3.5 text-sm font-medium text-white"
          >
            <span>{@summary_label}</span>
            <span :if={not is_nil(@summary_count)} class="text-white/75">{@summary_count}</span>
          </span>
          {render_slot(@chips)}
        </div>
      </div>
      <p :if={@meta} class="text-sm font-medium text-[#7d877f]">{@meta}</p>
      <div :if={@actions != []} class="flex shrink-0 flex-wrap items-center gap-2">
        {render_slot(@actions)}
      </div>
    </section>
    """
  end

  attr :label, :string, required: true
  attr :count, :any, default: nil

  def admin_pill(assigns) do
    ~H"""
    <span class="inline-flex h-9 items-center gap-1 rounded-full border border-[#d6d2c8] bg-white px-3.5 text-sm font-medium text-[#15201c] shadow-sm">
      <span>{@label}</span>
      <span :if={not is_nil(@count)} class="text-[#7d877f]">{@count}</span>
    </span>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :inner_block, required: true

  def admin_table_card(assigns) do
    ~H"""
    <section id={@id} class="overflow-hidden rounded-xl border border-[#e0ddd4] bg-white shadow-sm">
      <div :if={@title || @description} class="border-b border-[#e6e3dc] px-4 py-4 sm:px-5">
        <h2 class="text-base font-semibold text-[#15201c]">{@title}</h2>
        <p :if={@description} class="mt-1 text-sm text-[#7d877f]">{@description}</p>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :label, :string, required: true
  attr :tone, :string, default: "neutral"
  attr :rest, :global

  def admin_status_chip(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold",
        status_chip_class(@tone)
      ]}
      {@rest}
    >
      <span class="size-1.5 rounded-full bg-current"></span>
      {@label}
    </span>
    """
  end

  attr :initials, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :tone, :string, default: "green"
  attr :link, :string, default: nil
  attr :link_id, :string, default: nil
  attr :testid, :string, default: nil
  attr :aria_label, :string, default: nil

  def admin_identity_cell(assigns) do
    ~H"""
    <div class="flex items-center gap-3">
      <div class={[
        "flex size-8 shrink-0 items-center justify-center rounded-lg text-xs font-bold",
        avatar_class(@tone)
      ]}>
        {@initials}
      </div>
      <div class="min-w-0">
        <.link
          :if={@link}
          id={@link_id}
          navigate={@link}
          data-testid={@testid}
          aria-label={@aria_label}
          class="block truncate font-semibold text-[#15201c] transition hover:text-[#1f4842]"
        >
          {@title}
        </.link>
        <p :if={!@link} data-testid={@testid} class="truncate font-semibold text-[#15201c]">
          {@title}
        </p>
        <p :if={@subtitle} class="mt-0.5 truncate text-xs text-[#7d877f]">{@subtitle}</p>
      </div>
    </div>
    """
  end

  defp status_chip_class("good"), do: "bg-[#e6ece4] text-[#315d3d]"
  defp status_chip_class("info"), do: "bg-[#e4ebef] text-[#345365]"
  defp status_chip_class("warn"), do: "bg-[#f3ecd8] text-[#7a5416]"
  defp status_chip_class("bad"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp status_chip_class(_tone), do: "bg-[#eef0ec] text-[#4b5a55]"

  defp avatar_class("purple"), do: "bg-[#7c5c8f] text-white"
  defp avatar_class("blue"), do: "bg-[#2d7896] text-white"
  defp avatar_class("orange"), do: "bg-[#b66a34] text-white"
  defp avatar_class("muted"), do: "bg-[#d9d6cb] text-[#15201c]"
  defp avatar_class(_tone), do: "bg-[#1f5a52] text-white"
end
