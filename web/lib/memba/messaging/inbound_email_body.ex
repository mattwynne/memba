defmodule Memba.Messaging.InboundEmailBody do
  @moduledoc """
  Plain-text-only body policy for inbound club-message email.

  This intentionally ignores HTML and applies conservative plain-text cleanup:
  common signature delimiters and quoted prior-message content are stripped, and
  a non-blank body is required after cleanup.
  """

  alias Memba.Messaging.InboundEmail

  @plain_text_required :plain_text_required

  @doc """
  Normalize the `text/plain` body that may become a club message body.
  """
  @spec normalize_text_body(InboundEmail.t() | String.t() | nil) ::
          {:ok, String.t()} | {:error, :plain_text_required}
  def normalize_text_body(%InboundEmail{text_body: text_body}) do
    normalize_text_body(text_body)
  end

  def normalize_text_body(nil), do: {:error, @plain_text_required}

  def normalize_text_body(text_body) when is_binary(text_body) do
    text_body =
      text_body
      |> normalize_line_endings()
      |> strip_after_reply_or_signature_marker()
      |> strip_quoted_lines()
      |> String.trim()

    if text_body == "" do
      {:error, @plain_text_required}
    else
      {:ok, text_body}
    end
  end

  defp normalize_line_endings(text_body) do
    text_body
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
  end

  defp strip_after_reply_or_signature_marker(text_body) do
    text_body
    |> String.split("\n")
    |> Enum.take_while(&(not reply_or_signature_marker?(&1)))
    |> Enum.join("\n")
  end

  defp reply_or_signature_marker?("-- "), do: true

  defp reply_or_signature_marker?(line) do
    trimmed_line = String.trim(line)

    original_message_marker?(trimmed_line) or
      reply_intro_marker?(trimmed_line) or
      mobile_signature_marker?(trimmed_line)
  end

  defp original_message_marker?("-----Original Message-----"), do: true
  defp original_message_marker?(_line), do: false

  defp reply_intro_marker?(line) do
    String.match?(line, ~r/^On .+ wrote:$/i)
  end

  defp mobile_signature_marker?(line) do
    String.match?(line, ~r/^Sent from my (iPhone|iPad|Android|mobile)/i)
  end

  defp strip_quoted_lines(text_body) do
    text_body
    |> String.split("\n")
    |> Enum.reject(fn line -> String.starts_with?(String.trim_leading(line), ">") end)
    |> Enum.join("\n")
  end
end
