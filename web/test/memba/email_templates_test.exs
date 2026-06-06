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
