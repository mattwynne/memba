defmodule Memba.EmailTemplatesTest do
  use ExUnit.Case, async: true

  alias Memba.EmailTemplates

  test "renders a v2-compatible single-card shell without external CSS dependencies" do
    content =
      EmailTemplates.card_section([
        EmailTemplates.heading("Sign in to Wessex <Choir>"),
        EmailTemplates.paragraph("Use the button below & keep this email private.")
      ])

    html =
      EmailTemplates.render_shell(
        title: "Sign in <now>",
        preheader: "Your link expires in 15 minutes & works once.",
        content: content,
        footer: EmailTemplates.card_section("Footer component", border_top: true)
      )

    assert html =~ "<!doctype html>"
    assert html =~ "<title>Sign in &lt;now&gt;</title>"
    assert html =~ "display:none; max-height:0; overflow:hidden"
    assert html =~ "Your link expires in 15 minutes &amp; works once."
    assert html =~ "width:560px; max-width:560px"
    assert html =~ "role=\"presentation\""
    assert html =~ "class=\"container\""
    assert html =~ "class=\"gutter\""
    assert html =~ "border-top:1px solid #e6e3dc"
    assert html =~ "Sign in to Wessex &lt;Choir&gt;"
    assert html =~ "Use the button below &amp; keep this email private."
    refute html =~ "<link"
    refute html =~ "@import"
  end

  test "escapes dynamic text consistently for reusable components" do
    assert EmailTemplates.escaped_text(~s|<script>alert("x")</script> & clubs|) ==
             ~s|&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; clubs|

    assert EmailTemplates.escaped_text(nil) == ""
    assert EmailTemplates.escaped_text(123) == "123"
  end

  test "sanitizes dynamic text that will be used in email headers" do
    assert EmailTemplates.sanitize_header_text(" Wessex\r\nBcc: attacker@example.test\t Choir\0 ") ==
             "Wessex Bcc: attacker@example.test Choir"

    assert EmailTemplates.sanitize_header_text(nil) == ""
    assert EmailTemplates.sanitize_header_text(123) == "123"
  end

  test "converts plaintext message bodies into escaped email-safe paragraphs" do
    html =
      EmailTemplates.plaintext_to_html("""
      Hi <all>,
      Please bring stands & folders.

      <script>alert("x")</script>
      Thanks
      """)

    assert html =~ "<p"
    assert html =~ "Hi &lt;all&gt;,<br>\nPlease bring stands &amp; folders."
    assert html =~ "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;<br>\nThanks"
    refute html =~ "<script>"
  end

  test "renders a primary button with an escaped printed fallback URL" do
    url = ~s|https://memba.test/sign-in?token="abc"&next=<home>|

    html =
      EmailTemplates.primary_action("Sign <in>", url,
        fallback_label: "Copy this <link>:",
        margin: "4px 0 12px"
      )

    escaped_url = ~s|https://memba.test/sign-in?token=&quot;abc&quot;&amp;next=&lt;home&gt;|

    assert html =~ ~s|href="#{escaped_url}"|
    assert html =~ "Sign &lt;in&gt;"
    assert html =~ "Copy this &lt;link&gt;:"
    assert html =~ escaped_url
    assert html =~ "word-break:break-all"
    assert html =~ "v:roundrect"
  end

  test "renders escaped group-led and Memba-led headers" do
    group_header =
      EmailTemplates.group_header("Wessex <Choir>\nInjected",
        label: "Members <message>"
      )

    assert group_header =~ "WC"
    assert group_header =~ "Wessex &lt;Choir&gt; Injected"
    assert group_header =~ "Members &lt;message&gt;"
    refute group_header =~ "Wessex <Choir>"

    memba_header = EmailTemplates.memba_header(label: "Delivery <notice>")

    assert memba_header =~ "Memba"
    assert memba_header =~ "Delivery &lt;notice&gt;"
    assert memba_header =~ "<svg"
  end

  test "renders escaped Memba footer and trust footer without hard-coded support addresses" do
    footer =
      EmailTemplates.memba_footer(
        group_name: "Wessex <Choir>",
        recipient_email: "lou@example.test",
        reply_to_email: "support@example.test"
      )

    assert footer =~ "Delivered for Wessex &lt;Choir&gt; by"
    assert footer =~ "Sent to lou@example.test."
    assert footer =~ ~s|mailto:support@example.test|
    refute footer =~ "help@memba.io"

    trust_footer = EmailTemplates.trust_footer(group_name: "Wessex <Choir>")

    assert trust_footer =~ "Secured by Memba"
    assert trust_footer =~ "Wessex &lt;Choir&gt; runs on Memba."
    assert trust_footer =~ "expires in 15&nbsp;minutes"
    refute trust_footer =~ "help@memba.io"
  end

  test "keeps trusted component HTML composable while escaping component text" do
    section =
      EmailTemplates.card_section([
        EmailTemplates.heading("Members <Message>"),
        ~s(<table role="presentation"><tr><td>trusted button component</td></tr></table>)
      ])

    assert section =~ "Members &lt;Message&gt;"

    assert section =~
             ~s(<table role="presentation"><tr><td>trusted button component</td></tr></table>)

    refute section =~ "Members <Message>"
  end
end
