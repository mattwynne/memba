defmodule Memba.Messaging.MemberMessageEmail do
  @moduledoc """
  Shared rendering and header helpers for member-message delivery emails.

  Member-message text bodies remain exactly as the sender wrote them. The HTML
  part uses Memba's v2 group-led template, with Memba only as the carrier.
  """

  alias Memba.ClubInboundEmailAddress
  alias Memba.EmailTemplates
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.OutboundMessageID

  @doc "Return the sanitized From display name for a member-message email."
  def from_display_name(%EmailDeliveryRequest{} = request) do
    if reply?(request) or private_group_root?(request) do
      "#{group_name(request)} via Memba"
    else
      "#{sender_name(request)} via Memba"
    end
  end

  @doc "Return the sanitized Reply-To tuple for a member-message email."
  def reply_to(%EmailDeliveryRequest{} = request) do
    case ClubInboundEmailAddress.address(request.club_slug) do
      nil -> {sender_name(request), request.sender_address}
      address -> {group_name(request), address}
    end
  end

  @doc "Return the sanitized To tuple for a member-message email."
  def to(%EmailDeliveryRequest{} = request) do
    {recipient_name(request), request.recipient_address}
  end

  @doc "Return the persisted RFC Message-ID header value for this outbound email."
  def message_id(%EmailDeliveryRequest{} = request) do
    request.outbound_message_id
  end

  @doc "Return RFC threading headers for a reply notification email."
  def threading_headers(%EmailDeliveryRequest{} = request) do
    if reply?(request) do
      []
      |> maybe_header("In-Reply-To", request.in_reply_to_outbound_message_id)
      |> maybe_header("References", references_header(request.references_outbound_message_ids))
      |> Enum.reverse()
    else
      []
    end
  end

  @doc "Return the sanitized subject for a member-message email header."
  def subject(%EmailDeliveryRequest{} = request) do
    subject =
      request
      |> subject_text()
      |> default_text("Message from #{group_name(request)}")

    case club_slug(request) do
      "" -> subject
      slug -> "[#{slug}] #{subject}"
    end
  end

  @doc "Render the plain-text body for a member-message email."
  def text_body(%EmailDeliveryRequest{} = request) do
    if reply?(request) do
      reply_text_body(request)
    else
      request.body
    end
  end

  @doc "Render the v2-compatible HTML body for a member-message email."
  def html_body(%EmailDeliveryRequest{} = request) do
    if reply?(request) do
      reply_html_body(request)
    else
      message_html_body(request)
    end
  end

  defp message_html_body(%EmailDeliveryRequest{} = request) do
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
      reply_hint(request, sender_name, group_name)
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

  defp reply_html_body(%EmailDeliveryRequest{} = request) do
    group_name = group_name(request)
    sender_name = sender_name(request)
    title = subject(request)

    content = [
      EmailTemplates.group_header(group_name,
        label: "New reply",
        padding: "18px 28px",
        border_bottom: true
      ),
      conversation_subject_section(request),
      reply_author_row(sender_name),
      reply_body_section(request.body),
      view_conversation_section(request.conversation_url),
      replied_to_context_section(request)
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader: "#{sender_name} replied in the #{conversation_subject(request)} conversation.",
      content: content,
      footer: reply_footer(request, group_name)
    )
  end

  defp reply_text_body(%EmailDeliveryRequest{} = request) do
    [
      "#{sender_name(request)} replied in the #{conversation_subject(request)} conversation:",
      "",
      request.body,
      view_conversation_text(request.conversation_url),
      stop_follow_text(request.stop_follow_url),
      replied_to_context_text(request)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp subject_text(%EmailDeliveryRequest{} = request) do
    request.subject
    |> EmailTemplates.sanitize_header_text()
    |> maybe_reply_subject(request)
  end

  defp maybe_reply_subject(subject, %EmailDeliveryRequest{} = request) do
    if reply?(request) and not reply_subject?(subject) do
      "Re: #{subject}"
    else
      subject
    end
  end

  defp reply_subject?(subject) do
    subject
    |> String.downcase()
    |> String.starts_with?("re:")
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

  defp conversation_subject_section(%EmailDeliveryRequest{} = request) do
    """
        <tr>
          <td class="gutter" style="padding:20px 28px 2px;">
            <div style="font-size:11px; color:#7d877f; letter-spacing:0.04em; text-transform:uppercase;">In the conversation</div>
            <h1 class="h1" style="margin:5px 0 0; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; font-size:22px; font-weight:600; line-height:1.2; letter-spacing:-0.022em; color:#15201c;">#{EmailTemplates.escaped_text(conversation_subject(request))}</h1>
          </td>
        </tr>
    """
  end

  defp reply_author_row(sender_name) do
    """
        <tr>
          <td class="gutter" style="padding:18px 28px 4px;">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="vertical-align:middle;">
                <div style="font-size:15px; font-weight:600; color:#15201c; letter-spacing:-0.01em;">#{EmailTemplates.escaped_text(sender_name)} replied</div>
                <div style="font-size:12.5px; color:#7d877f; margin-top:1px;">just now</div>
              </td>
            </tr></table>
          </td>
        </tr>
    """
  end

  defp reply_body_section(body) do
    EmailTemplates.card_section(
      EmailTemplates.plaintext_to_html(body,
        color: "#2c3a35",
        font_size: "15.5px"
      ),
      padding: "12px 28px 14px"
    )
  end

  defp view_conversation_section(nil), do: ""

  defp view_conversation_section(url) do
    case String.trim(to_string(url)) do
      "" ->
        ""

      url ->
        EmailTemplates.card_section(
          EmailTemplates.primary_action("View the conversation", url,
            width: "190px",
            margin: "0 0 16px"
          ),
          padding: "0 28px 6px"
        )
    end
  end

  defp replied_to_context_section(%EmailDeliveryRequest{} = request) do
    cond do
      blank?(request.reply_to_sender_name) or blank?(request.reply_to_body) ->
        ""

      true ->
        EmailTemplates.card_section(
          [
            EmailTemplates.paragraph("In reply to #{request.reply_to_sender_name}:",
              margin: "0 0 8px",
              color: "#7d877f",
              font_size: "13.5px"
            ),
            """
            <blockquote class="gmail_quote" style="margin:0; padding:2px 0 2px 14px; border-left:2px solid #e6e3dc; color:#7d877f;">
              #{EmailTemplates.plaintext_to_html(request.reply_to_body, color: "#7d877f", font_size: "13.5px", margin: "0 0 12px")}
            </blockquote>
            """
          ],
          padding: "0 28px 18px"
        )
    end
  end

  defp reply_hint(%EmailDeliveryRequest{} = request, sender_name, group_name) do
    case ClubInboundEmailAddress.address(request.club_slug) do
      nil -> sender_reply_hint(sender_name)
      _address -> club_reply_hint(group_name)
    end
  end

  defp sender_reply_hint(sender_name) do
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

  defp club_reply_hint(group_name) do
    """
        <tr>
          <td class="gutter" style="padding:0 28px 22px;">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
              <td style="background:#f7f6f3; border:1px solid #e6e3dc; border-radius:10px; padding:13px 16px; font-size:13px; line-height:1.5; color:#4b5a55;">
                Reply to this email to post back to <b style="color:#15201c; font-weight:600;">#{EmailTemplates.escaped_text(group_name)}</b>.
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

  defp conversation_subject(%EmailDeliveryRequest{} = request) do
    request.subject
    |> EmailTemplates.sanitize_header_text()
    |> default_text("this message")
  end

  defp view_conversation_text(nil), do: nil

  defp view_conversation_text(url) do
    case String.trim(to_string(url)) do
      "" -> nil
      url -> "\nView the conversation:\n#{url}"
    end
  end

  defp stop_follow_text(nil), do: nil

  defp stop_follow_text(url) do
    case String.trim(to_string(url)) do
      "" -> nil
      url -> "\nYou're following this conversation.\nStop following this conversation:\n#{url}"
    end
  end

  defp replied_to_context_text(%EmailDeliveryRequest{} = request) do
    cond do
      blank?(request.reply_to_sender_name) or blank?(request.reply_to_body) ->
        nil

      true ->
        "\nIn reply to #{request.reply_to_sender_name}:\n#{request.reply_to_body}"
    end
  end

  defp reply?(%EmailDeliveryRequest{reply_to_message_id: reply_to_message_id}) do
    is_binary(reply_to_message_id) and String.trim(reply_to_message_id) != ""
  end

  defp private_group_root?(%EmailDeliveryRequest{
         audience_group_id: audience_group_id,
         club_id: club_id
       })
       when is_binary(audience_group_id) and is_binary(club_id) do
    audience_group_id != SystemGroups.everyone_group_id(club_id)
  end

  defp private_group_root?(%EmailDeliveryRequest{}), do: false

  defp maybe_header(headers, _name, nil), do: headers

  defp maybe_header(headers, name, value) when is_binary(value) do
    case String.trim(value) do
      "" -> headers
      value -> [{name, value} | headers]
    end
  end

  defp maybe_header(headers, _name, _value), do: headers

  defp references_header(values) when is_list(values) do
    values
    |> Enum.map(&OutboundMessageID.normalize/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> case do
      [] -> nil
      message_ids -> Enum.join(message_ids, " ")
    end
  end

  defp references_header(_values), do: nil

  defp blank?(value), do: value in [nil, ""]

  defp membership_reason(club_name, display_name) do
    case EmailTemplates.sanitize_header_text(club_name) do
      "" -> "You're getting this because you're an active member of this group."
      _club_name -> "You're getting this because you're an active member of #{display_name}."
    end
  end

  defp reply_footer(%EmailDeliveryRequest{} = request, group_name) do
    stop_follow_line =
      case String.trim(to_string(request.stop_follow_url || "")) do
        "" ->
          nil

        stop_follow_url ->
          """
          You're following this conversation. <a href="#{EmailTemplates.escaped_text(stop_follow_url)}" style="color:#7d877f; text-decoration:underline;">Stop following this conversation</a>.
          """
      end

    EmailTemplates.memba_footer(
      group_name: group_name,
      recipient_email: request.recipient_address,
      reason: membership_reason(request.club_name, group_name),
      extra_detail_html: stop_follow_line
    )
  end

  defp default_text("", fallback), do: fallback
  defp default_text(text, _fallback), do: text
end
