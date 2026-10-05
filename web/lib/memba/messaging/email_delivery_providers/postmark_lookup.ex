defmodule Memba.Messaging.EmailDeliveryProviders.PostmarkLookup do
  @moduledoc """
  Search a Postmark server's outbound messages by Memba delivery metadata.

  A negative search is only inconclusive: indexing is eventual and retention is
  finite. Every candidate is confirmed against its detail's metadata and exact
  recipient. Multiple confirmed IDs mean multiple accepted provider handoffs.
  """
  alias Memba.Messaging.EmailDeliveryProviders.PostmarkConfig

  @page_size 500
  @max_offset 9_500

  def find(delivery_id, recipient, _started_at) do
    with {:ok, %PostmarkConfig{} = config} <- PostmarkConfig.from_application_env() do
      search(delivery_id, recipient, config, 0, [], nil)
    end
  end

  defp search(delivery_id, recipient, config, offset, confirmed, first_error) do
    token = config.server_token
    base = Application.get_env(:memba, :postmark_lookup_url, "https://api.postmarkapp.com")

    params = [
      count: @page_size,
      offset: offset,
      recipient: recipient,
      metadata_memba_delivery_id: delivery_id
    ]

    result =
      Req.get(
        base <> "/messages/outbound",
        Keyword.merge(
          [
            params: params,
            headers: [{"x-postmark-server-token", token}, {"accept", "application/json"}],
            receive_timeout: 10_000,
            retry: false
          ],
          request_options()
        )
      )

    case result do
      {:ok, %{status: 200, body: %{"Messages" => messages, "TotalCount" => total}}}
      when is_list(messages) and is_integer(total) ->
        {confirmed, first_error} =
          Enum.reduce(messages, {confirmed, first_error}, fn candidate, {ids, error} ->
            case candidate do
              %{"MessageID" => id, "Metadata" => %{"memba_delivery_id" => ^delivery_id}}
              when is_binary(id) ->
                case detail(id, delivery_id, recipient, base, token) do
                  {:ok, ^id} -> {if(id in ids, do: ids, else: [id | ids]), error}
                  {:error, reason} -> {ids, candidate_error(error, reason)}
                end

              _ ->
                {ids, candidate_error(error, :postmark_search_candidate_mismatch)}
            end
          end)

        cond do
          offset + @page_size < total and offset < @max_offset ->
            search(delivery_id, recipient, config, offset + @page_size, confirmed, first_error)

          offset + @page_size < total ->
            finish(confirmed, :postmark_search_truncated)

          true ->
            finish(confirmed, first_error)
        end

      {:ok, %{status: status}} ->
        finish(confirmed, {:postmark_search_http, status})

      {:error, reason} ->
        finish(confirmed, {:postmark_search_transport, reason})
    end
  end

  defp candidate_error(nil, reason), do: reason

  defp candidate_error(error, reason)
       when error in [:postmark_recipient_mismatch, :postmark_metadata_mismatch] and
              reason not in [:postmark_recipient_mismatch, :postmark_metadata_mismatch],
       do: reason

  defp candidate_error(error, _reason), do: error

  defp finish([], nil), do: :not_found
  defp finish([], reason), do: {:error, reason}

  defp finish(confirmed, error) do
    ids = Enum.reverse(confirmed)

    {:ok,
     %{
       message_ids: ids,
       duplicate_count: length(ids) - 1,
       complete?:
         is_nil(error) or error in [:postmark_recipient_mismatch, :postmark_metadata_mismatch]
     }}
  end

  defp request_options, do: Application.get_env(:memba, :postmark_lookup_req_options, [])

  defp detail(id, delivery_id, recipient, base, token) do
    result =
      Req.get(
        base <> "/messages/outbound/#{URI.encode(id)}/details",
        Keyword.merge(
          [
            headers: [{"x-postmark-server-token", token}, {"accept", "application/json"}],
            receive_timeout: 10_000,
            retry: false
          ],
          request_options()
        )
      )

    case result do
      {:ok,
       %{status: 200, body: %{"Metadata" => %{"memba_delivery_id" => ^delivery_id}, "To" => to}}} ->
        case recipient_addresses(to) do
          {:ok, addresses} ->
            if String.downcase(recipient) in addresses,
              do: {:ok, id},
              else: {:error, :postmark_recipient_mismatch}

          :error ->
            {:error, :invalid_postmark_detail}
        end

      {:ok, %{status: 200}} ->
        {:error, :postmark_metadata_mismatch}

      {:ok, %{status: status}} ->
        {:error, {:postmark_detail_http, status}}

      {:error, reason} ->
        {:error, {:postmark_detail_transport, reason}}
    end
  end

  # The outbound details API represents To as an array of recipient objects,
  # unlike the comma-separated string in some other Postmark payloads.
  defp recipient_addresses(to) when is_list(to) do
    if Enum.all?(to, &match?(%{"Email" => email} when is_binary(email), &1)) do
      {:ok,
       Enum.map(to, fn %{"Email" => email} -> email |> String.trim() |> String.downcase() end)}
    else
      :error
    end
  end

  defp recipient_addresses(to) when is_binary(to) do
    addresses =
      to
      |> String.split(",")
      |> Enum.map(fn entry ->
        case Regex.run(~r/<([^<>]+)>\s*$/, entry) do
          [_, address] -> String.downcase(String.trim(address))
          nil -> String.downcase(String.trim(entry))
        end
      end)

    {:ok, addresses}
  end

  defp recipient_addresses(_), do: :error
end
