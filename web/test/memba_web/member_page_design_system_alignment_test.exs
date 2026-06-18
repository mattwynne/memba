defmodule MembaWeb.MemberPageDesignSystemAlignmentTest do
  use ExUnit.Case, async: true

  @member_page_files [
    "lib/memba_web/controllers/page_html/club.html.heex",
    "lib/memba_web/controllers/page_html/message.html.heex",
    "lib/memba_web/live/member_message_live/new.ex",
    "lib/memba_web/live/public_club_page_live.ex"
  ]

  @hardcoded_hex ~r/#[0-9A-Fa-f]{3}(?:[0-9A-Fa-f]{3})?(?:[0-9A-Fa-f]{2})?/

  @legacy_member_palette ~r/\b(?:bg|text|border|ring|decoration|placeholder|focus:border|focus:ring)-(?:blue|emerald|rose|sky|slate)-[0-9]/

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

  defp member_page_sources do
    file_sources =
      Enum.map(@member_page_files, fn path ->
        {path, File.read!(web_path(path))}
      end)

    [{"MembaWeb.Layouts.club_site", club_site_source()} | file_sources]
  end

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
