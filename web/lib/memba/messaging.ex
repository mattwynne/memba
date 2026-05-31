defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Memba.Membership
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.Projections.MemberReceipt, as: MemberReceiptProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.OperatorDeliverability, as: OperatorDeliverabilityProjection
  alias Memba.Messaging.Projections.RecipientDelivery, as: RecipientDeliveryProjection
  alias Memba.Messaging.Recipient
  alias Memba.Repo

  import Ecto.Query

  @doc """
  Send a message to the active members of a club.

  The service resolves recipients through Membership's public query API, builds
  a `SendMessage` command containing those resolved recipients, and dispatches it
  to the Messaging Commanded application.
  """
  def send_club_message(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- send_club_message_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts),
         :ok <- deliver_to_provider(command) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient delivery was accepted by the recipient server.
  """
  def report_delivery_delivered(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_delivery_delivered_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient delivery was temporarily delayed.
  """
  def report_delivery_delayed(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_delivery_delayed_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient delivery bounced.
  """
  def report_delivery_bounced(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_delivery_bounced_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient marked a delivery as spam.
  """
  def report_delivery_spam_complaint(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_delivery_spam_complaint_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient opened a delivery.
  """
  def report_delivery_opened(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_delivery_opened_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Fetch a projected message read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_message(message_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id) do
      Repo.get(MessageProjection, message_id)
    else
      :error -> nil
    end
  end

  @doc """
  List projected messages sent to a club.

  Invalid or missing club IDs return an empty list. Results are ordered by
  insertion time and ID for stable browser/test output.
  """
  def list_messages_for_club(club_id) do
    with {:ok, club_id} <- Ecto.UUID.cast(club_id) do
      MessageProjection
      |> where([message], message.club_id == ^club_id)
      |> order_by([message], asc: message.inserted_at, asc: message.message_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Fetch a projected recipient delivery read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_recipient_delivery(delivery_id) do
    with {:ok, delivery_id} <- Ecto.UUID.cast(delivery_id) do
      Repo.get(RecipientDeliveryProjection, delivery_id)
    else
      :error -> nil
    end
  end

  @doc """
  List recipient delivery records for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_recipient_deliveries(message_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id) do
      RecipientDeliveryProjection
      |> where([delivery], delivery.message_id == ^message_id)
      |> order_by([delivery], asc: delivery.recipient_name, asc: delivery.recipient_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Fetch a member-facing receipt read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_member_receipt(delivery_id) do
    with {:ok, delivery_id} <- Ecto.UUID.cast(delivery_id) do
      Repo.get(MemberReceiptProjection, delivery_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch a member-facing receipt for a recipient on a message.

  Invalid or missing IDs return `nil`. The receipt status uses ADR 0006's
  simplified member vocabulary: sent, delivered, delivery problem, or opened.
  """
  def get_member_receipt(message_id, recipient_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id),
         {:ok, recipient_id} <- Ecto.UUID.cast(recipient_id) do
      Repo.get_by(MemberReceiptProjection, message_id: message_id, recipient_id: recipient_id)
    else
      :error -> nil
    end
  end

  @doc """
  List member-facing receipt records for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_member_receipts(message_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id) do
      MemberReceiptProjection
      |> where([receipt], receipt.message_id == ^message_id)
      |> order_by([receipt], asc: receipt.recipient_name, asc: receipt.recipient_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Fetch an operator deliverability read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_operator_deliverability(delivery_id) do
    with {:ok, delivery_id} <- Ecto.UUID.cast(delivery_id) do
      Repo.get(OperatorDeliverabilityProjection, delivery_id)
    else
      :error -> nil
    end
  end

  @doc """
  Fetch an operator deliverability record for a recipient on a message.

  Invalid or missing IDs return `nil`. This view keeps detailed delivery status
  and reason text for delayed, bounced, and spam complaint reports.
  """
  def get_operator_deliverability(message_id, recipient_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id),
         {:ok, recipient_id} <- Ecto.UUID.cast(recipient_id) do
      Repo.get_by(OperatorDeliverabilityProjection,
        message_id: message_id,
        recipient_id: recipient_id
      )
    else
      :error -> nil
    end
  end

  @doc """
  List operator-facing delivery records for the deliveries overview.

  Results include message subject and event timestamp fields populated from the
  messaging projections and are ordered newest event first. Pass
  `message_id: message_id` to narrow the overview to one projected message.
  Invalid options return an empty list.
  """
  def list_operator_deliveries(opts \\ []) do
    if is_list(opts) do
      with {:ok, query} <- operator_deliveries_query(opts) do
        Repo.all(query)
      else
        :error -> []
      end
    else
      []
    end
  end

  @doc """
  List operator deliverability records for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_operator_deliverabilities(message_id) do
    with {:ok, message_id} <- Ecto.UUID.cast(message_id) do
      OperatorDeliverabilityProjection
      |> where([deliverability], deliverability.message_id == ^message_id)
      |> order_by([deliverability],
        asc: deliverability.recipient_name,
        asc: deliverability.recipient_id
      )
      |> Repo.all()
    else
      :error -> []
    end
  end

  defp operator_deliveries_query(opts) do
    query =
      from deliverability in OperatorDeliverabilityProjection,
        join: message in MessageProjection,
        on: message.message_id == deliverability.message_id,
        order_by: [desc: deliverability.updated_at, desc: deliverability.delivery_id],
        select_merge: %{
          message_subject: message.subject,
          event_at: deliverability.updated_at
        }

    case Keyword.fetch(opts, :message_id) do
      {:ok, message_id} ->
        with {:ok, message_id} <- Ecto.UUID.cast(message_id) do
          {:ok,
           where(query, [deliverability, _message], deliverability.message_id == ^message_id)}
        else
          :error -> :error
        end

      :error ->
        {:ok, query}
    end
  end

  defp dispatch_command(command, dispatch_opts) do
    case App.dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> {:ok, ok}
      {:error, _reason} = error -> error
    end
  end

  defp send_club_message_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, sender_id} <- fetch_required(attrs, :sender_id),
         {:ok, subject} <- fetch_required(attrs, :subject),
         {:ok, body} <- fetch_required(attrs, :body) do
      {:ok,
       %SendMessage{
         message_id: message_id,
         club_id: club_id,
         sender_id: sender_id,
         subject: subject,
         body: body,
         recipients: resolve_recipients(club_id)
       }}
    end
  end

  defp report_delivery_delivered_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id) do
      {:ok, %ReportDeliveryDelivered{message_id: message_id, delivery_id: delivery_id}}
    end
  end

  defp report_delivery_delayed_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportDeliveryDelayed{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp report_delivery_bounced_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportDeliveryBounced{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp report_delivery_spam_complaint_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportDeliverySpamComplaint{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp report_delivery_opened_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id) do
      {:ok, %ReportDeliveryOpened{message_id: message_id, delivery_id: delivery_id}}
    end
  end

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp resolve_recipients(club_id) do
    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.map(&resolved_recipient/1)
  end

  defp resolved_recipient(%{id: person_id, name: name, email: email}) do
    %Recipient{
      delivery_id: Ecto.UUID.generate(),
      person_id: person_id,
      name: name,
      email: email
    }
  end

  defp deliver_to_provider(%SendMessage{} = command) do
    Enum.reduce_while(command.recipients, :ok, fn %Recipient{} = recipient, :ok ->
      case DeliveryProvider.deliver(delivery_request(command, recipient)) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp delivery_request(%SendMessage{} = command, %Recipient{} = recipient) do
    %DeliveryRequest{
      message_id: command.message_id,
      delivery_id: recipient.delivery_id,
      recipient_id: recipient.person_id,
      recipient_name: recipient.name,
      recipient_address: recipient.email,
      channel: :email,
      subject: command.subject,
      body: command.body
    }
  end
end
