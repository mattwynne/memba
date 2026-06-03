defmodule Memba.Messaging.InboundEmailBodyTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailBody

  test "requires a non-blank text/plain body and ignores HTML" do
    inbound_email = %InboundEmail{
      provider: "resend",
      provider_message_id: "email-123",
      from_address: "alice@example.com",
      recipient_addresses: ["kmc@clubs.memba.io"],
      subject: "Trip planning night",
      text_body: nil,
      html_body: "<p>This must not be converted.</p>"
    }

    assert {:error, :plain_text_required} = InboundEmailBody.normalize_text_body(inbound_email)
    assert {:error, :plain_text_required} = InboundEmailBody.normalize_text_body(" \n\t ")
  end

  test "normalizes line endings and trims the usable text body" do
    assert {:ok, "Bring route ideas.\nMeet at 7."} =
             InboundEmailBody.normalize_text_body("\r\n  Bring route ideas.\r\nMeet at 7.  \r\n")
  end

  test "strips common signatures and quoted prior-message content" do
    text_body = """
    Bring route ideas.

    -- 
    Alice Example

    On Tue, Bob Example wrote:
    > Previous message
    """

    assert {:ok, "Bring route ideas."} = InboundEmailBody.normalize_text_body(text_body)
  end

  test "strips reply intros and quoted lines conservatively" do
    text_body = """
    New plan for Thursday.

    On Tue, Jun 2, 2026 at 7:15 PM Bob Example wrote:
    > Previous plan.
    > More old text.
    """

    assert {:ok, "New plan for Thursday."} = InboundEmailBody.normalize_text_body(text_body)
  end

  test "rejects bodies that are blank after quote and signature stripping" do
    assert {:error, :plain_text_required} =
             InboundEmailBody.normalize_text_body("""
             -- 
             Alice Example
             """)

    assert {:error, :plain_text_required} =
             InboundEmailBody.normalize_text_body("""
             > Previous message only.
             > More old text.
             """)
  end
end
