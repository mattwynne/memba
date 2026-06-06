defmodule Memba.Onboarding.WelcomeEmail do
  @moduledoc """
  Builds and delivers welcome emails for converted onboarding requesters.

  The welcome link uses the shared sign-in-link token store and lands on the
  converted club's member home after authentication.
  """

  import Swoosh.Email

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailConfig
  alias Memba.Onboarding.Request
  alias MembaWeb.ClubSite

  @sender_name "Memba"

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
    new()
    |> from({@sender_name, config.from})
    |> to({request.requester_name, recipient_email})
    |> subject("Welcome to #{club.name} on Memba")
    |> text_body(text_body(request, club, callback_url))
    |> html_body(html_body(request, club, callback_url))
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

  defp text_body(%Request{} = request, club, callback_url) do
    """
    Hi #{request.requester_name},

    Welcome to #{club.name} on Memba.

    Use this secure link to sign in and open your new club member home:

    #{callback_url}

    This link expires in 15 minutes. If you were not expecting this email, you can ignore it.
    """
  end

  defp html_body(%Request{} = request, club, callback_url) do
    escaped_name = html_escape_to_string(request.requester_name)
    escaped_club_name = html_escape_to_string(club.name)
    escaped_url = html_escape_to_string(callback_url)

    """
    <html><body>
    <p>Hi #{escaped_name},</p>
    <p>Welcome to #{escaped_club_name} on Memba.</p>
    <p>Use this secure link to sign in and open your new club member home:</p>
    <p><a href="#{escaped_url}">Open #{escaped_club_name} on Memba</a></p>
    <p>This link expires in 15 minutes. If you were not expecting this email, you can ignore it.</p>
    </body></html>
    """
  end

  defp html_escape_to_string(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
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
