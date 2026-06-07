defmodule Memba.Messaging.InboundClubRejectionEmailTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend
  alias Memba.Messaging.InboundClubRejectionEmail
  alias Memba.Messaging.InboundEmail

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)
    original_resend_config = Application.get_env(:memba, Resend)

    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, Postmark,
      from: {"Memba", "messages@mail.memba.test"},
      reply_to: {"Memba support", "support@memba.test"}
    )

    Application.put_env(:memba, Resend,
      from: {"Memba", "messages@mail.memba.test"},
      reply_to: {"Memba support", "support@memba.test"}
    )

    on_exit(fn ->
      restore_env(:messaging_email_delivery_provider, original_provider)
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      restore_env(Resend, original_resend_config)
    end)

    :ok
  end

  test "renders a group-named delivery notice with safe text, HTML, and Postmark metadata" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    club_name = "Wessex <Choir>\r\nBcc: attacker@example.com"

    inbound_email =
      inbound_email(%{
        provider: "postmark",
        provider_message_id: "inbound-rejection-template",
        from_address: "margaret@example.com",
        recipient_addresses: ["wessex@clubs.memba.io"],
        subject: "Can I bring <guest>?",
        text_body: "Hi — can I bring <script>alert('x')</script>?"
      })

    assert :ok =
             InboundClubRejectionEmail.deliver(
               inbound_email,
               "wessex@clubs.memba.io",
               "unknown_sender",
               "delivery-reference-123",
               club_name: club_name
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Memba", "messages@mail.memba.test"}
    assert email.reply_to == {"Memba support", "support@memba.test"}
    assert email.to == [{"", "margaret@example.com"}]

    assert email.subject ==
             "Your email to Wessex <Choir> Bcc: attacker@example.com wasn't posted"

    refute email.subject =~ "\n"
    refute elem(email.from, 0) =~ "\n"

    assert email.text_body =~
             "Your email to Wessex <Choir> Bcc: attacker@example.com wasn't posted."

    assert email.text_body =~
             "We couldn't find a member account for this email address, so your message wasn't posted."

    assert email.text_body =~
             "Is it possible you signed up for membership of Wessex <Choir> Bcc: attacker@example.com with a different email address?"

    assert email.text_body =~ "Just reply to this email and a person will help."
    assert email.text_body =~ "Nothing was sent to Wessex <Choir> Bcc: attacker@example.com"
    assert email.text_body =~ "Subject: Can I bring <guest>?"

    assert email.html_body =~ "Delivery notice"
    assert email.html_body =~ "Your email wasn&#39;t posted"
    assert email.html_body =~ "Wessex &lt;Choir&gt; Bcc: attacker@example.com"
    assert email.html_body =~ "member account for this email address"
    assert email.html_body =~ "Just reply to this email and a person will help"
    assert email.html_body =~ "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;"
    refute email.html_body =~ "<script>"
    refute email.html_body =~ "help@memba.io"

    assert email.provider_options[:metadata] == %{
             "memba_email_kind" => "inbound_club_rejection",
             "memba_inbound_id" => InboundEmail.identity(inbound_email),
             "memba_in_provider" => "postmark",
             "memba_in_msg_id" => "inbound-rejection-template",
             "memba_in_to" => "wessex@clubs.memba.io",
             "memba_reject_reason" => "unknown_sender",
             "memba_reject_ref" => "delivery-reference-123"
           }
  end

  test "preserves reply threading with sanitized headers and Resend tags" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Resend)

    inbound_email =
      inbound_email(%{
        provider: "resend",
        provider_message_id: "1b700cb9-3a48-460d-a2d1-255fe01ed4e2",
        from_address: "alice@example.com",
        recipient_addresses: ["kmc@clubs.memba.io"],
        subject: "Trip planning night\r\nBcc: attacker@example.com",
        text_body: "See the attached route.",
        original_message_id: "<original@example.com>\r\nReferences: injected"
      })

    assert :ok =
             InboundClubRejectionEmail.deliver(
               inbound_email,
               "kmc@clubs.memba.io",
               "attachments_not_supported",
               "del-ref-456",
               club_name: "Kootenay Mountaineering Club"
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.subject == "Re: Trip planning night Bcc: attacker@example.com"
    refute email.subject =~ "\n"

    assert email.headers["In-Reply-To"] == "<original@example.com> References: injected"
    assert email.headers["References"] == "<original@example.com> References: injected"
    refute email.headers["In-Reply-To"] =~ "\n"

    assert email.text_body =~
             "Emails with attachments can't be posted yet, so your message wasn't posted."

    assert email.html_body =~ html_escape("Emails with attachments can't be posted yet")

    assert email.provider_options[:tags] == [
             %{name: "memba_email_kind", value: "inbound_club_rejection"},
             %{
               name: "memba_inbound_provider_message_id",
               value: "1b700cb9-3a48-460d-a2d1-255fe01ed4e2"
             },
             %{name: "memba_rejection_reason", value: "attachments_not_supported"},
             %{name: "memba_rejection_delivery_reference", value: "del-ref-456"}
           ]

    assert email.headers["X-Memba-Inbound-Email-ID"] == InboundEmail.identity(inbound_email)
    assert email.headers["X-Memba-Rejection-Delivery-Reference"] == "del-ref-456"
  end

  test "falls back to Memba-led subject and generic next steps without group context or reply-to" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    Application.put_env(:memba, Postmark, from: {"Memba", "messages@mail.memba.test"})

    inbound_email =
      inbound_email(%{
        provider: "postmark",
        provider_message_id: "fallback-rejection-template",
        from_address: "sender@example.com",
        recipient_addresses: ["unknown@clubs.memba.io"],
        subject: "Plain text?\r\nBcc: attacker@example.com",
        text_body: "<script>alert('x')</script>"
      })

    assert :ok =
             InboundClubRejectionEmail.deliver(
               inbound_email,
               "unknown@clubs.memba.io",
               "plain_text_required",
               "fallback-reference"
             )

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.subject == "Your email wasn't posted"
    refute email.reply_to

    assert email.text_body =~ "Your email wasn't posted."
    assert email.text_body =~ "We couldn't read a plain-text message body"
    assert email.text_body =~ "If you need a hand, contact Memba support."
    assert email.text_body =~ "Nothing was sent to a group"
    assert email.text_body =~ "Subject: Plain text? Bcc: attacker@example.com"
    refute email.text_body =~ "\r\nBcc"

    assert email.html_body =~ "Delivery notice"
    assert email.html_body =~ "Your email wasn&#39;t posted"
    assert email.html_body =~ "If you need a hand, contact Memba support."
    assert email.html_body =~ "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;"
    refute email.html_body =~ "<script>"
    refute email.html_body =~ "help@memba.io"

    assert email.provider_options[:metadata]["memba_reject_reason"] == "plain_text_required"
    assert email.provider_options[:metadata]["memba_reject_ref"] == "fallback-reference"
  end

  test "maps each known rejection reason to plain-language text and HTML copy" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    reason_expectations = [
      {"attachments_not_supported", "Emails with attachments can't be posted yet"},
      {"plain_text_required", "We couldn't read a plain-text message body"},
      {"unknown_sender", "We couldn't find a member account for this email address"},
      {"sender_not_active_member", "This email address isn't an active member of KMC"},
      {"unknown_club_slug", "We couldn't match the address you used to a Memba group"},
      {"unsupported_recipient_address",
       "That recipient address isn't set up for member messages"},
      {"unexpected_failure", "We couldn't post this email"}
    ]

    for {reason, expected_copy} <- reason_expectations do
      inbound_email =
        inbound_email(%{
          provider: "postmark",
          provider_message_id: "reason-#{reason}",
          from_address: "sender@example.com",
          recipient_addresses: ["kmc@clubs.memba.io"],
          subject: "Reason #{reason}",
          text_body: "Original body"
        })

      assert :ok =
               InboundClubRejectionEmail.deliver(
                 inbound_email,
                 "kmc@clubs.memba.io",
                 reason,
                 "delivery-#{reason}",
                 club_name: "KMC"
               )

      assert_received {:email, %Swoosh.Email{} = email}
      assert email.text_body =~ expected_copy
      assert email.html_body =~ html_escape(expected_copy)
    end
  end

  defp inbound_email(attrs) do
    {:ok, inbound_email} = InboundEmail.new(attrs)
    inbound_email
  end

  defp html_escape(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
