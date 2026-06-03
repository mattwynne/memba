defmodule MembaWeb.ResendWebhookSignatureTest do
  use ExUnit.Case, async: true

  alias MembaWeb.ResendWebhookSignature

  test "reads and trims the Resend webhook signing secret from environment" do
    assert "whsec_test-secret" =
             ResendWebhookSignature.signing_secret_from_env!(:prod, fn
               "MEMBA_RESEND_WEBHOOK_SIGNING_SECRET" -> "  whsec_test-secret  "
             end)
  end

  test "allows missing Resend webhook signing secret outside production" do
    assert ResendWebhookSignature.signing_secret_from_env!(:dev, fn _name -> nil end) == nil
    assert ResendWebhookSignature.signing_secret_from_env!(:test, fn _name -> "  " end) == nil
  end

  test "requires the Resend webhook signing secret in production" do
    assert_raise RuntimeError, ~r/MEMBA_RESEND_WEBHOOK_SIGNING_SECRET/, fn ->
      ResendWebhookSignature.signing_secret_from_env!(:prod, fn _name -> nil end)
    end
  end
end
