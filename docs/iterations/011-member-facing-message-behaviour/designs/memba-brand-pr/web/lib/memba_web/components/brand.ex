defmodule MembaWeb.Brand do
  @moduledoc """
  The Memba sprig mark + wordmark, as HEEx function components.

  The sprig is *responsive*: use `variant={:line}` (the default) at 28px and
  above, and `variant={:solid}` at 24px and below (favicons, dense table
  rows). Both share the exact same silhouette, so the swap is invisible.

  The foliage uses `currentColor`, so colour it with a Tailwind text class
  (e.g. `text-sage-600`, or `text-cream` when reversed on sage). The apricot
  bud stays fixed.
  """
  use Phoenix.Component

  attr :variant, :atom, default: :line, values: [:line, :solid]
  attr :class, :string, default: "h-7 w-7 text-sage-600"
  attr :rest, :global, include: ~w(role aria-label)

  def sprig(assigns) do
    ~H"""
    <svg viewBox="0 0 64 64" fill="none" class={@class} aria-hidden="true" {@rest}>
      <%= if @variant == :solid do %>
        <path d="M32 51 C32 43 32 36 32 18" stroke="currentColor" stroke-width="4.8" stroke-linecap="round" />
        <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="currentColor" />
        <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="currentColor" />
        <circle cx="32" cy="15" r="3.7" fill="#d2925a" />
      <% else %>
        <path d="M32 51 C32 43 32 36 32 18" stroke="currentColor" stroke-width="3" stroke-linecap="round" />
        <path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" stroke="currentColor" stroke-width="2.6" stroke-linejoin="round" />
        <path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" stroke="currentColor" stroke-width="2.6" stroke-linejoin="round" />
        <circle cx="32" cy="15" r="3" fill="#d2925a" />
      <% end %>
    </svg>
    """
  end

  @doc "Full lockup: sprig + lowercase wordmark."
  attr :class, :string, default: nil
  attr :mark_class, :string, default: "h-7 w-7 text-sage-600"

  def logo(assigns) do
    ~H"""
    <span class={["inline-flex items-center gap-2.5", @class]}>
      <.sprig class={@mark_class} />
      <span class="text-2xl font-semibold tracking-tight text-ink lowercase">memba</span>
    </span>
    """
  end
end
