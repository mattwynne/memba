defmodule Memba.Messaging.EmailDeliveryProviders.ResendAdapter do
  @moduledoc """
  Swoosh adapter for Resend with the header shape expected by Resend's API.

  Swoosh's built-in Resend adapter serializes custom headers as a list of
  `%{name: ..., value: ...}` objects. Resend's send-email API documents
  `headers` as an object, and real delivery showed the list shape being
  interpreted as headers named `Name` and `Value`. This adapter keeps the
  Swoosh email-building API while sending headers as a JSON object.
  """

  use Swoosh.Adapter, required_config: [:api_key]

  alias Swoosh.Email

  @base_url "https://api.resend.com"
  @api_endpoint "/emails"

  @impl Swoosh.Adapter
  def deliver(%Email{} = email, config \\ []) do
    headers = prepare_request_headers(config, email)
    body = email |> prepare_body() |> Swoosh.json_library().encode!()
    url = [base_url(config), @api_endpoint]

    case Swoosh.ApiClient.post(url, headers, body, email) do
      {:ok, code, _headers, body} when code >= 200 and code <= 399 ->
        {:ok, %{id: extract_id(body)}}

      {:ok, code, _headers, body} when code >= 400 ->
        case Swoosh.json_library().decode(body) do
          {:ok, error} -> {:error, {code, error}}
          {:error, _} -> {:error, {code, body}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp base_url(config), do: config[:base_url] || @base_url

  defp prepare_request_headers(config, email) do
    headers = [
      {"Authorization", "Bearer #{config[:api_key]}"},
      {"Content-Type", "application/json"},
      {"User-Agent", "swoosh/#{Swoosh.version()}"}
    ]

    if idempotency_key = email.provider_options[:idempotency_key] do
      [{"Idempotency-Key", idempotency_key} | headers]
    else
      headers
    end
  end

  defp prepare_body(email) do
    %{}
    |> prepare_from(email)
    |> prepare_to(email)
    |> prepare_cc(email)
    |> prepare_bcc(email)
    |> prepare_reply_to(email)
    |> prepare_subject(email)
    |> prepare_text(email)
    |> prepare_html(email)
    |> prepare_attachments(email)
    |> prepare_tags(email)
    |> prepare_scheduled_at(email)
    |> prepare_template(email)
    |> prepare_headers_body(email)
  end

  defp prepare_from(body, %{from: {name, email}}) when name not in [nil, ""] do
    Map.put(body, "from", "#{name} <#{email}>")
  end

  defp prepare_from(body, %{from: {_name, email}}), do: Map.put(body, "from", email)

  defp prepare_to(body, %{to: to}), do: Map.put(body, "to", Enum.map(to, &format_recipient/1))

  defp prepare_cc(body, %{cc: []}), do: body
  defp prepare_cc(body, %{cc: cc}), do: Map.put(body, "cc", Enum.map(cc, &format_recipient/1))

  defp prepare_bcc(body, %{bcc: []}), do: body

  defp prepare_bcc(body, %{bcc: bcc}) do
    Map.put(body, "bcc", Enum.map(bcc, &format_recipient/1))
  end

  defp prepare_reply_to(body, %{reply_to: nil}), do: body

  defp prepare_reply_to(body, %{reply_to: reply_to}),
    do: Map.put(body, "reply_to", format_recipient(reply_to))

  defp prepare_subject(body, %{subject: subject}) when subject != "",
    do: Map.put(body, "subject", subject)

  defp prepare_subject(body, _email), do: body

  defp prepare_text(body, %{text_body: nil}), do: body
  defp prepare_text(body, %{text_body: text}), do: Map.put(body, "text", text)

  defp prepare_html(body, %{html_body: nil}), do: body
  defp prepare_html(body, %{html_body: html}), do: Map.put(body, "html", html)

  defp prepare_attachments(body, %{attachments: []}), do: body

  defp prepare_attachments(body, %{attachments: attachments}) do
    Map.put(
      body,
      "attachments",
      Enum.map(attachments, fn attachment ->
        attachment_data = %{
          filename: attachment.filename,
          content: Swoosh.Attachment.get_content(attachment, :base64)
        }

        case {attachment.type, attachment.cid} do
          {:inline, cid} when not is_nil(cid) -> Map.put(attachment_data, "content_id", cid)
          _other -> attachment_data
        end
      end)
    )
  end

  defp prepare_tags(body, %{provider_options: %{tags: tags}}) when is_list(tags) do
    Map.put(body, "tags", tags)
  end

  defp prepare_tags(body, _email), do: body

  defp prepare_scheduled_at(body, %{provider_options: %{scheduled_at: scheduled_at}}) do
    Map.put(body, "scheduled_at", scheduled_at)
  end

  defp prepare_scheduled_at(body, _email), do: body

  defp prepare_template(body, %{provider_options: %{template: template}}) when is_map(template) do
    Map.put(body, "template", template)
  end

  defp prepare_template(body, _email), do: body

  defp prepare_headers_body(body, %{headers: headers}) when map_size(headers) > 0 do
    Map.put(body, "headers", headers)
  end

  defp prepare_headers_body(body, _email), do: body

  defp format_recipient({name, email}) when name not in [nil, ""], do: "#{name} <#{email}>"
  defp format_recipient({_name, email}), do: email

  defp extract_id(body) do
    body
    |> Swoosh.json_library().decode!()
    |> Map.get("id")
  end
end
