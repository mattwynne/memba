defmodule Memba.Messaging.EmailDeliveryProviders.LocalTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.LocalDeliveryFacts

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
    request = email_delivery_request(body: "Hello <Alice> & Bob\nBring route ideas.")

    assert :ok = Local.deliver(request)

    assert_email_sent(fn email ->
      assert email.from == {"Bob via Memba", "messages@mail.memba.io"}
      assert email.reply_to == {"Bob", "bob@example.test"}
      assert email.to == [{"Alice", "alice@example.test"}]
      assert email.subject == "Trip planning night"
      assert email.text_body == "Hello <Alice> & Bob\nBring route ideas."
      assert email.html_body =~ "Hello &lt;Alice&gt; &amp; Bob<br>\nBring route ideas."

      assert email.provider_options[:metadata] == %{
               "memba_message_id" => request.message_id,
               "memba_delivery_id" => request.delivery_id,
               "memba_club_id" => request.club_id
             }
    end)

    assert [fact] = LocalDeliveryFacts.list()
    assert fact.delivery_id == request.delivery_id
    assert fact.message_id == request.message_id
    assert fact.recipient_address == "alice@example.test"
    assert fact.to == ["Alice <alice@example.test>"]
    assert fact.from == "Bob via Memba <messages@mail.memba.io>"
    assert fact.subject == "Trip planning night"
    assert fact.text_body == "Hello <Alice> & Bob\nBring route ideas."
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Local.deliver(email_delivery_request(channel: :sms))

    refute_email_sent()
    assert LocalDeliveryFacts.list() == []
  end

  defp email_delivery_request(overrides) do
    %EmailDeliveryRequest{
      message_id: Keyword.get_lazy(overrides, :message_id, fn -> Memba.ID.generate(:message) end),
      club_id: Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end),
      delivery_id:
        Keyword.get_lazy(overrides, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
      recipient_id:
        Keyword.get_lazy(overrides, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.test"),
      sender_name: Keyword.get(overrides, :sender_name, "Bob"),
      sender_address: Keyword.get(overrides, :sender_address, "bob@example.test"),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
