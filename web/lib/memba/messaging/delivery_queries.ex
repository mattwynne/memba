defmodule Memba.Messaging.DeliveryQueries do
  @moduledoc """
  Projection-backed delivery and receipt reads for Messaging.

  Authorization of member and operator surfaces remains with their callers;
  these queries expose the same unscoped read models as the Messaging facade.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

  def list_operator_email_deliveries(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      MembaStaffEmailDeliveryProjection
      |> where([deliverability], deliverability.message_id == ^message_id)
      |> order_by([deliverability],
        asc: deliverability.recipient_name,
        asc: deliverability.recipient_id
      )
      |> Repo.all()
      |> Enum.map(&normalize_memba_staff_email_delivery/1)
    else
      :error -> []
    end
  end

  def list_operator_deliveries(opts \\ []) do
    if is_list(opts) do
      with {:ok, query} <- operator_deliveries_query(opts) do
        Repo.all(query)
        |> Enum.map(&normalize_memba_staff_email_delivery/1)
      else
        :error -> []
      end
    else
      []
    end
  end

  def get_memba_staff_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      MembaStaffEmailDeliveryProjection
      |> Repo.get(delivery_id)
      |> normalize_memba_staff_email_delivery()
    else
      :error -> nil
    end
  end

  def get_memba_staff_email_delivery(message_id, recipient_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, recipient_id} <- ID.cast(:person, recipient_id) do
      Repo.get_by(MembaStaffEmailDeliveryProjection,
        message_id: message_id,
        recipient_id: recipient_id
      )
      |> normalize_memba_staff_email_delivery()
    else
      :error -> nil
    end
  end

  def list_member_email_deliverys(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      from(receipt in MemberEmailDeliveryProjection,
        left_join: deliverability in MembaStaffEmailDeliveryProjection,
        on: deliverability.delivery_id == receipt.delivery_id,
        where: receipt.message_id == ^message_id,
        order_by: [asc: receipt.recipient_name, asc: receipt.recipient_id],
        select_merge: %{reason: deliverability.reason}
      )
      |> Repo.all()
      |> Enum.map(&normalize_member_email_delivery/1)
    else
      :error -> []
    end
  end

  def get_member_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      MemberEmailDeliveryProjection
      |> Repo.get(delivery_id)
      |> normalize_member_email_delivery()
    else
      :error -> nil
    end
  end

  def get_member_email_delivery(message_id, recipient_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, recipient_id} <- ID.cast(:person, recipient_id) do
      Repo.get_by(MemberEmailDeliveryProjection,
        message_id: message_id,
        recipient_id: recipient_id
      )
      |> normalize_member_email_delivery()
    else
      :error -> nil
    end
  end

  def list_recipient_deliveries(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      EmailDeliveryProjection
      |> where([delivery], delivery.message_id == ^message_id)
      |> order_by([delivery], asc: delivery.recipient_name, asc: delivery.recipient_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  def get_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      Repo.get(EmailDeliveryProjection, delivery_id)
    else
      :error -> nil
    end
  end

  defp normalize_member_email_delivery(%MemberEmailDeliveryProjection{} = receipt), do: receipt

  defp normalize_member_email_delivery(nil), do: nil

  defp normalize_memba_staff_email_delivery(%MembaStaffEmailDeliveryProjection{} = delivery) do
    delivery
  end

  defp normalize_memba_staff_email_delivery(nil), do: nil

  defp operator_deliveries_query(opts) do
    query =
      from deliverability in MembaStaffEmailDeliveryProjection,
        left_join: dispatch in EmailDeliveryProjection,
        on: dispatch.delivery_id == deliverability.delivery_id,
        join: message in MessageProjection,
        on: message.message_id == deliverability.message_id,
        order_by: [desc: deliverability.updated_at, desc: deliverability.delivery_id],
        select_merge: %{
          message_subject: message.subject,
          event_at: deliverability.updated_at,
          dispatch_status: dispatch.status,
          dispatch_attempt_count: dispatch.attempt_count,
          dispatch_latest_error: dispatch.latest_error,
          dispatch_latest_detail: dispatch.latest_detail
        }

    case Keyword.fetch(opts, :message_id) do
      {:ok, message_id} ->
        with {:ok, message_id} <- ID.cast(:message, message_id) do
          {:ok,
           where(query, [deliverability, _message], deliverability.message_id == ^message_id)}
        else
          :error -> :error
        end

      :error ->
        {:ok, query}
    end
  end
end
