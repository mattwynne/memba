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

  test "builds and sends a Postmark-streamed sign-in-link email" do
    Application.put_env(:memba, AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    request_id = Memba.ID.generate(:auth_email_request)

    callback_url =
      "https://app.memba.io/auth/sign-in/token-123?return_to=%2Fadmin&client=ipad"

    assert :ok =
             AuthEmail.deliver_sign_in_link(" ALICE@EXAMPLE.COM ", callback_url,
               auth_email_request_id: request_id
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Memba", "auth@mail.memba.io"}
    assert email.to == [{"", "alice@example.com"}]
    assert email.subject == "Sign in to Memba"

    assert email.text_body =~ "Use this link to sign in to Memba:"
    assert email.text_body =~ callback_url
    assert email.text_body =~ "This link expires in 15 minutes and can be used once."
    assert email.text_body =~ "you can safely ignore this email"

    assert email.html_body =~ "Sign in to Memba"

    assert email.html_body =~
             "https://app.memba.io/auth/sign-in/token-123?return_to=%2Fadmin&amp;client=ipad"

    assert email.html_body =~ "Button not working? Copy and paste this link into your browser:"
    assert email.html_body =~ "This link expires in 15 minutes and can be used once."
    assert email.html_body =~ "Secured by Memba"
    assert_memba_sprig_branding(email.html_body)
    assert_standard_memba_footer(email.html_body, recipient_email: "alice@example.com")

    assert email.provider_options == %{
             message_stream: "outbound-authentication",
             metadata: %{
               "memba_email_kind" => "auth_sign_in_link",
               "memba_auth_email_request_id" => request_id
             }
           }
  end

  test "builds and sends a Resend-tagged sign-in-link email" do
    Application.put_env(:memba, AuthEmail,
      provider: :resend,
      from: "auth@mail.memba.io",
      message_stream: "auth"
    )

    assert :ok =
             AuthEmail.deliver_sign_in_link(
               " ALICE@EXAMPLE.COM ",
               "https://app.memba.io/auth/sign-in/token-123"
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Memba", "auth@mail.memba.io"}
    assert email.to == [{"", "alice@example.com"}]
    assert email.subject == "Sign in to Memba"

    assert email.text_body =~ "Use this link to sign in to Memba:"
    assert email.text_body =~ "https://app.memba.io/auth/sign-in/token-123"
    assert email.text_body =~ "This link expires in 15 minutes and can be used once."

    assert email.html_body =~ "Sign in to Memba"
    assert email.html_body =~ ~s|href="https://app.memba.io/auth/sign-in/token-123"|
    assert email.html_body =~ "Button not working? Copy and paste this link into your browser:"
    assert email.html_body =~ "Secured by Memba"
    assert_memba_sprig_branding(email.html_body)
    assert_standard_memba_footer(email.html_body, recipient_email: "alice@example.com")

    assert email.provider_options == %{
             tags: [
               %{name: "memba_email_kind", value: "auth_sign_in_link"},
               %{name: "memba_auth_email_stream", value: "auth"}
             ]
           }
  end

  test "builds a group-led sign-in-link email when group context is supplied" do
    Application.put_env(:memba, AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    callback_url = "https://choir.memba.test/auth/sign-in/token-123"
    group_name = "Wessex <Choir>\r\nBcc: attacker@example.com"

    assert :ok =
             AuthEmail.deliver_sign_in_link("member@example.com", callback_url,
               group_name: group_name
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from ==
             {"Wessex <Choir> Bcc: attacker@example.com via Memba", "auth@mail.memba.io"}

    assert email.subject == "Sign in to Wessex <Choir> Bcc: attacker@example.com"
    refute email.subject =~ "\n"
    refute elem(email.from, 0) =~ "\n"

    assert email.text_body =~
             "Use this link to sign in to Wessex <Choir> Bcc: attacker@example.com:"

    assert email.text_body =~ "This link expires in 15 minutes and can be used once."

    assert email.html_body =~ "Wessex &lt;Choir&gt; Bcc: attacker@example.com"
    assert email.html_body =~ "Sign in to Wessex &lt;Choir&gt; Bcc: attacker@example.com"
    assert email.html_body =~ "Wessex &lt;Choir&gt; Bcc: attacker@example.com runs on Memba"

    assert_standard_memba_footer(email.html_body,
      group_name: "Wessex <Choir> Bcc: attacker@example.com",
      recipient_email: "member@example.com"
    )

    refute email.html_body =~ "\r\nBcc"
    refute email.html_body =~ "<Choir>"
  end

  test "accepts nested club context for group-led sign-in-link email" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    club = %{name: "Kootenay Mountaineering Club", slug: "kmc"}

    assert :ok =
             AuthEmail.deliver_sign_in_link(
               "member@example.com",
               "http://kmc.lvh.me:4000/auth/sign-in/token",
               club: club
             )

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.from == {"Kootenay Mountaineering Club via Memba", "auth@mail.memba.local"}
    assert email.subject == "Sign in to Kootenay Mountaineering Club"
    assert email.html_body =~ "Kootenay Mountaineering Club"
    assert email.provider_options == %{message_stream: "development-auth"}
  end

  test "sends local auth email without requiring a Postmark server token" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    assert :ok =
             AuthEmail.deliver_sign_in_link(
               "matt@memba.io",
               "http://localhost:4000/auth/sign-in/token"
             )

    assert_received {:email, %Swoosh.Email{} = email}
    assert email.from == {"Memba", "auth@mail.memba.local"}
    assert email.to == [{"", "matt@memba.io"}]
    assert email.subject == "Sign in to Memba"
    assert email.text_body =~ "http://localhost:4000/auth/sign-in/token"
    assert email.html_body =~ "Sign in to Memba"
    assert email.html_body =~ ~s|href="http://localhost:4000/auth/sign-in/token"|
    assert email.html_body =~ "Button not working? Copy and paste this link into your browser:"
    assert email.provider_options == %{message_stream: "development-auth"}
  end

  test "does not hand an email to Swoosh when required auth email configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, AuthEmail, from: "auth@mail.memba.io")

    assert {:error, {:auth_email_configuration_error, message}} =
             AuthEmail.deliver_sign_in_link(
               "alice@example.com",
               "https://app.memba.io/auth/sign-in/token"
             )

    assert message =~ "Auth email delivery is enabled"
    assert message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"
    refute message =~ "MEMBA_POSTMARK_SERVER_TOKEN"

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
             AuthEmail.deliver_sign_in_link(
               "alice@example.com",
               "https://app.memba.io/auth/sign-in/token"
             )

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  test "rejects invalid delivery inputs before Swoosh handoff" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    assert {:error, :invalid_email} =
             AuthEmail.deliver_sign_in_link("  ", "https://app.memba.io/auth/sign-in/token")

    assert {:error, :invalid_callback_url} =
             AuthEmail.deliver_sign_in_link("alice@example.com", "  ")

    assert_no_email_sent()
  end

  defp assert_memba_sprig_branding(html_body) do
    assert html_body =~
             ~s|d="M32 33 C40 32 46 26 48 16 C39 17.5 33 24 32 33 Z"|

    refute html_body =~ ~s|d="M 18 34 L 28 44 L 46 24"|
  end

  defp assert_standard_memba_footer(html_body, opts) do
    case Keyword.get(opts, :group_name) do
      nil ->
        assert html_body =~ ~s|Delivered by <a href="https://memba.io"|

      group_name ->
        assert html_body =~ "Delivered for #{html_escape(group_name)} by"
        assert html_body =~ ~s|href="https://memba.io"|
    end

    assert html_body =~ "Sent to #{Keyword.fetch!(opts, :recipient_email)}."
    refute html_body =~ "help@memba.io"
  end

  defp html_escape(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
