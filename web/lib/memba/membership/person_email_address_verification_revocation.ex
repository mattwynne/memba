defmodule Memba.Membership.PersonEmailAddressVerificationRevocation do
  @moduledoc """
  Complete replacement/removal side effects after Membership command dispatch.

  Never revoke a pending verification token on failed dispatch. Preserve the
  dispatch result (including explicit Commanded returning modes) on success.
  """

  alias Memba.ID
  alias Memba.Membership.{EmailAddresses, EmailAddressVerificationToken}

  def revoker(opts) do
    case Keyword.pop(opts, :verification_revoker) do
      {nil, opts} -> {fn request -> default_revoker(request, opts) end, opts}
      {revoker, opts} -> {revoker, opts}
    end
  end

  def after_dispatch({:error, _} = error, _requests, _revoker), do: error
  def after_dispatch(result, [], _revoker), do: result

  def after_dispatch(result, requests, revoker) do
    with :ok <- revoke_requests(requests, revoker), do: result
  end

  defp revoke_requests(requests, revoker) when is_list(requests) and is_function(revoker, 1) do
    Enum.reduce_while(requests, :ok, fn request, :ok ->
      case revoker.(request) do
        :ok -> {:cont, :ok}
        {:ok, _revoked} -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
        other -> {:halt, {:error, {:unexpected_email_address_verification_revoker_result, other}}}
      end
    end)
  end

  defp revoke_requests(_requests, _revoker),
    do: {:error, :invalid_email_address_verification_revoker}

  defp default_revoker(request, opts) do
    now = Keyword.get_lazy(opts, :now, fn -> DateTime.utc_now(:microsecond) end)

    with {:ok, person_id} <- cast_person_id(request.person_id),
         {:ok, %{normalized_email: normalized_email}} <-
           EmailAddresses.normalize_email(request.normalized_email) do
      EmailAddressVerificationToken.revoke_pending(person_id, normalized_email, now)
    else
      _invalid -> {:error, :invalid_email_address_verification_request}
    end
  end

  defp cast_person_id(id) do
    case ID.cast(:person, id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end
end
