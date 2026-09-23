defmodule Memba.Messaging.LegacyConversationFollowDryRunCursor do
  @moduledoc """
  Signed opaque continuation for read-only legacy-follow reconciliation previews.

  A token is useful only for the exact cutover fence and apply checkpoint from
  which it was issued. It cannot be used as an apply cursor.
  """

  @prefix "lcfr1"
  @version 1
  @mode "dry_run"

  def issue(ordering_key, apply_checkpoint, fence, namespace)
      when is_tuple(ordering_key) and is_binary(namespace) do
    payload = %{
      "version" => @version,
      "mode" => @mode,
      "namespace" => namespace,
      "fence_id" => fence.cutover_id,
      "fence_position" => fence.event_store_position,
      "event_store_schema" => fence.event_store_schema,
      "ordering_key" => Tuple.to_list(ordering_key),
      "apply_checkpoint" => serialize_cursor(apply_checkpoint)
    }

    encoded = payload |> Jason.encode!() |> Base.url_encode64(padding: false)
    signature = encoded |> sign() |> Base.url_encode64(padding: false)
    Enum.join([@prefix, encoded, signature], ".")
  end

  def verify(token, apply_checkpoint, fence, namespace)
      when is_binary(token) and is_binary(namespace) do
    with [@prefix, encoded, encoded_signature] <- String.split(token, ".", parts: 3),
         {:ok, signature} <- Base.url_decode64(encoded_signature, padding: false),
         true <- secure_signature?(encoded, signature),
         {:ok, json} <- Base.url_decode64(encoded, padding: false),
         {:ok, payload} <- Jason.decode(json),
         :ok <- validate_payload(payload, apply_checkpoint, fence, namespace),
         [person_id, conversation_id] <- payload["ordering_key"],
         true <- Memba.ID.valid?(:person, person_id),
         true <- Memba.ID.valid?(:message, conversation_id) do
      {:ok, {person_id, conversation_id}}
    else
      _invalid -> {:error, :invalid_dry_run_cursor}
    end
  end

  def verify(_token, _apply_checkpoint, _fence, _namespace),
    do: {:error, :invalid_dry_run_cursor}

  defp validate_payload(payload, apply_checkpoint, fence, namespace) do
    expected = %{
      "version" => @version,
      "mode" => @mode,
      "namespace" => namespace,
      "fence_id" => fence.cutover_id,
      "fence_position" => fence.event_store_position,
      "event_store_schema" => fence.event_store_schema,
      "apply_checkpoint" => serialize_cursor(apply_checkpoint)
    }

    if Map.take(payload, Map.keys(expected)) == expected and
         Enum.sort(Map.keys(payload)) ==
           Enum.sort(Map.keys(expected) ++ ["ordering_key"]),
       do: :ok,
       else: {:error, :cursor_scope_mismatch}
  end

  defp secure_signature?(encoded, signature) do
    expected = sign(encoded)

    byte_size(signature) == byte_size(expected) and
      Plug.Crypto.secure_compare(signature, expected)
  end

  defp sign(encoded) do
    :memba
    |> Application.fetch_env!(MembaWeb.Endpoint)
    |> Keyword.fetch!(:secret_key_base)
    |> then(&:crypto.mac(:hmac, :sha256, &1, "#{@prefix}:#{encoded}"))
  end

  defp serialize_cursor(nil), do: nil
  defp serialize_cursor(cursor), do: Tuple.to_list(cursor)
end
