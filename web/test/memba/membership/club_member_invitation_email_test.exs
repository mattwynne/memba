defmodule Memba.Membership.ClubMemberInvitationEmailTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Accounts.AuthEmail
  alias Memba.Membership.ClubMemberInvitationEmail

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

  test "builds and sends a club-context invitation email with a one-use link" do
    Application.put_env(:memba, AuthEmail,
      provider: :postmark,
      from: "auth@mail.memba.io",
      message_stream: "outbound-authentication"
    )

    invitation_url = "https://app.memba.io/invitations/club-members/token-123?continue=club"

    assert :ok =
             ClubMemberInvitationEmail.deliver(%{
               email: " ROBIN@Example.COM ",
               club: %{
                 club_id: "club_0123456789ABCDEFGHJKMNPQRS",
                 name: "West Coast Paddlers"
               },
               invitation_id: "club_invitation_0123456789ABCDEFGHJKMNPQRS",
               invitation_url: invitation_url
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"West Coast Paddlers via Memba", "auth@mail.memba.io"}
    assert email.to == [{"", "robin@example.com"}]
    assert email.subject == "You're invited to join West Coast Paddlers"
    assert email.provider_options == %{message_stream: "outbound-authentication"}

    assert email.text_body =~ "You're invited to join West Coast Paddlers on Memba."
    assert email.text_body =~ "Use this secure invitation link to accept the invitation:"
    assert email.text_body =~ invitation_url
    assert email.text_body =~ "This invitation link can be used once to create your membership."
    assert email.text_body =~ "If you were not expecting this invitation, you can ignore it."
    refute email.text_body =~ "expires"

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "West Coast Paddlers"
    assert email.html_body =~ "Accept invitation"
    assert email.html_body =~ "This invitation link can be used once to create your membership."
    assert email.html_body =~ "Secured by Memba"
    assert email.html_body =~ "Sent to robin@example.com."
    refute email.html_body =~ "expires"

    escaped_invitation_url =
      Phoenix.HTML.html_escape(invitation_url) |> Phoenix.HTML.safe_to_string()

    assert email.html_body =~ escaped_invitation_url
  end

  test "sanitizes club context before using it in email headers and escapes HTML" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    assert :ok =
             ClubMemberInvitationEmail.deliver(%{
               email: "member@example.com",
               club: %{
                 name: "West <Coast>\r\nBcc: attacker@example.com"
               },
               invitation_url: "http://localhost:4000/invitations/club-members/token"
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from ==
             {"West <Coast> Bcc: attacker@example.com via Memba", "auth@mail.memba.local"}

    assert email.subject == "You're invited to join West <Coast> Bcc: attacker@example.com"
    refute email.subject =~ "\n"
    refute elem(email.from, 0) =~ "\n"

    assert email.html_body =~ "West &lt;Coast&gt; Bcc: attacker@example.com"
    refute email.html_body =~ "<Coast>"
    refute email.html_body =~ "\r\nBcc"
  end

  test "builds a Resend-tagged invitation email" do
    Application.put_env(:memba, AuthEmail,
      provider: :resend,
      from: "auth@mail.memba.io",
      message_stream: "auth"
    )

    invitation_id = "club_invitation_0123456789ABCDEFGHJKMNPQRS"
    club_id = "club_0123456789ABCDEFGHJKMNPQRS"

    assert :ok =
             ClubMemberInvitationEmail.deliver(%{
               email: "member@example.com",
               club: %{club_id: club_id, name: "Kootenay Mountaineering Club"},
               invitation_id: invitation_id,
               invitation_url: "https://app.memba.io/invitations/club-members/token-123"
             })

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.provider_options == %{
             tags: [
               %{name: "memba_email_kind", value: "club_member_invitation"},
               %{name: "memba_auth_email_stream", value: "auth"},
               %{name: "memba_club_id", value: club_id},
               %{name: "memba_invitation_id", value: invitation_id}
             ]
           }
  end

  test "rejects invalid inputs before Swoosh handoff" do
    Application.put_env(:memba, AuthEmail,
      from: "auth@mail.memba.local",
      message_stream: "development-auth"
    )

    assert {:error, :invalid_email} =
             ClubMemberInvitationEmail.deliver(%{
               email: " ",
               club: %{name: "West Coast Paddlers"},
               invitation_url: "http://localhost:4000/invitations/club-members/token"
             })

    assert {:error, :invalid_club} =
             ClubMemberInvitationEmail.deliver(%{
               email: "member@example.com",
               club: %{},
               invitation_url: "http://localhost:4000/invitations/club-members/token"
             })

    assert {:error, :invalid_invitation_url} =
             ClubMemberInvitationEmail.deliver(%{
               email: "member@example.com",
               club: %{name: "West Coast Paddlers"},
               invitation_url: " "
             })

    assert_no_email_sent()
  end

  test "does not hand an email to Swoosh when required auth email configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, AuthEmail, from: "auth@mail.memba.io")

    assert {:error, {:club_member_invitation_email_configuration_error, message}} =
             ClubMemberInvitationEmail.deliver(%{
               email: "member@example.com",
               club: %{name: "West Coast Paddlers"},
               invitation_url: "https://app.memba.io/invitations/club-members/token"
             })

    assert message =~ "Auth email delivery is enabled"
    assert message =~ "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"

    assert_no_email_sent()
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
