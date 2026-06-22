defmodule Memba.Messaging.EmailDeliveryProviders.LocalTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.LocalDeliveryFacts
  alias Memba.Messaging.OutboundMessageID

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)

    original_provider_config =
      Application.get_env(:memba, Memba.Messaging.EmailDeliveryProviders.Postmark)

    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, Memba.Messaging.EmailDeliveryProviders.Postmark,
      from: {"Memba", "messages@mail.memba.io"},
      reply_to: {"Matt Wynne", "matt@mattwynne.net"}
    )

    LocalDeliveryFacts.reset()

    on_exit(fn ->
      LocalDeliveryFacts.reset()
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Memba.Messaging.EmailDeliveryProviders.Postmark, original_provider_config)
    end)

    :ok
  end

  test "hands a rendered member message email to Swoosh" do
    request =
      email_delivery_request(
        club_name: "Kootenay <Mountaineers>",
        club_slug: "kmc",
        body: "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"
      )

    assert :ok = Local.deliver(request)

    assert_email_sent(fn email ->
      assert email.from == {"Bob via Memba", "messages@mail.memba.io"}
      assert email.reply_to == {"Kootenay <Mountaineers>", "everyone@kmc.clubs.memba.io"}
      assert email.to == [{"Alice", "alice@example.test"}]
      assert email.headers["Message-ID"] == request.outbound_message_id
      assert email.subject == "[kmc] Trip planning night"

      assert email.text_body ==
               "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"

      assert email.html_body =~ "<!doctype html>"
      assert email.html_body =~ "Kootenay &lt;Mountaineers&gt;"
      assert email.html_body =~ "Members message"
      assert email.html_body =~ "Bob"
      assert email.html_body =~ "to all members of Kootenay &lt;Mountaineers&gt;"
      assert email.html_body =~ "Trip planning night"
      assert email.html_body =~ "Hello &lt;Alice&gt; &amp; Bob"
      assert email.html_body =~ "Bring route ideas.<br>\n&lt;script&gt;alert(1)&lt;/script&gt;"
      assert email.html_body =~ "Reply to this email to post back to"
      assert email.html_body =~ "Kootenay &lt;Mountaineers&gt;"
      assert email.html_body =~ "Delivered for Kootenay &lt;Mountaineers&gt; by"
      assert email.html_body =~ "active member of Kootenay &lt;Mountaineers&gt;"

      refute email.html_body =~ "<Alice>"
      refute email.html_body =~ "<script>"

      assert email.provider_options[:metadata] == %{
               "memba_message_id" => request.message_id,
               "memba_delivery_id" => request.delivery_id,
               "memba_club_id" => request.club_id
             }
    end)

    assert [fact] = LocalDeliveryFacts.list()
    assert fact.delivery_id == request.delivery_id
    assert fact.message_id == request.message_id
    assert fact.outbound_message_id == request.outbound_message_id
    assert fact.recipient_address == "alice@example.test"
    assert fact.to == ["Alice <alice@example.test>"]
    assert fact.from == "Bob via Memba <messages@mail.memba.io>"
    assert fact.subject == "[kmc] Trip planning night"

    assert fact.text_body ==
             "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"
  end

  test "sanitizes local member-message header display values while preserving the text body" do
    request =
      email_delivery_request(
        recipient_name: "Alice\nAdams",
        sender_name: "Bob\nBarker",
        subject: "Trip planning\nnight",
        body: "Hello exactly as written.\nDo not add guidance here."
      )

    assert :ok = Local.deliver(request)

    assert_email_sent(fn email ->
      assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
      assert email.reply_to == {"Bob Barker", "bob@example.test"}
      assert email.to == [{"Alice Adams", "alice@example.test"}]
      assert email.subject == "Trip planning night"
      assert email.html_body =~ "not to the whole group"
      refute email.text_body =~ "Reply to this email"
      assert email.text_body == "Hello exactly as written.\nDo not add guidance here."
    end)
  end

  test "sets email reply-thread headers for local reply notifications" do
    request =
      email_delivery_request(
        club_name: "Kootenay Mountaineering Club",
        club_slug: "kmc",
        conversation_id: Memba.ID.generate(:message),
        reply_to_message_id: Memba.ID.generate(:message),
        in_reply_to_outbound_message_id: "<memba.parent@example.test>",
        references_outbound_message_ids: [
          "<memba.root@example.test>",
          "<memba.parent@example.test>"
        ]
      )

    assert :ok = Local.deliver(request)

    assert_email_sent(fn email ->
      assert email.reply_to == {"Kootenay Mountaineering Club", "everyone@kmc.clubs.memba.io"}
      assert email.headers["Message-ID"] == request.outbound_message_id
      assert email.headers["In-Reply-To"] == "<memba.parent@example.test>"

      assert email.headers["References"] ==
               "<memba.root@example.test> <memba.parent@example.test>"
    end)
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Local.deliver(email_delivery_request(channel: :sms))

    refute_email_sent()
    assert LocalDeliveryFacts.list() == []
  end

  defp email_delivery_request(overrides) do
    message_id = Keyword.get_lazy(overrides, :message_id, fn -> Memba.ID.generate(:message) end)

    delivery_id =
      Keyword.get_lazy(overrides, :delivery_id, fn -> Memba.ID.generate(:delivery) end)

    %EmailDeliveryRequest{
      message_id: message_id,
      club_id: Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end),
      delivery_id: delivery_id,
      outbound_message_id:
        Keyword.get(
          overrides,
          :outbound_message_id,
          OutboundMessageID.for_delivery(delivery_id, message_id)
        ),
      recipient_id:
        Keyword.get_lazy(overrides, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.test"),
      club_name: Keyword.get(overrides, :club_name, "Kootenay Mountaineering Club"),
      club_slug: Keyword.get(overrides, :club_slug),
      sender_name: Keyword.get(overrides, :sender_name, "Bob"),
      sender_address: Keyword.get(overrides, :sender_address, "bob@example.test"),
      conversation_id: Keyword.get(overrides, :conversation_id),
      reply_to_message_id: Keyword.get(overrides, :reply_to_message_id),
      in_reply_to_outbound_message_id: Keyword.get(overrides, :in_reply_to_outbound_message_id),
      references_outbound_message_ids: Keyword.get(overrides, :references_outbound_message_ids),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
