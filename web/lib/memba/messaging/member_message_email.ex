defmodule Memba.Messaging.MemberMessageEmail do
  @moduledoc """
  Shared rendering and header helpers for member-message delivery emails.

  Member-message text bodies remain exactly as the sender wrote them. The HTML
  part uses Memba's v2 group-led template, with Memba only as the carrier.
  """

  alias Memba.EmailTemplates
  alias Memba.Messaging.EmailDeliveryRequest

  @doc "Return the sanitized From display name for a member-message email."
  def from_display_name(%EmailDeliveryRequest{} = request) do
    "#{sender_name(request)} via Memba"
  end

  @doc "Return the sanitized Reply-To tuple for a member-message email."
  def reply_to(%EmailDeliveryRequest{} = request) do
    {sender_name(request), request.sender_address}
  end

  @doc "Return the sanitized To tuple for a member-message email."
  def to(%EmailDeliveryRequest{} = request) do
    {recipient_name(request), request.recipient_address}
  end

  @doc "Return the sanitized subject for a member-message email header."
  def subject(%EmailDeliveryRequest{} = request) do
    subject =
      request.subject
      |> EmailTemplates.sanitize_header_text()
      |> default_text("Message from #{group_name(request)}")

    case club_slug(request) do
      "" -> subject
      slug -> "[#{slug}] #{subject}"
    end
  end

  @doc "Render the v2-compatible HTML body for a member-message email."
  def html_body(%EmailDeliveryRequest{} = request) do
    group_name = group_name(request)
    sender_name = sender_name(request)
    title = subject(request)

    content = [
      EmailTemplates.group_header(group_name,
        label: "Members message",
        padding: "18px 28px",
        border_bottom: true
      ),
      sender_row(sender_name, group_name),
      message_section(title, request.body),
      reply_hint(sender_name)
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader: "A message from #{sender_name} to members of #{group_name}.",
      content: content,
      footer:
        EmailTemplates.memba_footer(
          group_name: group_name,
          recipient_email: request.recipient_address,
          reason: membership_reason(request.club_name, group_name)
        )
    )
  end

  defp sender_row(sender_name, group_name) do
    """
        <tr>
          <td class="gutter" style="padding:22px 28px 4px;">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="vertical-align:middle;">
                <div style="font-size:15px; font-weight:600; color:#15201c; letter-spacing:-0.01em;">#{EmailTemplates.escaped_text(sender_name)}</div>
                <div style="font-size:12.5px; color:#7d877f; margin-top:1px;">to all members of #{EmailTemplates.escaped_text(group_name)}</div>
              </td>
            </tr></table>
          </td>
        </tr>
    """
  end

  defp message_section(title, body) do
    [
      EmailTemplates.card_section(
        [
          EmailTemplates.heading(title,
            margin: "6px 0 14px"
          ),
          EmailTemplates.plaintext_to_html(body,
            color: "#2c3a35",
            font_size: "15.5px"
          )
        ],
        padding: "14px 28px 22px"
      )
    ]
  end

  defp reply_hint(sender_name) do
    """
        <tr>
          <td class="gutter" style="padding:0 28px 22px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="background:#f7f6f3; border:1px solid #e6e3dc; border-radius:10px; padding:13px 16px; font-size:13px; line-height:1.5; color:#4b5a55;">
                Reply to this email and it goes straight to <b style="color:#15201c; font-weight:600;">#{EmailTemplates.escaped_text(sender_name)}</b> &mdash; not to the whole group.
              </td>
            </tr></table>
          </td>
        </tr>
    """
  end

  defp sender_name(%EmailDeliveryRequest{} = request) do
    request.sender_name
    |> EmailTemplates.sanitize_header_text()
    |> default_text("A member")
  end

  defp recipient_name(%EmailDeliveryRequest{} = request) do
    request.recipient_name
    |> EmailTemplates.sanitize_header_text()
    |> default_text("Member")
  end

  defp group_name(%EmailDeliveryRequest{} = request) do
    request.club_name
    |> EmailTemplates.sanitize_header_text()
    |> default_text("Your group")
  end

  defp club_slug(%EmailDeliveryRequest{} = request) do
    request.club_slug
    |> EmailTemplates.sanitize_header_text()
    |> default_text("")
  end

  defp membership_reason(club_name, display_name) do
    case EmailTemplates.sanitize_header_text(club_name) do
      "" -> "You're getting this because you're an active member of this group."
      _club_name -> "You're getting this because you're an active member of #{display_name}."
    end
  end

  defp default_text("", fallback), do: fallback
  defp default_text(text, _fallback), do: text
end
