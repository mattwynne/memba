defmodule Memba.Onboarding.WelcomeEmail do
  @moduledoc """
  Builds and delivers welcome emails for converted onboarding requesters.

  The welcome link uses the shared sign-in-link token store and lands on the
  converted club's member home after authentication.
  """

  import Swoosh.Email

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailConfig
  alias Memba.EmailTemplates
  alias Memba.Onboarding.Request
  alias MembaWeb.ClubSite

  @doc """
  Deliver a welcome email for a completed request-to-club conversion.
  """
  def deliver(%{request: %Request{} = request, club: club}) do
    with {:ok, %AuthEmailConfig{} = config} <- auth_email_config(),
         {:ok, %{email: recipient_email, token: token}} <-
           Accounts.create_sign_in_token(request.requester_email) do
      callback_url = welcome_callback_url(club, token)

      request
      |> welcome_email(recipient_email, club, callback_url, config)
      |> deliver_email()
    end
  rescue
    exception ->
      {:error,
       {:onboarding_welcome_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  defp auth_email_config do
    case AuthEmailConfig.from_application_env() do
      {:ok, config} -> {:ok, config}
      {:error, message} -> {:error, {:onboarding_welcome_email_configuration_error, message}}
    end
  end

  defp welcome_callback_url(club, token) do
    club
    |> ClubSite.url("/auth/sign-in/#{token}")
    |> put_query(%{"return_to" => ClubSite.url(club, "/")})
  end

  defp put_query(url, params) do
    url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(params))
    |> URI.to_string()
  end

  defp welcome_email(
         %Request{} = request,
         recipient_email,
         club,
         callback_url,
         %AuthEmailConfig{} = config
       ) do
    context = welcome_context(request, club)

    new()
    |> from({context.sender_name, config.from})
    |> to({context.requester_name, recipient_email})
    |> subject(context.subject)
    |> text_body(welcome_text_body(context, callback_url))
    |> html_body(welcome_html_body(context, recipient_email, callback_url))
    |> put_provider_options(config, request)
  end

  defp put_provider_options(
         email,
         %AuthEmailConfig{provider: :resend} = config,
         %Request{} = request
       ) do
    put_provider_option(email, :tags, [
      %{name: "memba_email_kind", value: "onboarding_welcome"},
      %{name: "memba_onboarding_request_id", value: request.request_id},
      %{name: "memba_auth_email_stream", value: config.message_stream}
    ])
  end

  defp put_provider_options(email, %AuthEmailConfig{} = config, %Request{} = _request) do
    put_provider_option(email, :message_stream, config.message_stream)
  end

  defp welcome_context(%Request{} = request, club) do
    group_name =
      club
      |> Map.get(:name)
      |> present_header_text("your group")

    requester_name = present_header_text(request.requester_name, "")

    %{
      group_name: group_name,
      requester_name: requester_name,
      sender_name: "#{group_name} via Memba",
      subject: "Welcome to #{group_name} on Memba"
    }
  end

  defp present_header_text(value, fallback) do
    value
    |> EmailTemplates.sanitize_header_text()
    |> case do
      "" -> fallback
      text -> text
    end
  end

  defp welcome_text_body(context, callback_url) do
    """
    Hi #{context.requester_name},

    Welcome to #{context.group_name} on Memba.

    Use this secure link to sign in and open your new club member home:

    #{callback_url}

    This link expires in 15 minutes and can be used once. If you were not expecting this email, you can ignore it.
    """
  end

  defp welcome_html_body(context, recipient_email, callback_url) do
    title = context.subject

    content = [
      EmailTemplates.group_header(context.group_name, label: "Welcome"),
      EmailTemplates.card_section([
        EmailTemplates.heading(title),
        EmailTemplates.paragraph("Hi #{context.requester_name},", margin: "0 0 12px"),
        EmailTemplates.paragraph(
          "You're now set up with #{context.group_name} on Memba. Use the secure link below to sign in and open your new club member home.",
          margin: "0 0 18px"
        ),
        EmailTemplates.primary_action("Open #{context.group_name}", callback_url,
          width: "220px",
          fallback_label: "Button not working? Copy and paste this link into your browser:"
        ),
        EmailTemplates.paragraph(
          "This link expires in 15 minutes and can be used once.",
          margin: "0 0 20px",
          color: "#7d877f",
          font_size: "13px"
        ),
        welcome_reassurance()
      ])
    ]

    footer = [
      EmailTemplates.trust_footer(group_name: context.group_name),
      welcome_footer(recipient_email)
    ]

    EmailTemplates.render_shell(
      title: title,
      preheader: "Welcome to #{context.group_name} — your sign-in link expires in 15 minutes.",
      content: content,
      footer: footer
    )
  end

  defp welcome_reassurance do
    """
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
      <td style="border-top:1px solid #e6e3dc; padding-top:16px;">
        #{EmailTemplates.paragraph("If you were not expecting this welcome email, you can safely ignore it — no one can get into your account without the link above.", margin: "0", color: "#7d877f", font_size: "13px")}
      </td>
    </tr></table>
    """
  end

  defp welcome_footer(recipient_email) do
    """
        <tr>
          <td class="gutter" style="padding:14px 28px 24px; font-size:12px; line-height:1.6; color:#7d877f;">
            Sent to #{EmailTemplates.escaped_text(recipient_email)}. Need a hand? Contact Memba support.
          </td>
        </tr>
    """
  end

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:onboarding_welcome_email_delivery_error, reason}}

  defp normalize_delivery_result(result),
    do:
      {:error, {:onboarding_welcome_email_delivery_error, {:unexpected_delivery_result, result}}}
end
