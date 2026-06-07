defmodule Memba.Onboarding do
  @moduledoc """
  Public API for staff-approved request-to-club onboarding.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AssignMemberRole
  alias Memba.Membership.Roles
  alias Memba.Onboarding.Request
  alias Memba.Onboarding.WelcomeEmail
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

  @doc """
  Convert an active onboarding request into a club, first active member, and
  converted request audit record.

  Event-sourced Membership commands are dispatched with strong consistency so
  the projected club, person, and membership exist before the request is marked
  converted. The welcome email side effect runs only after the conversion
  transaction has committed and its result is returned under `:welcome_email`.
  """
  def convert_request_to_club(request_id, club_attrs, opts \\ [])
      when is_map(club_attrs) and is_list(opts) do
    request_id
    |> fetch_active_request()
    |> create_conversion_records(club_attrs, opts)
    |> mark_request_converted(opts)
    |> load_conversion_read_models()
    |> deliver_conversion_welcome_email(opts)
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

  defp fetch_active_request(request_id) do
    with {:ok, request_id} <- ID.cast(:onboarding_request, request_id) do
      request_id
      |> transact_active_fetch()
      |> unwrap_active_fetch_transaction()
    else
      :error -> {:error, :not_found}
    end
  end

  defp transact_active_fetch(request_id) do
    Repo.transaction(fn ->
      case lock_request(request_id) do
        nil ->
          Repo.rollback(:not_found)

        %Request{status: status} when status != "active" ->
          Repo.rollback(:not_active)

        %Request{} = request ->
          request
      end
    end)
  end

  defp unwrap_active_fetch_transaction({:ok, %Request{} = request}), do: {:ok, request}
  defp unwrap_active_fetch_transaction({:error, reason}), do: {:error, reason}

  defp create_conversion_records({:error, reason}, _club_attrs, _opts), do: {:error, reason}

  defp create_conversion_records({:ok, %Request{} = request}, club_attrs, opts) do
    club_id = ID.generate(:club)
    person = conversion_person(request)
    membership_id = ID.generate(:membership)

    request_conversion_attrs = %{
      converted_club_id: club_id,
      converted_person_id: person.person_id,
      converted_membership_id: membership_id
    }

    with :ok <- validate_request_conversion(request, request_conversion_attrs, opts),
         :ok <- create_conversion_club(club_id, club_attrs),
         :ok <- create_conversion_person(person),
         :ok <- create_conversion_membership(membership_id, club_id, person.person_id),
         :ok <-
           assign_conversion_membership_administrator(
             club_id,
             membership_id,
             person.person_id
           ) do
      %{
        request: request,
        request_conversion_attrs: request_conversion_attrs,
        club_id: club_id,
        person_id: person.person_id,
        membership_id: membership_id,
        person_reused?: person.reused?
      }
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_request_conversion(%Request{} = request, attrs, opts) do
    changeset = Request.conversion_changeset(request, attrs, opts)

    if changeset.valid? do
      :ok
    else
      {:error, changeset}
    end
  end

  defp create_conversion_club(club_id, club_attrs) do
    attrs =
      club_attrs
      |> Map.take([:name, :slug, "name", "slug"])
      |> Map.put(:club_id, club_id)

    attrs
    |> Membership.create_club(consistency: :strong)
    |> normalize_command_result()
  end

  defp conversion_person(%Request{} = request) do
    case Membership.get_person_by_email(request.requester_email) do
      nil ->
        person_id = ID.generate(:person)

        %{
          person_id: person_id,
          reused?: false,
          attrs: %{
            person_id: person_id,
            name: request.requester_name,
            email: request.requester_email
          }
        }

      person ->
        %{person_id: person.person_id, reused?: true, attrs: nil}
    end
  end

  defp create_conversion_person(%{reused?: true}), do: :ok

  defp create_conversion_person(%{attrs: attrs}) do
    attrs
    |> Membership.create_person(consistency: :strong)
    |> normalize_command_result()
  end

  defp create_conversion_membership(membership_id, club_id, person_id) do
    %{
      membership_id: membership_id,
      club_id: club_id,
      person_id: person_id
    }
    |> Membership.add_member(consistency: :strong)
    |> normalize_command_result()
  end

  defp assign_conversion_membership_administrator(club_id, membership_id, person_id) do
    %AssignMemberRole{
      club_id: club_id,
      membership_id: membership_id,
      person_id: person_id,
      role_id: Roles.membership_administrator_role_id(club_id)
    }
    |> MembershipApp.dispatch(consistency: :strong)
    |> normalize_command_result()
  end

  defp normalize_command_result(:ok), do: :ok
  defp normalize_command_result({:ok, _result}), do: :ok
  defp normalize_command_result({:error, reason}), do: {:error, reason}

  defp mark_request_converted({:error, reason}, _opts), do: {:error, reason}

  defp mark_request_converted(%{request: %Request{} = request} = conversion, opts) do
    case convert_request(request.request_id, conversion.request_conversion_attrs, opts) do
      {:ok, %Request{} = converted_request} ->
        {:ok, %{conversion | request: converted_request}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_conversion_read_models({:error, reason}), do: {:error, reason}

  defp load_conversion_read_models({:ok, conversion}) do
    {:ok,
     conversion
     |> Map.put(:club, Membership.get_club(conversion.club_id))
     |> Map.put(:person, Membership.get_person(conversion.person_id))
     |> Map.delete(:request_conversion_attrs)}
  end

  defp deliver_conversion_welcome_email({:error, reason}, _opts), do: {:error, reason}

  defp deliver_conversion_welcome_email({:ok, conversion}, opts) do
    welcome_email_fun = Keyword.get(opts, :welcome_email_fun, &default_welcome_email/1)
    welcome_email_result = call_welcome_email_fun(welcome_email_fun, conversion)

    {:ok, Map.put(conversion, :welcome_email, welcome_email_result)}
  end

  defp call_welcome_email_fun(welcome_email_fun, conversion)
       when is_function(welcome_email_fun, 1) do
    welcome_email_fun.(conversion)
  rescue
    exception ->
      {:error,
       {:onboarding_welcome_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  defp default_welcome_email(conversion), do: WelcomeEmail.deliver(conversion)
end
