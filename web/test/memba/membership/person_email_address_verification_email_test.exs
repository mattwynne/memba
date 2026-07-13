defmodule Memba.Membership.PersonEmailAddressVerificationEmailTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Accounts.AuthEmail
  alias Memba.Membership.PersonEmailAddressVerificationEmail

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

  test "builds and sends a general email-address verification email" do
    Application.put_env(:memba, AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    verification_url =
      "https://app.memba.io/my/settings/email-addresses/verify/token-123?email=alice%40example.com"

    assert :ok =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: " ALICE@Example.COM ",
               verification_url: verification_url,
               person_id: "per_00000000-0000-0000-0000-000000000011"
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Memba", "auth@mail.memba.io"}
    assert email.to == [{"", "alice@example.com"}]
    assert email.subject == "Verify this email address for your Memba account"
    assert email.provider_options == %{message_stream: "outbound-authentication"}

    assert email.text_body =~ "Verify this email address for your Memba account."
    assert email.text_body =~ "Use this secure link to verify this email address:"
    assert email.text_body =~ verification_url
    assert email.text_body =~ "This verification link expires in 15 minutes and can be used once."
    assert email.text_body =~ "If you were not expecting this email, you can ignore it."

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "Verify this email address for your Memba account"
    assert email.html_body =~ "Verify email address"
    assert email.html_body =~ "This verification link expires in 15 minutes and can be used once."
    assert email.html_body =~ "Secured by Memba"
    assert email.html_body =~ "Sent to alice@example.com."

    escaped_verification_url =
      Phoenix.HTML.html_escape(verification_url) |> Phoenix.HTML.safe_to_string()

    assert email.html_body =~ escaped_verification_url
  end

  test "escapes dynamic URL content in HTML while keeping headers general" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    verification_url =
      ~s|http://localhost:4000/my/settings/emails/verify/token?next=<settings>&email="member@example.com"|

    assert :ok =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: "member@example.com",
               verification_url: verification_url
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Memba", "auth@mail.memba.local"}
    assert email.subject == "Verify this email address for your Memba account"
    refute email.subject =~ "\n"

    escaped_verification_url =
      Phoenix.HTML.html_escape(verification_url) |> Phoenix.HTML.safe_to_string()

    assert email.html_body =~ escaped_verification_url
    refute email.html_body =~ ~s|next=<settings>|
    refute email.html_body =~ ~s|email="member@example.com"|
  end

  test "builds a Resend-tagged verification email" do
    Application.put_env(:memba, AuthEmail,
      provider: :resend,
      from: "auth@mail.memba.io",
      message_stream: "auth"
    )

    person_id = "per_00000000-0000-0000-0000-000000000011"

    assert :ok =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: "member@example.com",
               person_id: person_id,
               verification_url: "https://app.memba.io/my/settings/emails/verify/token-123"
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.provider_options == %{
             tags: [
               %{name: "memba_email_kind", value: "person_email_address_verification"},
               %{name: "memba_auth_email_stream", value: "auth"},
               %{name: "memba_person_id", value: person_id}
             ]
           }
  end

  test "rejects invalid inputs before Swoosh handoff" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    assert {:error, :invalid_email} =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: " ",
               verification_url: "http://localhost:4000/my/settings/emails/verify/token"
             })

    assert {:error, :invalid_verification_url} =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: "member@example.com",
               verification_url: " "
             })

    assert_no_email_sent()
  end

  test "does not hand an email to Swoosh when required auth email configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, AuthEmail, from: "auth@mail.memba.io")

    assert {:error, {:person_email_address_verification_email_configuration_error, message}} =
             PersonEmailAddressVerificationEmail.deliver(%{
               email: "member@example.com",
               verification_url: "https://app.memba.io/my/settings/emails/verify/token"
             })

    assert message =~ "Auth email delivery is enabled"
    assert message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"

    assert_no_email_sent()
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
