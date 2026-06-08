defmodule Memba.Membership.ClubMemberInvitationEmail do
  @moduledoc """
  Club member invitation email delivery.

  The invitation link is built by the web layer once the callback route exists;
  this module owns the provider-neutral email composition and handoff to
  `Memba.Mailer`. Invitation emails intentionally use the auth email sender
  configuration because the link proves email control and grants membership.
  """

  import Swoosh.Email

  alias Memba.Accounts.AuthEmailConfig
  alias Memba.EmailTemplates
  alias Memba.Membership.EmailAddresses

  @doc """
  Deliver a club member invitation email.

  Required attributes are:

    * `:email` / `"email"` - invited recipient email address
    * `:club` / `"club"` - map or struct containing a non-blank `:name` / `"name"`
    * `:invitation_url` / `"invitation_url"` - one-use invitation link

  Optional `:invitation_id` and club `:club_id` values are used only for provider
  metadata/tags when available.
  """
  def deliver(attrs) when is_map(attrs) do
    with {:ok, recipient_email} <- recipient_email(attrs),
         {:ok, context} <- invitation_context(attrs),
         {:ok, invitation_url} <- invitation_url(attrs),
         {:ok, %AuthEmailConfig{} = config} <- auth_email_config() do
      recipient_email
      |> invitation_email(context, invitation_url, config)
      |> deliver_email()
    end
  rescue
    exception ->
      {:error,
       {:club_member_invitation_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  def deliver(_attrs), do: {:error, :invalid_invitation_email_attrs}

  defp recipient_email(attrs) do
    attrs
    |> option_value([:email, :invited_email, :recipient_email])
    |> EmailAddresses.normalize_email()
    |> case do
      {:ok, %{normalized_email: normalized_email}} -> {:ok, normalized_email}
      {:error, :invalid_email} -> {:error, :invalid_email}
    end
  end

  defp invitation_context(attrs) do
    club = option_value(attrs, [:club])
    club_name = club |> option_value([:name, :club_name]) |> present_header_text()

    if club_name == "" do
      {:error, :invalid_club}
    else
      {:ok,
       %{
         club_id: club |> option_value([:club_id]) |> present_header_text(),
         club_name: club_name,
         invitation_id: attrs |> option_value([:invitation_id]) |> present_header_text()
       }}
    end
  end

  defp invitation_url(attrs) do
    attrs
    |> option_value([:invitation_url, :url, :callback_url])
    |> normalize_invitation_url()
  end

  defp normalize_invitation_url(url) when is_binary(url) do
    case String.trim(url) do
      "" -> {:error, :invalid_invitation_url}
      url -> {:ok, url}
    end
  end

  defp normalize_invitation_url(_url), do: {:error, :invalid_invitation_url}

  defp auth_email_config do
    case AuthEmailConfig.from_application_env() do
      {:ok, config} -> {:ok, config}
      {:error, message} -> {:error, {:club_member_invitation_email_configuration_error, message}}
    end
  end

  defp invitation_email(recipient_email, context, invitation_url, %AuthEmailConfig{} = config) do
    new()
    |> from({sender_name(context), config.from})
    |> to(recipient_email)
    |> subject(subject(context))
    |> text_body(invitation_text_body(context, invitation_url))
    |> html_body(invitation_html_body(context, recipient_email, invitation_url))
    |> put_provider_options(config, context)
  end

  defp put_provider_options(email, %AuthEmailConfig{provider: :resend} = config, context) do
    tags =
      [
        %{name: "memba_email_kind", value: "club_member_invitation"},
        %{name: "memba_auth_email_stream", value: config.message_stream},
        optional_tag("memba_club_id", context.club_id),
        optional_tag("memba_invitation_id", context.invitation_id)
      ]
      |> Enum.reject(&is_nil/1)

    put_provider_option(email, :tags, tags)
  end

  defp put_provider_options(email, %AuthEmailConfig{} = config, _context) do
    put_provider_option(email, :message_stream, config.message_stream)
  end

  defp optional_tag(_name, ""), do: nil
  defp optional_tag(name, value), do: %{name: name, value: value}

  defp invitation_text_body(context, invitation_url) do
    """
    You're invited to join #{context.club_name} on Memba.

    Use this secure invitation link to accept the invitation:

    #{invitation_url}

    This invitation link can be used once to create your membership. If you were not expecting this invitation, you can ignore it.
    """
  end

  defp invitation_html_body(context, recipient_email, invitation_url) do
    title = subject(context)

    content = [
      EmailTemplates.group_header(context.club_name, label: "Invitation"),
      EmailTemplates.card_section([
        EmailTemplates.heading(title),
        EmailTemplates.paragraph(
          "You've been invited to join #{context.club_name} on Memba. Use the secure link below to accept the invitation.",
          margin: "0 0 18px"
        ),
        EmailTemplates.primary_action("Accept invitation", invitation_url,
          width: "210px",
          fallback_label:
            "Button not working? Copy and paste this invitation link into your browser:"
        ),
        EmailTemplates.paragraph(
          "This invitation link can be used once to create your membership.",
          margin: "0 0 20px",
          color: "#7d877f",
          font_size: "13px"
        ),
        invitation_reassurance()
      ])
    ]

    footer = [
      invitation_trust_footer(context),
      EmailTemplates.memba_footer(
        group_name: context.club_name,
        recipient_email: recipient_email,
        reason:
          "You're getting this because someone invited this email address to join #{context.club_name}."
      )
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader:
        "You're invited to join #{context.club_name} — use this one-use invitation link to accept.",
      content: content,
      footer: footer
    )
  end

  defp invitation_reassurance do
    """
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
      <td style="border-top:1px solid #e6e3dc; padding-top:16px;">
        #{EmailTemplates.paragraph("If you were not expecting this invitation, you can safely ignore it — no membership will be created unless the link is accepted.", margin: "0", color: "#7d877f", font_size: "13px")}
      </td>
    </tr></table>
    """
  end

  defp invitation_trust_footer(context) do
    club_name = EmailTemplates.escaped_text(context.club_name)

    """
        <tr>
          <td class="gutter" style="padding:18px 28px 22px; background:#ecf2ee; border-top:1px solid #d2e0d7;">
            <table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin-bottom:8px;"><tr>
              <td style="vertical-align:middle; font-size:13px; font-weight:600; color:#173a35; letter-spacing:-0.01em;">Secured by Memba</td>
            </tr></table>
            <p style="margin:0; font-size:12.5px; line-height:1.55; color:#102b27;">#{club_name} runs on Memba. This is a genuine invitation link &mdash; it can be used once to create membership for this invited email address. We&rsquo;ll never ask for a password or payment by email.</p>
          </td>
        </tr>
    """
  end

  defp sender_name(context), do: "#{context.club_name} via Memba"
  defp subject(context), do: "You're invited to join #{context.club_name}"

  defp present_header_text(value) do
    value
    |> EmailTemplates.sanitize_header_text()
    |> String.trim()
  end

  defp option_value(opts, keys) when is_list(opts) do
    if Keyword.keyword?(opts) do
      Enum.find_value(keys, &Keyword.get(opts, &1))
    end
  end

  defp option_value(%{} = opts, keys) do
    Enum.find_value(keys, fn key ->
      Map.get(opts, key) || Map.get(opts, Atom.to_string(key))
    end)
  end

  defp option_value(_opts, _keys), do: nil

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:club_member_invitation_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error,
       {:club_member_invitation_email_delivery_error, {:unexpected_delivery_result, result}}}
end
