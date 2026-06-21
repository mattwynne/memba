defmodule Memba.Messaging.ConversationStopFollowToken do
  @moduledoc """
  Encrypted, signed tokens for one-click reply-email stop-follow links.

  The token payload is scoped to exactly one club, conversation, and member. The
  encrypted Phoenix token keeps those identifiers opaque to recipients while the
  signature prevents tampering.
  """

  alias Memba.ID
  alias MembaWeb.Endpoint

  @salt "conversation stop follow v1"
  @version 1

  @type scope :: %{
          club_id: String.t(),
          conversation_id: String.t(),
          member_id: String.t()
        }

  @doc """
  Create a long-lived opaque token scoped to one follow state.
  """
  @spec sign(scope()) :: {:ok, String.t()} | {:error, :invalid}
  def sign(attrs) when is_map(attrs) do
    with {:ok, scope} <- normalize_scope(attrs) do
      token =
        Phoenix.Token.encrypt(
          Endpoint,
          @salt,
          Map.put(scope, :version, @version),
          max_age: :infinity
        )

      {:ok, token}
    end
  end

  def sign(_attrs), do: {:error, :invalid}

  @doc """
  Verify and decrypt a stop-follow token.
  """
  @spec verify(String.t()) :: {:ok, scope()} | {:error, :invalid}
  def verify(token) when is_binary(token) do
    case Phoenix.Token.decrypt(Endpoint, @salt, token, max_age: :infinity) do
      {:ok, %{version: @version} = scope} -> normalize_scope(scope)
      {:ok, _wrong_shape} -> {:error, :invalid}
      {:error, _reason} -> {:error, :invalid}
    end
  end

  def verify(_token), do: {:error, :invalid}

  defp normalize_scope(attrs) do
    with {:ok, club_id} <- cast_id(attrs, :club_id, :club),
         {:ok, conversation_id} <- cast_id(attrs, :conversation_id, :message),
         {:ok, member_id} <- cast_id(attrs, :member_id, :person) do
      {:ok, %{club_id: club_id, conversation_id: conversation_id, member_id: member_id}}
    else
      :error -> {:error, :invalid}
      {:error, :invalid} -> {:error, :invalid}
    end
  end

  defp cast_id(attrs, key, type) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> ID.cast(type, value)
      :error -> :error
    end
  end
end
