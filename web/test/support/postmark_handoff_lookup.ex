defmodule Memba.Support.PostmarkHandoffLookup do
  @moduledoc false
  def find_handoff(delivery_id, _recipient, _started_at) do
    case Application.fetch_env!(:memba, :test_postmark_handoff_result) do
      {:ok, %{message_ids: _ids} = match} ->
        {:ok, match}

      {:ok, provider_id} ->
        {:ok, %{message_ids: [provider_id <> delivery_id], duplicate_count: 0, complete?: true}}

      other ->
        other
    end
  end
end
