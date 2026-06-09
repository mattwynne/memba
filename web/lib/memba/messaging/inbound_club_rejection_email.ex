defmodule Memba.Messaging.InboundClubRejectionEmail do
  @moduledoc """
  Builds and delivers concise rejection emails for inbound club messages.

  Rejection emails use the application mailer and the configured messaging sender
  address so local/test/production mailer adapters stay switchable.
  """

  import Swoosh.Email

  alias Memba.EmailTemplates
  alias Memba.Messaging.InboundEmail

  @subject "Your email wasn't posted"
  @fallback_from {"Memba", "messages@mail.memba.io"}

  @doc """
  Deliver a rejection email to the inbound sender.
  """
  def deliver(
        %InboundEmail{} = inbound_email,
        to_address,
        rejection_reason,
        delivery_reference,
        opts \\ []
      )
      when is_binary(rejection_reason) and is_binary(delivery_reference) and is_list(opts) do
    inbound_email
    |> email(to_address, rejection_reason, delivery_reference, opts)
    |> deliver_email()
  end

  defp email(
         %InboundEmail{} = inbound_email,
         to_address,
         rejection_reason,
         delivery_reference,
         opts
       ) do
    reply_to_address = reply_to_address()
    body = rejection_text_body(inbound_email, rejection_reason, opts, reply_to_address)

    new()
    |> from(from_address(opts))
    |> maybe_reply_to(reply_to_address)
    |> maybe_thread_as_reply(inbound_email)
    |> to(inbound_email.from_address)
    |> subject(email_subject(inbound_email, opts))
    |> text_body(body)
    |> html_body(html_body(inbound_email, rejection_reason, opts, reply_to_address))
    |> put_provider_options(inbound_email, to_address, rejection_reason, delivery_reference)
  end

  defp from_address(opts) do
    from_address = configured_from_address() || @fallback_from

    case club_sender_name(opts) do
      nil -> from_address
      sender_name -> put_sender_name(from_address, sender_name)
    end
  end

  defp club_sender_name(opts) do
    case club_name(opts) do
      nil -> nil
      club_name -> "#{club_name} via Memba"
    end
  end

  defp put_sender_name({_name, address}, sender_name), do: {sender_name, address}

  defp configured_from_address do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)

      Memba.Messaging.EmailDeliveryProviders.Postmark ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      Memba.Messaging.EmailDeliveryProviders.Local ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      _provider ->
        messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Postmark) ||
          messaging_provider_from_address(Memba.Messaging.EmailDeliveryProviders.Resend)
    end
  end

  defp messaging_provider_from_address(provider_module) do
    :memba
    |> Application.get_env(provider_module, [])
    |> Keyword.get(:from)
    |> normalize_address()
  end

  defp reply_to_address do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Resend)

      Memba.Messaging.EmailDeliveryProviders.Postmark ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      Memba.Messaging.EmailDeliveryProviders.Local ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark)

      _provider ->
        messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Postmark) ||
          messaging_provider_reply_to_address(Memba.Messaging.EmailDeliveryProviders.Resend)
    end
  end

  defp messaging_provider_reply_to_address(provider_module) do
    :memba
    |> Application.get_env(provider_module, [])
    |> Keyword.get(:reply_to)
    |> normalize_address()
  end

  defp normalize_address({_name, address} = named_address) when is_binary(address) do
    named_address
  end

  defp normalize_address(address) when is_binary(address) do
    case String.trim(address) do
      "" -> nil
      address -> {"Memba", address}
    end
  end

  defp normalize_address(_address), do: nil

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, reply_to_address), do: reply_to(email, reply_to_address)

  defp email_subject(
         %InboundEmail{original_message_id: original_message_id, subject: original_subject},
         _opts
       )
       when is_binary(original_message_id) do
    original_subject
    |> EmailTemplates.sanitize_header_text()
    |> default_text(@subject)
    |> reply_subject()
  end

  defp email_subject(%InboundEmail{}, opts) do
    case club_name(opts) do
      nil -> @subject
      club_name -> "Your email to #{club_name} wasn't posted"
    end
  end

  defp reply_subject("Re:" <> _rest = subject), do: subject
  defp reply_subject("re:" <> _rest = subject), do: subject
  defp reply_subject(subject), do: "Re: #{subject}"

  defp maybe_thread_as_reply(email, %InboundEmail{original_message_id: original_message_id})
       when is_binary(original_message_id) do
    original_message_id = EmailTemplates.sanitize_header_text(original_message_id)

    email
    |> header("In-Reply-To", original_message_id)
    |> header("References", original_message_id)
  end

  defp maybe_thread_as_reply(email, %InboundEmail{}), do: email

  defp put_provider_options(
         email,
         inbound_email,
         to_address,
         rejection_reason,
         delivery_reference
       ) do
    case selected_provider() do
      Memba.Messaging.EmailDeliveryProviders.Resend ->
        email
        |> put_provider_option(:tags, [
          %{name: "memba_email_kind", value: "inbound_club_rejection"},
          %{name: "memba_inbound_provider_message_id", value: inbound_email.provider_message_id},
          %{name: "memba_rejection_reason", value: rejection_reason},
          %{name: "memba_rejection_delivery_reference", value: delivery_reference}
        ])
        |> header("X-Memba-Inbound-Email-ID", InboundEmail.identity(inbound_email))
        |> header("X-Memba-Rejection-Delivery-Reference", delivery_reference)

      _provider ->
        put_provider_option(
          email,
          :metadata,
          metadata(inbound_email, to_address, rejection_reason, delivery_reference)
        )
    end
  end

  defp selected_provider do
    Application.get_env(:memba, :messaging_email_delivery_provider)
  end

  defp metadata(inbound_email, to_address, rejection_reason, delivery_reference) do
    %{
      "memba_email_kind" => "inbound_club_rejection",
      "memba_inbound_id" => InboundEmail.identity(inbound_email),
      "memba_in_provider" => inbound_email.provider,
      "memba_in_msg_id" => inbound_email.provider_message_id,
      "memba_in_to" => to_address,
      "memba_reject_reason" => rejection_reason,
      "memba_reject_ref" => delivery_reference
    }
    |> Map.new(fn {key, value} -> {key, postmark_metadata_value(value)} end)
  end

  defp postmark_metadata_value(value) do
    value
    |> to_string()
    |> String.slice(0, 80)
  end

  defp reason_copy("attachments_not_supported", _opts),
    do: "Emails with attachments can't be posted yet, so your message wasn't posted."

  defp reason_copy("plain_text_required", _opts),
    do: "We couldn't read a plain-text message body, so your message wasn't posted."

  defp reason_copy("unknown_sender", _opts),
    do: "We couldn't find a member account for this email address, so your message wasn't posted."

  defp reason_copy("sender_not_active_member", opts) do
    case club_name(opts) do
      nil ->
        "This email address isn't an active member of that group, so your message wasn't posted."

      club_name ->
        "This email address isn't an active member of #{club_name}, so your message wasn't posted."
    end
  end

  defp reason_copy("unknown_club_slug", _opts),
    do: "We couldn't match the address you used to a Memba group, so your message wasn't posted."

  defp reason_copy("unsupported_recipient_address", _opts),
    do: "That recipient address isn't set up for member messages, so your message wasn't posted."

  defp reason_copy(_reason, _opts),
    do: "We couldn't post this email. Nothing was sent to the group."

  defp rejection_text_body(%InboundEmail{} = inbound_email, reason, opts, reply_to_address) do
    [
      opening_line(opts),
      "",
      reason_copy(reason, opts),
      membership_hint_text(reason, opts),
      "",
      "What to do next",
      next_step_text(opts, reply_to_address),
      original_context_text(inbound_email)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp html_body(
         %InboundEmail{} = inbound_email,
         rejection_reason,
         opts,
         reply_to_address
       ) do
    group_name = club_name(opts)
    reason = reason_copy(rejection_reason, opts)

    content = [
      EmailTemplates.memba_header(label: "Delivery notice"),
      EmailTemplates.card_section(
        [
          delivery_status_mark(),
          EmailTemplates.heading(@subject, margin: "12px 0 12px"),
          intro_html(group_name),
          reason_box(reason),
          membership_hint_html(rejection_reason, group_name),
          section_label("What to do next"),
          next_step_html(opts, reply_to_address),
          original_context_html(inbound_email)
        ],
        padding: "6px 28px 24px"
      )
    ]

    EmailTemplates.render_shell(
      title: @subject,
      preheader: preheader(opts),
      content: content,
      footer:
        EmailTemplates.memba_footer(
          group_name: group_name,
          recipient_email: inbound_email.from_address,
          reply_to_email: reply_to_email(reply_to_address),
          reason: "This is an automatic delivery notice."
        )
    )
  end

  defp opening_line(opts) do
    case club_name(opts) do
      nil -> "Your email wasn't posted."
      club_name -> "Your email to #{club_name} wasn't posted."
    end
  end

  defp preheader(opts) do
    case club_name(opts) do
      nil -> "Your email wasn't posted. Here's why, and how to fix it."
      club_name -> "Your email to #{club_name} wasn't posted. Here's why, and how to fix it."
    end
  end

  defp intro_html(nil) do
    """
    <p style="margin:0 0 16px;">Sorry &mdash; your email didn&rsquo;t go out to members. Here&rsquo;s why:</p>
    """
  end

  defp intro_html(group_name) do
    """
    <p style="margin:0 0 16px;">Sorry &mdash; your message to <b style="color:#15201c; font-weight:600;">#{EmailTemplates.escaped_text(group_name)}</b> didn&rsquo;t go out to members. Here&rsquo;s why:</p>
    """
  end

  defp reason_box(reason) do
    """
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 16px;"><tr>
      <td style="background:#f7f6f3; border:1px solid #e6e3dc; border-radius:10px; padding:14px 16px; font-size:15px; line-height:1.5; color:#15201c;">
        #{EmailTemplates.escaped_text(reason)}
      </td>
    </tr></table>
    """
  end

  defp membership_hint_text("unknown_sender", opts) do
    case club_name(opts) do
      nil ->
        nil

      club_name ->
        "Is it possible you signed up for membership of #{club_name} with a different email address?"
    end
  end

  defp membership_hint_text(_reason, _opts), do: nil

  defp membership_hint_html("unknown_sender", club_name) when is_binary(club_name) do
    """
    <p style="margin:0 0 18px;">Is it possible you signed up for membership of #{EmailTemplates.escaped_text(club_name)} with a different email address?</p>
    """
  end

  defp membership_hint_html(_reason, _club_name), do: ""

  defp next_step_text(opts, reply_to_address) do
    help =
      if reply_to_email(reply_to_address) do
        "Just reply to this email and a person will help."
      else
        "If you need a hand, contact Memba support."
      end

    "#{help} #{nothing_sent_sentence(opts)}"
  end

  defp next_step_html(opts, reply_to_address) do
    help = help_html(reply_to_address)
    nothing_sent = opts |> nothing_sent_sentence() |> EmailTemplates.escaped_text()

    """
    <p style="margin:0 0 18px;">#{help} #{nothing_sent}</p>
    """
  end

  defp help_html(reply_to_address) do
    case reply_to_email(reply_to_address) do
      nil ->
        "If you need a hand, contact Memba support."

      reply_to_email ->
        escaped_reply_to_email = EmailTemplates.escaped_text(reply_to_email)

        ~s|Just reply to this email and a person will help, or write to <a href="mailto:#{escaped_reply_to_email}" style="color:#1f4842; text-decoration:underline;">#{escaped_reply_to_email}</a>.|
    end
  end

  defp nothing_sent_sentence(opts) do
    case club_name(opts) do
      nil -> "Nothing was sent to a group, so there's nothing to undo."
      club_name -> "Nothing was sent to #{club_name}, so there's nothing to undo."
    end
  end

  defp original_context_text(%InboundEmail{} = inbound_email) do
    subject =
      inbound_email.subject
      |> EmailTemplates.sanitize_header_text()
      |> default_text("(no subject)")

    snippet = message_snippet(inbound_email.text_body)

    [
      "",
      "Your message",
      "Subject: #{subject}",
      if(snippet == "", do: nil, else: snippet)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp original_context_html(%InboundEmail{} = inbound_email) do
    subject =
      inbound_email.subject
      |> EmailTemplates.sanitize_header_text()
      |> default_text("(no subject)")

    snippet = message_snippet(inbound_email.text_body)

    snippet_html =
      if snippet == "" do
        ""
      else
        """
        <div style="font-size:13.5px; line-height:1.5; color:#7d877f;">#{EmailTemplates.escaped_text(snippet)}</div>
        """
      end

    """
    #{section_label("Your message")}
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
      <td style="background:#ffffff; border:1px solid #e6e3dc; border-radius:10px; padding:14px 16px;">
        <div style="font-size:14px; font-weight:600; color:#15201c; letter-spacing:-0.01em; margin-bottom:4px;">#{EmailTemplates.escaped_text(subject)}</div>
        #{snippet_html}
      </td>
    </tr></table>
    """
  end

  defp message_snippet(nil), do: ""

  defp message_snippet(text) do
    text =
      text
      |> to_string()
      |> String.replace(~r/\r\n|\r|\n/u, "\n")
      |> String.trim()

    if String.length(text) > 220 do
      "#{String.slice(text, 0, 220)}…"
    else
      text
    end
  end

  defp section_label(text) do
    """
    <p style="margin:0 0 7px; font-size:12px; font-weight:600; letter-spacing:0.04em; text-transform:uppercase; color:#7d877f;">#{EmailTemplates.escaped_text(text)}</p>
    """
  end

  defp delivery_status_mark do
    """
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:6px 0 2px;"><tr>
      <td width="40" height="40" align="center" valign="middle" style="width:40px; height:40px; background:#e3e9ec; border-radius:999px; text-align:center; line-height:40px; font-size:18px; color:#4f6b78;">
        &#9993;
      </td>
    </tr></table>
    """
  end

  defp reply_to_email(nil), do: nil
  defp reply_to_email({_name, address}) when is_binary(address), do: address
  defp reply_to_email(address) when is_binary(address), do: address
  defp reply_to_email(_reply_to_address), do: nil

  defp club_name(opts) do
    opts
    |> Keyword.get(:club_name)
    |> EmailTemplates.sanitize_header_text()
    |> case do
      "" -> nil
      club_name -> club_name
    end
  end

  defp default_text("", fallback), do: fallback
  defp default_text(text, _fallback), do: text

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  rescue
    exception ->
      {:error,
       {:inbound_club_rejection_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:inbound_club_rejection_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error,
       {:inbound_club_rejection_email_delivery_error, {:unexpected_delivery_result, result}}}
end
