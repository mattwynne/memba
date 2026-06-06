defmodule Memba.Onboarding do
  @moduledoc """
  Public API for staff-approved request-to-club onboarding.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Onboarding.Request
  alias Memba.Repo

  @doc """
  Create a new active onboarding request.
  """
  def create_request(attrs, opts \\ []) when is_map(attrs) and is_list(opts) do
    attrs
    |> Request.create_changeset(opts)
    |> Repo.insert()
  end

  @doc """
  Build an onboarding request changeset for forms.
  """
  def change_request(attrs \\ %{}, opts \\ []) when is_map(attrs) and is_list(opts) do
    Request.create_changeset(attrs, opts)
  end

  @doc """
  Build a rejection changeset for staff triage forms.
  """
  def change_rejection(%Request{} = request, attrs \\ %{})
      when is_map(attrs) do
    Request.rejection_changeset(request, attrs)
  end

  @doc """
  List active onboarding requests, oldest first.
  """
  def list_active_requests do
    Request
    |> where([request], request.status == ^Request.status_active())
    |> order_by([request], asc: request.inserted_at, asc: request.request_id)
    |> Repo.all()
  end

  @doc """
  Fetch an onboarding request by typed request ID.
  """
  def get_request(request_id) do
    with {:ok, request_id} <- ID.cast(:onboarding_request, request_id) do
      Repo.get(Request, request_id)
    else
      :error -> nil
    end
  end

  @doc """
  Reject an active onboarding request with internal notes.
  """
  def reject_request(request_id, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    update_active_request(request_id, fn request ->
      request
      |> Request.rejection_changeset(attrs, opts)
      |> Repo.update()
    end)
  end

  @doc """
  Mark an active onboarding request as converted after the conversion records exist.
  """
  def convert_request(request_id, attrs, opts \\ [])
      when is_map(attrs) and is_list(opts) do
    update_active_request(request_id, fn request ->
      request
      |> Request.conversion_changeset(attrs, opts)
      |> Repo.update()
    end)
  end

  defp update_active_request(request_id, update_fun) when is_function(update_fun, 1) do
    with {:ok, request_id} <- ID.cast(:onboarding_request, request_id) do
      request_id
      |> transact_active_update(update_fun)
      |> unwrap_transaction()
    else
      :error -> {:error, :not_found}
    end
  end

  defp transact_active_update(request_id, update_fun) do
    Repo.transaction(fn ->
      case lock_request(request_id) do
        nil ->
          Repo.rollback(:not_found)

        %Request{status: status} when status != "active" ->
          Repo.rollback(:not_active)

        %Request{} = request ->
          case update_fun.(request) do
            {:ok, request} -> request
            {:error, changeset} -> Repo.rollback(changeset)
          end
      end
    end)
  end

  defp lock_request(request_id) do
    Request
    |> where([request], request.request_id == ^request_id)
    |> lock("FOR UPDATE")
    |> Repo.one()
  end

  defp unwrap_transaction({:ok, %Request{} = request}), do: {:ok, request}
  defp unwrap_transaction({:error, reason}), do: {:error, reason}
end
