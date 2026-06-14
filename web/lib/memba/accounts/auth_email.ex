defmodule Memba.Accounts.AuthEmail do
  @moduledoc """
  Sign-in-link authentication email delivery.

  Builds concise text and HTML sign-in-link emails, assigns provider-specific
  categorisation, and hands delivery to `Memba.Mailer`.
  """

  import Swoosh.Email

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailConfig
  alias Memba.EmailTemplates
  alias Memba.ID

  @sender_name "Memba"
  @subject "Sign in to Memba"

  @doc """
  Deliver a sign-in-link sign-in email to a normalized recipient address.
  """
  def deliver_sign_in_link(email, callback_url) do
    with {:ok, recipient_email} <- normalize_recipient_email(email),
         {:ok, callback_url} <- normalize_callback_url(callback_url),
         {:ok, %AuthEmailConfig{} = config} <- auth_email_config() do
      recipient_email
      |> sign_in_link_email(callback_url, config)
      |> deliver_email()
    end
  end

  @doc """
  Deliver a sign-in-link sign-in email with optional group context.

  Callers that already know the group/club context may pass a keyword list or
  map with `:group_name`, `:club_name`, `:group`, or `:club`. When a group name
  is available, the email uses the group-led subject, display name, heading, and
  trust footer while keeping the configured Memba sender address and provider
  options unchanged.
  """
  def deliver_sign_in_link(email, callback_url, opts) do
    context = sign_in_context(opts)

    with {:ok, recipient_email} <- normalize_recipient_email(email),
         {:ok, callback_url} <- normalize_callback_url(callback_url),
         {:ok, %AuthEmailConfig{} = config} <- auth_email_config() do
      recipient_email
      |> sign_in_link_email(callback_url, config, context)
      |> deliver_email()
    end
  end

  defp normalize_recipient_email(email) do
    case Accounts.normalize_email(email) do
      nil -> {:error, :invalid_email}
      normalized_email -> {:ok, normalized_email}
    end
  end

  defp normalize_callback_url(callback_url) when is_binary(callback_url) do
    case String.trim(callback_url) do
      "" -> {:error, :invalid_callback_url}
      normalized_url -> {:ok, normalized_url}
    end
  end

  defp normalize_callback_url(_callback_url), do: {:error, :invalid_callback_url}

  defp auth_email_config do
    case AuthEmailConfig.from_application_env() do
      {:ok, config} -> {:ok, config}
      {:error, message} -> {:error, {:auth_email_configuration_error, message}}
    end
  end

  defp sign_in_link_email(recipient_email, callback_url, %AuthEmailConfig{} = config) do
    sign_in_link_email(recipient_email, callback_url, config, %{group_name: nil})
  end

  defp sign_in_link_email(recipient_email, callback_url, %AuthEmailConfig{} = config, context) do
    new()
    |> from({sender_name(context), config.from})
    |> to(recipient_email)
    |> subject(subject(context))
    |> text_body(sign_in_text_body(callback_url, context))
    |> html_body(html_body(callback_url, recipient_email, context))
    |> put_provider_options(config, context)
  end

  defp put_provider_options(email, %AuthEmailConfig{provider: :resend}, _context) do
    put_provider_option(email, :tags, [
      %{name: "memba_email_kind", value: "auth_sign_in_link"},
      %{name: "memba_auth_email_stream", value: "auth"}
    ])
  end

  defp put_provider_options(email, %AuthEmailConfig{} = config, context) do
    email
    |> put_provider_option(:message_stream, config.message_stream)
    |> put_postmark_auth_request_metadata(context)
  end

  defp put_postmark_auth_request_metadata(email, %{auth_email_request_id: request_id})
       when is_binary(request_id) do
    put_provider_option(email, :metadata, %{
      "memba_email_kind" => "auth_sign_in_link",
      "memba_auth_email_request_id" => request_id
    })
  end

  defp put_postmark_auth_request_metadata(email, _context), do: email

  defp sign_in_text_body(callback_url, context) do
    """
    Use this link to sign in to #{target_name(context)}:

    #{callback_url}

    This link expires in 15 minutes and can be used once. If you did not request it, you can safely ignore this email.
    """
  end

  defp html_body(callback_url, recipient_email, context) do
    title = subject(context)

    content = [
      header(context),
      EmailTemplates.card_section([
        EmailTemplates.heading(title),
        EmailTemplates.paragraph(
          "Use the button below to sign in. You'll go straight to your account — there's no password to remember.",
          margin: "0 0 18px"
        ),
        EmailTemplates.primary_action("Sign in", callback_url),
        EmailTemplates.paragraph("This link expires in 15 minutes and can be used once.",
          margin: "0 0 20px",
          color: "#7d877f",
          font_size: "13px"
        ),
        sign_in_reassurance()
      ])
    ]

    footer = [
      EmailTemplates.trust_footer(group_name: context.group_name),
      EmailTemplates.memba_footer(
        group_name: context.group_name,
        recipient_email: recipient_email
      )
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader: preheader(context),
      content: content,
      footer: footer
    )
  end

  defp sign_in_context(opts) do
    %{
      group_name: group_name_from_context(opts),
      auth_email_request_id: auth_email_request_id_from_context(opts)
    }
  end

  defp group_name_from_context(opts) do
    direct_group_name =
      opts
      |> option_value([:group_name, :club_name, :name])
      |> present_header_text()

    nested_group_name =
      opts
      |> option_value([:group, :club, :group_context, :club_context])
      |> context_name()

    direct_group_name || nested_group_name
  end

  defp context_name(nil), do: nil

  defp context_name(context) do
    context
    |> option_value([:group_name, :club_name, :name])
    |> present_header_text()
  end

  defp auth_email_request_id_from_context(opts) do
    opts
    |> option_value([:auth_email_request_id, :request_id])
    |> cast_auth_email_request_id()
  end

  defp cast_auth_email_request_id(value) when is_binary(value) do
    value
    |> String.trim()
    |> then(fn value ->
      case ID.cast(:auth_email_request, value) do
        {:ok, request_id} -> request_id
        :error -> nil
      end
    end)
  end

  defp cast_auth_email_request_id(_value), do: nil

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

  defp present_header_text(value) do
    value
    |> EmailTemplates.sanitize_header_text()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp sender_name(%{group_name: nil}), do: @sender_name
  defp sender_name(%{group_name: group_name}), do: "#{group_name} via Memba"

  defp subject(%{group_name: nil}), do: @subject
  defp subject(%{group_name: group_name}), do: "Sign in to #{group_name}"

  defp target_name(%{group_name: nil}), do: "Memba"
  defp target_name(%{group_name: group_name}), do: group_name

  defp preheader(context) do
    "Your sign-in link for #{target_name(context)} — it expires in 15 minutes. If you didn't request it, ignore this email."
  end

  defp header(%{group_name: nil}), do: EmailTemplates.memba_header(label: "Sign-in link")

  defp header(%{group_name: group_name}) do
    EmailTemplates.group_header(group_name, label: "Sign-in link")
  end

  defp sign_in_reassurance do
    """
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
      <td style="border-top:1px solid #e6e3dc; padding-top:16px;">
        #{EmailTemplates.paragraph("Didn't ask to sign in? You can safely ignore this email — no one can get into your account without the link above.", margin: "0", color: "#7d877f", font_size: "13px")}
      </td>
    </tr></table>
    """
  end

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  rescue
    exception ->
      {:error,
       {:auth_email_delivery_exception, exception.__struct__, Exception.message(exception)}}
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:auth_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do: {:error, {:auth_email_delivery_error, {:unexpected_delivery_result, result}}}
end
