defmodule Memba.Messaging.DeliveryProviders.LocalTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.DeliveryProviders.Local
  alias Memba.Messaging.DeliveryRequest

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)

    original_provider_config =
      Application.get_env(:memba, Memba.Messaging.DeliveryProviders.Postmark)

    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, Memba.Messaging.DeliveryProviders.Postmark,
      from: {"Memba", "messages@mail.memba.io"},
      reply_to: {"Matt Wynne", "matt@mattwynne.net"}
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Memba.Messaging.DeliveryProviders.Postmark, original_provider_config)
    end)

    :ok
  end

  test "hands a rendered member message email to Swoosh" do
    request = delivery_request(body: "Hello <Alice> & Bob\nBring route ideas.")

    assert :ok = Local.deliver(request)

    assert_email_sent(fn email ->
      assert email.from == {"Memba", "messages@mail.memba.io"}
      assert email.reply_to == {"Matt Wynne", "matt@mattwynne.net"}
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
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Local.deliver(delivery_request(channel: :sms))

    refute_email_sent()
  end

  defp delivery_request(overrides) do
    %DeliveryRequest{
      message_id: Keyword.get_lazy(overrides, :message_id, &Ecto.UUID.generate/0),
      club_id: Keyword.get_lazy(overrides, :club_id, &Ecto.UUID.generate/0),
      delivery_id: Keyword.get_lazy(overrides, :delivery_id, &Ecto.UUID.generate/0),
      recipient_id: Keyword.get_lazy(overrides, :recipient_id, &Ecto.UUID.generate/0),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.test"),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
