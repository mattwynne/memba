defmodule Memba.Onboarding.WelcomeEmailTest do
  use Memba.DataCase, async: false

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Accounts.SignInToken
  alias Memba.Membership.Projections.Club
  alias Memba.Onboarding.Request
  alias Memba.Onboarding.WelcomeEmail

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_auth_email_config = Application.get_env(:memba, AuthEmail)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(AuthEmail, original_auth_email_config)
    end)

    :ok
  end

  test "generates a sign-in token and sends a welcome link to the club member home" do
    request = %Request{
      request_id: Memba.ID.generate(:onboarding_request),
      requester_name: "Robin Requester",
      requester_email: " Robin@Example.COM ",
      requested_club_name: "West Coast Paddlers"
    }

    club = %Club{
      club_id: Memba.ID.generate(:club),
      name: "West Coast Paddlers",
      slug: "west-coast-paddlers"
    }

    assert :ok = WelcomeEmail.deliver(%{request: request, club: club})

    assert [%SignInToken{email: "robin@example.com", consumed_at: nil}] =
             Repo.all(SignInToken)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"West Coast Paddlers via Memba", "auth@mail.memba.io"}
    assert email.to == [{"Robin Requester", "robin@example.com"}]
    assert email.subject == "Welcome to West Coast Paddlers on Memba"
    assert email.provider_options == %{message_stream: "outbound-authentication"}

    assert email.text_body =~ "Welcome to West Coast Paddlers on Memba."
    assert email.text_body =~ "http://west-coast-paddlers.lvh.me:4002/auth/sign-in/"
    assert email.text_body =~ "This link expires in 15 minutes and can be used once."

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "West Coast Paddlers"
    assert email.html_body =~ "Welcome to West Coast Paddlers on Memba"
    assert email.html_body =~ "Open West Coast Paddlers"
    assert email.html_body =~ "Button not working? Copy and paste this link into your browser:"
    assert email.html_body =~ "This link expires in 15 minutes and can be used once."
    assert email.html_body =~ "Secured by Memba"
    assert email.html_body =~ "West Coast Paddlers runs on Memba"
    assert email.html_body =~ "Sent to robin@example.com."
    refute email.html_body =~ "<html><body>"
    refute email.html_body =~ "help@memba.io"

    assert [_, callback_url] =
             Regex.run(
               ~r{(http://west-coast-paddlers\.lvh\.me:4002/auth/sign-in/[^\s]+)},
               email.text_body
             )

    callback_uri = URI.parse(callback_url)
    assert callback_uri.host == "west-coast-paddlers.lvh.me"
    assert callback_uri.port == 4002

    assert %{"return_to" => "http://west-coast-paddlers.lvh.me:4002/"} =
             URI.decode_query(callback_uri.query)

    token = callback_uri.path |> Path.basename()
    assert {:ok, %{email: "robin@example.com"}} = Accounts.consume_sign_in_token(token)

    escaped_callback_url =
      callback_url
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    assert email.html_body =~ escaped_callback_url
  end

  test "escapes welcome email content and sanitizes header values from request and club context" do
    request = %Request{
      request_id: Memba.ID.generate(:onboarding_request),
      requester_name: "Robin <Requester>\r\nFrom: forged@example.com",
      requester_email: "robin@example.com",
      requested_club_name: "West <Coast>"
    }

    club = %Club{
      club_id: Memba.ID.generate(:club),
      name: "West <Coast>\r\nBcc: attacker@example.com",
      slug: "west-coast"
    }

    assert :ok = WelcomeEmail.deliver(%{request: request, club: club})

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from ==
             {"West <Coast> Bcc: attacker@example.com via Memba", "auth@mail.memba.io"}

    assert email.to == [{"Robin <Requester> From: forged@example.com", "robin@example.com"}]
    assert email.subject == "Welcome to West <Coast> Bcc: attacker@example.com on Memba"

    refute email.subject =~ "\n"
    refute elem(email.from, 0) =~ "\n"

    {recipient_name, _recipient_email} = List.first(email.to)
    refute recipient_name =~ "\n"

    assert email.html_body =~ "West &lt;Coast&gt; Bcc: attacker@example.com"
    assert email.html_body =~ "Robin &lt;Requester&gt; From: forged@example.com"
    refute email.html_body =~ "<Coast>"
    refute email.html_body =~ "<Requester>"
    refute email.html_body =~ "\r\nBcc"
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
