defmodule Memba.Membership.PersonEmailAddressVerificationEmail do
  @moduledoc """
  Person email-address verification email delivery.

  The verification link is built by the web layer once the callback route exists;
  this module owns the provider-neutral email composition and handoff to
  `Memba.Mailer`. Verification emails intentionally use the auth email sender
  configuration because the link proves mailbox control for a signed-in identity.
  """

  import Swoosh.Email

  alias Memba.Accounts.AuthEmailConfig
  alias Memba.EmailTemplates
  alias Memba.ID
  alias Memba.Membership.EmailAddresses

  @subject "Verify this email address for your Memba account"

  @doc """
  Deliver a person email-address verification email.

  Required attributes are:

    * `:email` / `"email"` - recipient email address being verified
    * `:verification_url` / `"verification_url"` - one-use verification link

  Optional `:person_id` / `"person_id"` is used only for provider metadata/tags
  when available.
  """
  def deliver(attrs) when is_map(attrs) do
    with {:ok, recipient_email} <- recipient_email(attrs),
         {:ok, verification_url} <- verification_url(attrs),
         {:ok, %AuthEmailConfig{} = config} <- auth_email_config() do
      context = verification_context(attrs)

      recipient_email
      |> verification_email(context, verification_url, config)
      |> deliver_email()
    end
  rescue
    exception ->
      {:error,
       {:person_email_address_verification_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  def deliver(_attrs), do: {:error, :invalid_person_email_address_verification_email_attrs}

  defp recipient_email(attrs) do
    attrs
    |> option_value([:email, :recipient_email])
    |> EmailAddresses.normalize_email()
    |> case do
      {:ok, %{normalized_email: normalized_email}} -> {:ok, normalized_email}
      {:error, :invalid_email} -> {:error, :invalid_email}
    end
  end

  defp verification_url(attrs) do
    attrs
    |> option_value([:verification_url, :url, :callback_url])
    |> normalize_verification_url()
  end

  defp normalize_verification_url(url) when is_binary(url) do
    case String.trim(url) do
      "" -> {:error, :invalid_verification_url}
      url -> {:ok, url}
    end
  end

  defp normalize_verification_url(_url), do: {:error, :invalid_verification_url}

  defp auth_email_config do
    case AuthEmailConfig.from_application_env() do
      {:ok, config} ->
        {:ok, config}

      {:error, message} ->
        {:error, {:person_email_address_verification_email_configuration_error, message}}
    end
  end

  defp verification_context(attrs) do
    %{person_id: attrs |> option_value([:person_id]) |> cast_person_id()}
  end

  defp cast_person_id(value) when is_binary(value) do
    value
    |> String.trim()
    |> then(fn value ->
      case ID.cast(:person, value) do
        {:ok, person_id} -> person_id
        :error -> ""
      end
    end)
  end

  defp cast_person_id(_value), do: ""

  defp verification_email(recipient_email, context, verification_url, %AuthEmailConfig{} = config) do
    new()
    |> from({"Memba", config.from})
    |> to(recipient_email)
    |> subject(@subject)
    |> text_body(verification_text_body(verification_url))
    |> html_body(verification_html_body(recipient_email, verification_url))
    |> put_provider_options(config, context)
  end

  defp put_provider_options(email, %AuthEmailConfig{provider: :resend} = config, context) do
    tags =
      [
        %{name: "memba_email_kind", value: "person_email_address_verification"},
        %{name: "memba_auth_email_stream", value: config.message_stream},
        optional_tag("memba_person_id", context.person_id)
      ]
      |> Enum.reject(&is_nil/1)

    put_provider_option(email, :tags, tags)
  end

  defp put_provider_options(email, %AuthEmailConfig{} = config, _context) do
    put_provider_option(email, :message_stream, config.message_stream)
  end

  defp optional_tag(_name, ""), do: nil
  defp optional_tag(name, value), do: %{name: name, value: value}

  defp verification_text_body(verification_url) do
    """
    Verify this email address for your Memba account.

    Use this secure link to verify this email address:

    #{verification_url}

    This verification link expires in 15 minutes and can be used once. If you were not expecting this email, you can ignore it.
    """
  end

  defp verification_html_body(recipient_email, verification_url) do
    content = [
      EmailTemplates.memba_header(label: "Email verification"),
      EmailTemplates.card_section([
        EmailTemplates.heading(@subject),
        EmailTemplates.paragraph(
          "Use the secure link below to verify this email address for your Memba account.",
          margin: "0 0 18px"
        ),
        EmailTemplates.primary_action("Verify email address", verification_url,
          width: "220px",
          fallback_label:
            "Button not working? Copy and paste this verification link into your browser:"
        ),
        EmailTemplates.paragraph(
          "This verification link expires in 15 minutes and can be used once.",
          margin: "0 0 20px",
          color: "#7d877f",
          font_size: "13px"
        ),
        verification_reassurance()
      ])
    ]

    footer = [
      EmailTemplates.trust_footer(),
      EmailTemplates.memba_footer(
        recipient_email: recipient_email,
        reason: "You're getting this because this email address was added to a Memba user."
      )
    ]

    EmailTemplates.render_shell(
      title: @subject,
      preheader:
        "Verify this email address for your Memba account — the link expires in 15 minutes.",
      content: content,
      footer: footer
    )
  end

  defp verification_reassurance do
    """
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
      <td style="border-top:1px solid #e6e3dc; padding-top:16px;">
        #{EmailTemplates.paragraph("If you were not expecting this email, you can safely ignore it — this address will not be verified unless the link above is opened.", margin: "0", color: "#7d877f", font_size: "13px")}
      </td>
    </tr></table>
    """
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
    do: {:error, {:person_email_address_verification_email_delivery_error, reason}}

  defp normalize_delivery_result(result) do
    {:error,
     {:person_email_address_verification_email_delivery_error,
      {:unexpected_delivery_result, result}}}
  end
end
