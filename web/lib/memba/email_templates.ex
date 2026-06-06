defmodule Memba.EmailTemplates do
  @moduledoc """
  Shared low-level helpers for rendering Memba's transactional email HTML.

  The helpers intentionally produce conservative, table-oriented markup with
  inline styles so the higher-level email modules can share one v2-compatible
  shell without depending on external CSS or browser-only layout features.
  """

  @canvas "#ece9e0"
  @paper "#ffffff"
  @line "#e6e3dc"
  @ink "#15201c"
  @ink_2 "#4b5a55"

  @doc """
  Render a complete v2-compatible email document around already-rendered card
  content.

  Dynamic text passed as `:title` and `:preheader` is HTML-escaped. The
  `:content` and optional `:footer` values are treated as trusted component
  HTML so callers can compose sections without double-escaping markup.
  """
  def render_shell(opts) when is_list(opts) do
    title = opts |> Keyword.fetch!(:title) |> escaped_text()
    preheader = opts |> Keyword.get(:preheader, "") |> escaped_text()
    content = Keyword.fetch!(opts, :content)
    footer = Keyword.get(opts, :footer, "")

    [
      """
      <!doctype html>
      <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="color-scheme" content="light only">
        <meta name="supported-color-schemes" content="light only">
        <title>#{title}</title>
        <style>
          body { margin:0; padding:0; width:100% !important; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; }
          table { border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt; }
          a { color:#1f4842; }
          @media only screen and (max-width:600px) {
            .container { width:100% !important; max-width:100% !important; border-radius:0 !important; }
            .gutter { padding-left:22px !important; padding-right:22px !important; }
            .h1 { font-size:23px !important; }
          }
        </style>
      </head>
      <body style="margin:0; padding:0; background:#{@canvas}; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; color:#{@ink}; -webkit-font-smoothing:antialiased;">
        <div style="display:none; max-height:0; overflow:hidden; mso-hide:all; font-size:1px; line-height:1px; color:#{@canvas};">
          #{preheader}
          &#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;&#847;&zwnj;&nbsp;
        </div>

        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#{@canvas};">
          <tr>
            <td align="center" style="padding:32px 16px;">
              <table role="presentation" class="container" width="560" cellpadding="0" cellspacing="0" border="0" style="width:560px; max-width:560px; background:#{@paper}; border:1px solid #{@line}; border-radius:14px; overflow:hidden;">
      """,
      content,
      footer,
      """
              </table>
            </td>
          </tr>
        </table>
      </body>
      </html>
      """
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  Render a table row section inside the shared 560px card.

  `content` is treated as already-rendered component HTML. Use `escaped_text/1`
  or text-safe components such as `heading/2` and `paragraph/2` for dynamic
  content.
  """
  def card_section(content, opts \\ []) do
    padding = Keyword.get(opts, :padding, "6px 28px 24px")
    background = Keyword.get(opts, :background, @paper)

    border_top =
      if Keyword.get(opts, :border_top, false), do: " border-top:1px solid #{@line};", else: ""

    [
      """
          <tr>
            <td class="gutter" style="padding:#{padding}; background:#{background};#{border_top} font-size:15px; line-height:1.55; color:#{@ink_2};">
      """,
      content,
      """
            </td>
          </tr>
      """
    ]
    |> IO.iodata_to_binary()
  end

  @doc """
  Render an email-safe h1 with escaped text content.
  """
  def heading(text, opts \\ []) do
    margin = Keyword.get(opts, :margin, "8px 0 14px")

    """
    <h1 class="h1" style="margin:#{margin}; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; font-size:26px; font-weight:600; line-height:1.15; letter-spacing:-0.028em; color:#{@ink};">#{escaped_text(text)}</h1>
    """
  end

  @doc """
  Render an email-safe paragraph with escaped text content.
  """
  def paragraph(text, opts \\ []) do
    margin = Keyword.get(opts, :margin, "0 0 16px")
    color = Keyword.get(opts, :color, @ink_2)
    font_size = Keyword.get(opts, :font_size, "15px")

    """
    <p style="margin:#{margin}; font-size:#{font_size}; line-height:1.55; color:#{color};">#{escaped_text(text)}</p>
    """
  end

  @doc """
  Escape dynamic text for insertion into HTML email components.
  """
  def escaped_text(nil), do: ""

  def escaped_text(text) when is_binary(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  def escaped_text(text), do: text |> to_string() |> escaped_text()
end
