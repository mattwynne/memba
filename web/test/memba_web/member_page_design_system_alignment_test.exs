defmodule MembaWeb.MemberPageDesignSystemAlignmentTest do
  @moduledoc """
  Structural guardrails for the member design-system migration.

  These source scans intentionally complement rendered component tests and the
  gallery-walk screenshots. They catch regressions back to bespoke member-page
  styling, hardcoded colours, or the removed white-label layer, but they are not a
  substitute for semantic rendering assertions or visual review.
  """

  use ExUnit.Case, async: true

  @member_page_files [
    "lib/memba_web/controllers/page_html/club.html.heex",
    "lib/memba_web/controllers/page_html/message.html.heex",
    "lib/memba_web/live/member_invitation_live/new.ex",
    "lib/memba_web/live/member_message_live/new.ex",
    "lib/memba_web/live/public_club_page_live.ex"
  ]

  @hardcoded_hex ~r/#[0-9A-Fa-f]{3}(?:[0-9A-Fa-f]{3})?(?:[0-9A-Fa-f]{2})?/

  @legacy_member_palette ~r/\b(?:bg|text|border|ring|decoration|placeholder|focus:border|focus:ring)-(?:blue|emerald|rose|sky|slate)-[0-9]/

  @expected_component_usage [
    {"club home template", "lib/memba_web/controllers/page_html/club.html.heex",
     ["<.button", "<.avatar"]},
    {"message detail template", "lib/memba_web/controllers/page_html/message.html.heex",
     ["<.button"]},
    {"member invitation LiveView", "lib/memba_web/live/member_invitation_live/new.ex",
     ["<.button", "<.avatar"]},
    {"compose LiveView", "lib/memba_web/live/member_message_live/new.ex",
     ["<.button", "<.avatar"]},
    {"public club page LiveView", "lib/memba_web/live/public_club_page_live.ex", ["<.button"]},
    {"club site layout", :club_site, ["app-frame", "app-card", "app-bar"]}
  ]

  test "member page sources use theme tokens rather than hardcoded hex or legacy palette utilities" do
    for {label, source} <- member_page_sources() do
      refute source =~ @hardcoded_hex,
             "#{label} contains a hardcoded hex colour; use a Memba token or daisyUI class"

      refute source =~ "--club-site-",
             "#{label} contains legacy club-site theming; use the canonical Memba theme"

      refute source =~ @legacy_member_palette,
             "#{label} contains a legacy Tailwind colour-family utility; use a Memba token or daisyUI class"
    end
  end

  test "member page sources call shared design-system components and shell classes" do
    for {label, source_ref, required_components} <- @expected_component_usage do
      source = source_for(source_ref)

      for component_call <- required_components do
        assert source =~ component_call,
               "#{label} should render #{component_call} from the shared design system"
      end
    end
  end

  defp member_page_sources do
    file_sources =
      Enum.map(@member_page_files, fn path ->
        {path, File.read!(web_path(path))}
      end)

    [{"MembaWeb.Layouts.club_site", club_site_source()} | file_sources]
  end

  defp source_for(:club_site), do: club_site_source()
  defp source_for(path), do: File.read!(web_path(path))

  defp club_site_source do
    source = File.read!(web_path("lib/memba_web/components/layouts.ex"))

    [template] =
      Regex.run(
        ~r/def club_site\(assigns\) do\s+~H"""\n(.*?)\n\s+"""\n\s+end/s,
        source,
        capture: :all_but_first
      )

    template
  end

  defp web_path(path), do: Path.expand("../../#{path}", __DIR__)
end
