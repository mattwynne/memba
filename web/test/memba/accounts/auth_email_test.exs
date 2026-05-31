defmodule Memba.Accounts.AuthEmailTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Accounts.AuthEmail

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

  test "builds and sends a Postmark-streamed magic-link email" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    callback_url = "https://app.memba.io/auth/magic/token-123?return_to=%2Fadmin"

    assert :ok = AuthEmail.deliver_magic_link(" ALICE@EXAMPLE.COM ", callback_url)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"", "auth@mail.memba.io"}
    assert email.to == [{"", "alice@example.com"}]
    assert email.subject == "Sign in to Memba"

    assert email.text_body =~ "Use this link to sign in to Memba:"
    assert email.text_body =~ callback_url
    assert email.text_body =~ "This link expires in 15 minutes."

    assert email.html_body =~ "Sign in to Memba"
    assert email.html_body =~ "https://app.memba.io/auth/magic/token-123?return_to=%2Fadmin"
    assert email.html_body =~ "This link expires in 15 minutes."

    assert email.provider_options == %{
             message_stream: "outbound-authentication"
           }
  end

  test "does not hand an email to Swoosh when required auth email configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, AuthEmail, from: "auth@mail.memba.io")

    assert {:error, {:auth_email_configuration_error, message}} =
             AuthEmail.deliver_magic_link(
               "alice@example.com",
               "https://app.memba.io/auth/magic/token"
             )

    assert message =~ "Auth email Postmark delivery is enabled"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"

    assert_no_email_sent()
  end

  test "returns a visible auth email delivery error when Swoosh reports an API failure" do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_owner: self(),
      test_delivery_result: {:error, {401, %{"Message" => "Invalid server token"}}}
    )

    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    assert {:error, {:auth_email_delivery_error, {401, %{"Message" => "Invalid server token"}}}} =
             AuthEmail.deliver_magic_link(
               "alice@example.com",
               "https://app.memba.io/auth/magic/token"
             )

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  test "rejects invalid delivery inputs before Swoosh handoff" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    assert {:error, :invalid_email} =
             AuthEmail.deliver_magic_link("  ", "https://app.memba.io/auth/magic/token")

    assert {:error, :invalid_callback_url} =
             AuthEmail.deliver_magic_link("alice@example.com", "  ")

    assert_no_email_sent()
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
