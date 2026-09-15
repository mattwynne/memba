defmodule Memba.Membership.GroupWelcomeEmailTest do
  use ExUnit.Case, async: false

  alias Memba.Membership.GroupWelcomeEmail
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_postmark_config = Application.get_env(:memba, Postmark)
    original_resend_config = Application.get_env(:memba, Resend)
    original_inbound_email_config = Application.get_env(:memba, :club_inbound_email)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, :club_inbound_email, domain: "clubs.memba.test")

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Postmark, original_postmark_config)
      restore_env(Resend, original_resend_config)
      restore_env(:club_inbound_email, original_inbound_email_config)
    end)

    :ok
  end

  test "builds and sends a group-branded welcome through the configured Postmark sender" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)
    Application.put_env(:memba, Postmark, from: {"Memba", "messages@mail.memba.test"})

    group_url = "https://kootenay-alpine.clubs.memba.io/groups/group_123?from=email&tab=all"

    assert :ok = GroupWelcomeEmail.deliver(welcome_attrs(group_url))

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Kootenay Alpine Club via Memba", "messages@mail.memba.test"}
    assert email.to == [{"Carol Canoe", "carol@example.com"}]
    assert email.reply_to == {"Board", "board@kootenay-alpine.clubs.memba.test"}
    assert email.subject == "[kootenay-alpine] You've been added to Board"

    assert email.provider_options == %{
             metadata: %{
               "memba_actor_id" => "person_alice",
               "memba_club_id" => "club_kootenay",
               "memba_email_kind" => "group_welcome",
               "memba_group_id" => "group_board",
               "memba_recipient_id" => "person_carol"
             }
           }

    assert email.text_body =~ "Hi Carol,"

    assert email.text_body =~
             "Alice Ahmed added you to Board, a private group inside Kootenay Alpine Club."

    assert email.text_body =~
             "You can read everything already in it, take part in its conversations"

    assert email.text_body =~
             "Earlier Board emails aren't resent — the full history is on the website."

    assert email.text_body =~ group_url

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "Board"
    assert email.html_body =~ "Kootenay Alpine Club"
    assert email.html_body =~ "Alice Ahmed added you to Board"
    assert email.html_body =~ "Open Board"
    assert email.html_body =~ "Earlier Board emails aren&#39;t resent"
    assert email.html_body =~ "board@kootenay-alpine.clubs.memba.test"
    assert email.html_body =~ "Sent to carol@example.com."

    escaped_group_url =
      group_url
      |> Phoenix.HTML.html_escape()
      |> Phoenix.HTML.safe_to_string()

    assert email.html_body =~ escaped_group_url
  end

  test "uses Resend tags and self-add copy without changing the mailer handoff" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Resend)
    Application.put_env(:memba, Resend, from: "updates@mail.memba.test")

    attrs =
      "https://kootenay-alpine.clubs.memba.io/groups/group_123"
      |> welcome_attrs()
      |> put_in([:added_by], %{person_id: "person_carol", name: "Carol Canoe"})

    assert :ok = GroupWelcomeEmail.deliver(attrs)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Kootenay Alpine Club via Memba", "updates@mail.memba.test"}
    assert email.text_body =~ "You added yourself to Board"
    assert email.html_body =~ "You added yourself to Board"

    assert email.provider_options == %{
             tags: [
               %{name: "memba_email_kind", value: "group_welcome"},
               %{name: "memba_club_id", value: "club_kootenay"},
               %{name: "memba_group_id", value: "group_board"},
               %{name: "memba_recipient_id", value: "person_carol"},
               %{name: "memba_actor_id", value: "person_carol"}
             ]
           }
  end

  test "sanitizes email headers, escapes content, and rejects missing delivery data" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.test")

    attrs =
      welcome_attrs("https://clubs.memba.test/groups/group_123?a=1&b=2")
      |> put_in([:club, :name], "Kootenay <Alpine>\r\nBcc: attacker@example.com")
      |> put_in([:group, :name], "Board <script>\r\nInjected")
      |> put_in([:recipient, :name], "Carol <Canoe>")
      |> put_in([:added_by, :name], "Alice <Ahmed>")

    assert :ok = GroupWelcomeEmail.deliver(attrs)
    assert_received {:email, %Swoosh.Email{} = email}

    refute email.subject =~ "\n"
    refute elem(email.from, 0) =~ "\n"
    assert email.html_body =~ "Kootenay &lt;Alpine&gt; Bcc: attacker@example.com"
    assert email.html_body =~ "Board &lt;script&gt; Injected"
    assert email.html_body =~ "Alice &lt;Ahmed&gt;"
    refute email.html_body =~ "<script>"

    assert {:error, :invalid_email} =
             attrs
             |> put_in([:recipient, :email], "not-an-email")
             |> GroupWelcomeEmail.deliver()

    assert {:error, :invalid_group_url} =
             attrs
             |> Map.put(:group_url, " ")
             |> GroupWelcomeEmail.deliver()
  end

  defp welcome_attrs(group_url) do
    %{
      club: %{
        club_id: "club_kootenay",
        name: "Kootenay Alpine Club",
        slug: "kootenay-alpine"
      },
      group: %{
        group_id: "group_board",
        email_slug: "board",
        name: "Board"
      },
      recipient: %{
        person_id: "person_carol",
        name: "Carol Canoe",
        email: " CAROL@Example.COM "
      },
      added_by: %{
        person_id: "person_alice",
        name: "Alice Ahmed"
      },
      group_url: group_url
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
