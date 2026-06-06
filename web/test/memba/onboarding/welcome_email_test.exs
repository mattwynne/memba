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

    assert email.from == {"Memba", "auth@mail.memba.io"}
    assert email.to == [{"Robin Requester", "robin@example.com"}]
    assert email.subject == "Welcome to West Coast Paddlers on Memba"
    assert email.provider_options == %{message_stream: "outbound-authentication"}

    assert email.text_body =~ "Welcome to West Coast Paddlers on Memba."
    assert email.text_body =~ "http://west-coast-paddlers.lvh.me:4002/auth/sign-in/"

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
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
