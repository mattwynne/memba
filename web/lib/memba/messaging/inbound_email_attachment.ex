defmodule Memba.Messaging.InboundEmailAttachment do
  @moduledoc """
  Provider-neutral attachment metadata from an inbound email.

  Attachments are not supported for posting in this iteration, but preserving
  metadata in the inbound command lets later policy code reject them without
  depending on a provider-specific payload shape.
  """

  defstruct [:filename, :content_type, :size, :content_id]

  @type t :: %__MODULE__{
          filename: String.t() | nil,
          content_type: String.t() | nil,
          size: non_neg_integer() | nil,
          content_id: String.t() | nil
        }

  @doc """
  Build attachment metadata from atom- or string-keyed provider-neutral attrs.
  """
  @spec new(map()) :: {:ok, t()} | {:error, :invalid_attachment}
  def new(attrs) when is_map(attrs) do
    with {:ok, size} <- optional_size(fetch_optional(attrs, :size)) do
      {:ok,
       %__MODULE__{
         filename: optional_string(fetch_optional(attrs, :filename)),
         content_type: optional_string(fetch_optional(attrs, :content_type)),
         size: size,
         content_id: optional_string(fetch_optional(attrs, :content_id))
       }}
    end
  end

  def new(_attrs), do: {:error, :invalid_attachment}

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> value
      %{^string_key => value} -> value
      _attrs -> nil
    end
  end

  defp optional_string(nil), do: nil

  defp optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp optional_string(_value), do: nil

  defp optional_size(nil), do: {:ok, nil}
  defp optional_size(size) when is_integer(size) and size >= 0, do: {:ok, size}
  defp optional_size(_size), do: {:error, :invalid_attachment}
end
