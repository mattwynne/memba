defmodule Memba.Accounts.AuthEmail do
  @moduledoc """
  Magic-link authentication email delivery.

  Builds concise text and HTML magic-link emails, assigns the configured
  Postmark message stream, and hands delivery to `Memba.Mailer`.
  """

  import Swoosh.Email

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmailConfig

  @subject "Sign in to Memba"

  @doc """
  Deliver a magic-link sign-in email to a normalized recipient address.
  """
  def deliver_magic_link(email, callback_url) do
    with {:ok, recipient_email} <- normalize_recipient_email(email),
         {:ok, callback_url} <- normalize_callback_url(callback_url),
         {:ok, %AuthEmailConfig{} = config} <- auth_email_config() do
      recipient_email
      |> magic_link_email(callback_url, config)
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

  defp magic_link_email(recipient_email, callback_url, %AuthEmailConfig{} = config) do
    new()
    |> from(config.from)
    |> to(recipient_email)
    |> subject(@subject)
    |> text_body(text_body(callback_url))
    |> html_body(html_body(callback_url))
    |> put_provider_option(:message_stream, config.message_stream)
  end

  defp text_body(callback_url) do
    """
    Use this link to sign in to Memba:

    #{callback_url}

    This link expires in 15 minutes. If you did not request it, you can ignore this email.
    """
  end

  defp html_body(callback_url) do
    escaped_url = html_escape_to_string(callback_url)

    """
    <html><body>
    <p>Use this link to sign in to Memba:</p>
    <p><a href="#{escaped_url}">Sign in to Memba</a></p>
    <p>This link expires in 15 minutes. If you did not request it, you can ignore this email.</p>
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
