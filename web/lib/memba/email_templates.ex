defmodule Memba.EmailTemplates do
  @moduledoc """
  Shared low-level helpers for rendering Memba's transactional email HTML.

  The helpers intentionally produce conservative, table-oriented markup with
  inline styles so the higher-level email modules can share one v2-compatible
  shell without depending on external CSS or browser-only layout features.
  """

  @canvas "#ece9e0"
  @paper "#ffffff"
  @paper_sunk "#f7f6f3"
  @line "#e6e3dc"
  @ink "#15201c"
  @ink_2 "#4b5a55"
  @ink_3 "#7d877f"
  @ink_4 "#b3b9b4"
  @forest "#1f4842"
  @forest_50 "#ecf2ee"
  @forest_100 "#d2e0d7"
  @forest_600 "#173a35"
  @forest_700 "#102b27"

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

  @doc """
  Sanitize dynamic text before using it in email header values.

  This removes control characters (including CR/LF) and collapses whitespace so
  user-, group-, or sender-provided values cannot inject additional headers.
  """
  def sanitize_header_text(nil), do: ""

  def sanitize_header_text(text) when is_binary(text) do
    text
    |> String.replace(~r/[[:cntrl:]]+/u, " ")
    |> String.replace(~r/[[:space:]]+/u, " ")
    |> String.trim()
  end

  def sanitize_header_text(text), do: text |> to_string() |> sanitize_header_text()

  @doc """
  Convert a plain-text message body into escaped, email-safe HTML paragraphs.

  Single newlines inside a paragraph become `<br>` tags; blank lines split
  paragraphs. The result is component HTML for use inside an email card, not a
  complete document.
  """
  def plaintext_to_html(text, opts \\ [])

  def plaintext_to_html(nil, _opts), do: ""

  def plaintext_to_html(text, opts) do
    margin = Keyword.get(opts, :margin, "0 0 15px")
    color = Keyword.get(opts, :color, @ink)
    font_size = Keyword.get(opts, :font_size, "15px")

    text
    |> to_string()
    |> normalize_line_endings()
    |> String.split(~r/\n[ \t]*\n+/u, trim: true)
    |> Enum.reject(&(String.trim(&1) == ""))
    |> Enum.map(fn paragraph ->
      paragraph_html =
        paragraph
        |> String.split("\n", trim: false)
        |> Enum.map(&escaped_text/1)
        |> Enum.join("<br>\n")

      """
      <p style="margin:#{margin}; font-size:#{font_size}; line-height:1.6; color:#{color};">#{paragraph_html}</p>
      """
    end)
    |> IO.iodata_to_binary()
  end

  @doc """
  Render the primary email action and the printed fallback URL.

  Both the button label and URL are escaped. The markup uses a table-backed
  button plus an Outlook VML fallback, and prints the raw URL in a mono block so
  clients that block buttons still expose the link.
  """
  def primary_action(label, url, opts \\ []) do
    escaped_label = escaped_text(label)
    escaped_url = escaped_text(url)

    fallback_label =
      opts
      |> Keyword.get(
        :fallback_label,
        "Button not working? Copy and paste this link into your browser:"
      )
      |> escaped_text()

    margin = Keyword.get(opts, :margin, "2px 0 16px")
    width = Keyword.get(opts, :width, "160px")

    """
    <table role="presentation" class="btn" cellpadding="0" cellspacing="0" border="0" style="margin:#{margin};"><tr>
      <td align="center" bgcolor="#{@forest}" style="border-radius:8px;">
        <!--[if mso]><v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="#{escaped_url}" style="height:44px;v-text-anchor:middle;width:#{width};" arcsize="18%" fillcolor="#{@forest}" stroke="f"><w:anchorlock/><center style="color:#f7f6f3;font-family:sans-serif;font-size:15px;font-weight:600;">#{escaped_label}</center></v:roundrect><![endif]-->
        <!--[if !mso]><!-- -->
        <a href="#{escaped_url}" style="display:inline-block; padding:13px 30px; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; font-size:15px; font-weight:600; line-height:1; color:#f7f6f3; text-decoration:none; border-radius:8px;">#{escaped_label}</a>
        <!--<![endif]-->
      </td>
    </tr></table>

    <p style="margin:0 0 8px; font-size:13px; color:#{@ink_3};">#{fallback_label}</p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 20px;"><tr>
      <td style="background:#{@paper_sunk}; border:1px solid #{@line}; border-radius:8px; padding:11px 14px; font-family:ui-monospace, Menlo, Consolas, monospace; font-size:12.5px; line-height:1.5; color:#{@forest}; word-break:break-all;">
        <a href="#{escaped_url}" style="color:#{@forest}; text-decoration:none; word-break:break-all;">#{escaped_url}</a>
      </td>
    </tr></table>
    """
  end

  @doc """
  Render a group-led card header with a neutral monogram and escaped group name.
  """
  def group_header(group_name, opts \\ []) do
    display_name =
      group_name
      |> sanitize_header_text()
      |> default_text("Your group")

    initials =
      opts
      |> Keyword.get(:initials)
      |> normalize_initials(derive_initials(display_name))

    label = opts |> Keyword.get(:label) |> sanitize_header_text()
    padding = Keyword.get(opts, :padding, "24px 28px 16px")

    border_bottom =
      if Keyword.get(opts, :border_bottom, false),
        do: " border-bottom:1px solid #{@line};",
        else: ""

    label_cell = label_cell(label)

    """
        <tr>
          <td class="gutter" style="padding:#{padding};#{border_bottom}">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="vertical-align:middle;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
                  <td style="padding-right:11px; vertical-align:middle;">
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
                      <td width="30" height="30" align="center" valign="middle" style="width:30px; height:30px; background:#{@ink}; border-radius:8px; font-size:12px; font-weight:600; color:#f7f6f3; text-align:center; line-height:30px; letter-spacing:0.01em;">#{escaped_text(initials)}</td>
                    </tr></table>
                  </td>
                  <td style="vertical-align:middle; font-size:16px; font-weight:600; color:#{@ink}; letter-spacing:-0.018em;">#{escaped_text(display_name)}</td>
                </tr></table>
              </td>
              #{label_cell}
            </tr></table>
          </td>
        </tr>
    """
  end

  @doc """
  Render a Memba-led card header for account/trust or delivery-notice emails.
  """
  def memba_header(opts \\ []) do
    label = opts |> Keyword.get(:label) |> sanitize_header_text()
    padding = Keyword.get(opts, :padding, "24px 28px 16px")
    label_cell = label_cell(label)

    """
        <tr>
          <td class="gutter" style="padding:#{padding};">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="vertical-align:middle;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
                  <td style="padding-right:9px; vertical-align:middle;">
                    #{memba_sprig_svg(22, "#f7f6f3", "3.4")}
                  </td>
                  <td style="vertical-align:middle; font-size:16px; font-weight:600; color:#{@ink}; letter-spacing:-0.018em;">Memba</td>
                </tr></table>
              </td>
              #{label_cell}
            </tr></table>
          </td>
        </tr>
    """
  end

  @doc """
  Render the ambient Memba footer used by non-auth transactional emails.

  Optional `:reply_to_email` may be supplied from a configured reply-to address.
  No support mailbox is hard-coded when that option is absent.
  """
  def memba_footer(opts \\ []) when is_list(opts) do
    group_name = opts |> Keyword.get(:group_name) |> sanitize_header_text()
    recipient_email = opts |> Keyword.get(:recipient_email) |> sanitize_header_text()
    reply_to_email = opts |> Keyword.get(:reply_to_email) |> sanitize_header_text()
    reason = opts |> Keyword.get(:reason) |> sanitize_header_text()
    extra_detail_html = Keyword.get(opts, :extra_detail_html, [])

    delivered_line =
      if group_name == "" do
        ~s|Delivered by <a href="https://memba.io" style="color:#{@ink_2}; text-decoration:none; font-weight:600;">Memba</a>|
      else
        ~s|Delivered for #{escaped_text(group_name)} by <a href="https://memba.io" style="color:#{@ink_2}; text-decoration:none; font-weight:600;">Memba</a>|
      end

    detail_lines =
      [
        footer_sentence("Sent to", recipient_email),
        if(reason == "", do: nil, else: escaped_text(reason)),
        extra_detail_html,
        support_sentence(reply_to_email)
      ]
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.join("<br>\n")

    """
        <tr>
          <td class="gutter" style="padding:16px 28px 24px; border-top:1px solid #{@line};">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:9px;"><tr>
              <td style="padding-right:7px; vertical-align:middle;">
                #{memba_sprig_svg(15, "#ffffff", "4")}
              </td>
              <td style="vertical-align:middle; font-size:11.5px; color:#{@ink_3};">#{delivered_line}</td>
            </tr></table>
            <div style="font-size:12px; line-height:1.6; color:#{@ink_3};">
              #{detail_lines}
            </div>
          </td>
        </tr>
    """
  end

  @doc """
  Render the sign-in trust footer where Memba intentionally steps forward.
  """
  def trust_footer(opts \\ []) when is_list(opts) do
    group_name = opts |> Keyword.get(:group_name) |> sanitize_header_text()

    trust_copy =
      if group_name == "" do
        "This sign-in link is secured by Memba. It expires in 15&nbsp;minutes, works only once, and only for you. We&rsquo;ll never ask for a password or payment by email."
      else
        "#{escaped_text(group_name)} runs on Memba. This is a genuine sign-in link &mdash; it expires in 15&nbsp;minutes, works only once, and only for you. We&rsquo;ll never ask for a password or payment by email."
      end

    """
        <tr>
          <td class="gutter" style="padding:18px 28px 22px; background:#{@forest_50}; border-top:1px solid #{@forest_100};">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:8px;"><tr>
              <td style="padding-right:8px; vertical-align:middle;">
                #{memba_sprig_svg(18, @forest_50, "4")}
              </td>
              <td style="vertical-align:middle; font-size:13px; font-weight:600; color:#{@forest_600}; letter-spacing:-0.01em;">Secured by Memba</td>
            </tr></table>
            <p style="margin:0; font-size:12.5px; line-height:1.55; color:#{@forest_700};">#{trust_copy}</p>
          </td>
        </tr>
    """
  end

  defp normalize_line_endings(text) do
    String.replace(text, ~r/\r\n|\r|\n/u, "\n")
  end

  defp default_text("", fallback), do: fallback
  defp default_text(text, _fallback), do: text

  defp derive_initials(text) do
    words =
      ~r/[\p{L}\p{N}]+/u
      |> Regex.scan(text)
      |> List.flatten()

    initials =
      case words do
        [] ->
          []

        [word] ->
          word
          |> String.graphemes()
          |> Enum.take(2)

        words ->
          words
          |> Enum.take(2)
          |> Enum.map(&first_grapheme/1)
      end

    initials
    |> Enum.join()
    |> String.upcase()
    |> default_text("M")
  end

  defp first_grapheme(text) do
    text
    |> String.graphemes()
    |> List.first("")
  end

  defp normalize_initials(nil, fallback), do: fallback

  defp normalize_initials(initials, fallback) do
    initials =
      initials
      |> sanitize_header_text()
      |> String.replace(~r/[[:space:]]+/u, "")
      |> String.graphemes()
      |> Enum.take(3)
      |> Enum.join()
      |> String.upcase()

    default_text(initials, fallback)
  end

  defp label_cell(""), do: ""

  defp label_cell(label) do
    """
    <td align="right" style="vertical-align:middle; font-size:11px; color:#{@ink_4}; letter-spacing:0.04em; text-transform:uppercase;">#{escaped_text(label)}</td>
    """
  end

  defp footer_sentence(_prefix, ""), do: nil

  defp footer_sentence(prefix, text) do
    "#{escaped_text(prefix)} #{escaped_text(text)}."
  end

  defp support_sentence(""), do: "Need a hand? Contact Memba support."

  defp support_sentence(reply_to_email) do
    escaped_reply_to_email = escaped_text(reply_to_email)

    ~s|Need a hand? Reply to this email or write to <a href="mailto:#{escaped_reply_to_email}" style="color:#{@ink_3}; text-decoration:underline;">#{escaped_reply_to_email}</a>.|
  end

  defp memba_sprig_svg(size, color, stem_width) do
    """
    <svg width="#{size}" height="#{size}" viewBox="0 0 64 64" aria-hidden="true"><rect x="2" y="2" width="60" height="60" rx="12" fill="#{@forest}"></rect><path d="M32 51 C32 43 32 36 32 18" fill="none" stroke="#{color}" stroke-width="#{stem_width}" stroke-linecap="round"></path><path d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z" fill="#{color}"></path><path d="M32 39 C25 38 20 32 19 23 C26 24.5 31 31 32 39 Z" fill="#{color}"></path><circle cx="32" cy="15" r="3.7" fill="#d2925a"></circle></svg>
    """
  end
end
