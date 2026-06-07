defmodule Memba.Onboarding.NewRequestEmailTest do
  use Memba.DataCase, async: false

  import Swoosh.TestAssertions

  alias Memba.Onboarding.NewRequestEmail
  alias Memba.Onboarding.Request

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_email_config = Application.get_env(:memba, NewRequestEmail)

    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)

    Application.put_env(:memba, NewRequestEmail,
      from: {"Memba", "hello@memba.test"},
      to: "staff@memba.test"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(NewRequestEmail, original_email_config)
    end)

    :ok
  end

  test "staff notification includes a direct request conversion link" do
    request = %Request{
      request_id: Memba.ID.generate(:onboarding_request),
      requester_name: "Robin Requester",
      requester_email: "robin@example.com",
      requested_club_name: "West Coast Paddlers",
      note: "We want to try Memba."
    }

    assert :ok = NewRequestEmail.deliver(request)

    assert_email_sent(fn email ->
      assert email.to == [{"", "staff@memba.test"}]
      assert email.subject == "New Memba request: West Coast Paddlers"
      assert email.text_body =~ "Request ID: #{request.request_id}"
      assert email.text_body =~ "http://localhost:4000/admin/requests/#{request.request_id}"
      assert email.html_body =~ "http://localhost:4000/admin/requests/#{request.request_id}"
    end)
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
