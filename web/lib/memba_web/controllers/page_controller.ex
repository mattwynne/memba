defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Messaging
  alias MembaWeb.MemberReceiptPresentation

  @member_receipt_status_order ["opened", "delivered", "sent", "delivery problem"]

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
      when not is_nil(identity) do
    render_club_home(conn, club_id)
  end

  def home(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil ->
        not_found(conn)

      _club ->
        Phoenix.LiveView.Controller.live_render(conn, MembaWeb.ClubMarketingLive,
          session: %{"club_id" => club_id}
        )
    end
  end

  def home(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "My clubs"
      else
        "Membership made calm"
      end

    conn
    |> assign(:page_title, page_title)
    |> render(:home)
  end

  def send_message(%{assigns: %{current_identity: identity}} = conn, %{
        "club_id" => club_id,
        "message" => message_params
      })
      when not is_nil(identity) do
    selected_club = selected_club(conn, club_id)
    sender_id = Map.get(message_params, "sender_id")

    cond do
      is_nil(selected_club) ->
        not_found(conn)

      not Membership.active_member_of_club?(club_id, sender_id) ->
        conn
        |> put_flash(:error, "Choose an active member as the sender.")
        |> render_club_home(club_id, message_params)

      true ->
        attrs =
          message_params
          |> Map.take(["sender_id", "subject", "body"])
          |> Map.merge(%{
            "message_id" => Ecto.UUID.generate(),
            "club_id" => club_id
          })

        case Messaging.send_club_message(attrs, consistency: :strong) do
          :ok ->
            conn
            |> put_flash(:info, "Message sent")
            |> redirect(to: ~p"/?#{[club_id: club_id]}")

          {:ok, _result} ->
            conn
            |> put_flash(:info, "Message sent")
            |> redirect(to: ~p"/?#{[club_id: club_id]}")

          {:error, reason} ->
            conn
            |> put_flash(:error, "Could not send message: #{format_reason(reason)}")
            |> render_club_home(club_id, message_params)
        end
    end
  end

  def show_message(conn, %{"club_id" => club_id, "message_id" => message_id}) do
    case Ecto.UUID.cast(club_id) do
      {:ok, club_id} ->
        selected_club = selected_club(conn, club_id)
        message = Messaging.get_message(message_id)

        cond do
          is_nil(selected_club) ->
            forbidden(conn)

          is_nil(message) or message.club_id != club_id ->
            not_found(conn)

          true ->
            receipts =
              message.message_id
              |> Messaging.list_member_receipts()
              |> Enum.map(&MemberReceiptPresentation.present_receipt/1)

            sender = Membership.get_person(message.sender_id)

            conn
            |> assign(:page_title, message.subject)
            |> assign(:selected_club, selected_club)
            |> assign(:message, message)
            |> assign(:sender_name, sender_name(sender))
            |> assign(:member_receipts, receipts)
            |> assign(:member_receipt_count, Enum.count(receipts))
            |> assign(:member_receipt_groups, member_receipt_groups(receipts))
            |> render(:message)
        end

      :error ->
        forbidden(conn)
    end
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def terms(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end

  defp render_club_home(
         conn,
         club_id,
         message_params \\ %{"sender_id" => "", "subject" => "", "body" => ""}
       ) do
    case selected_club(conn, club_id) do
      nil ->
        not_found(conn)

      selected_club ->
        members =
          club_id
          |> Membership.list_active_members_of_club()
          |> Enum.map(&with_member_initials/1)

        messages =
          club_id
          |> Messaging.list_messages_for_club()
          |> Enum.reverse()

        current_member = current_member_for_identity(members, conn.assigns.current_identity)
        message_params = put_default_sender(message_params, current_member)

        conn
        |> assign(:page_title, selected_club.name)
        |> assign(:selected_club, selected_club)
        |> assign(:members, members)
        |> assign(:active_member_count, Enum.count(members))
        |> assign(:current_member, current_member)
        |> assign(:member_names_by_id, Map.new(members, &{&1.id, &1.name}))
        |> assign(:member_options, Enum.map(members, &{&1.name, &1.id}))
        |> assign(:messages, messages)
        |> assign(:message_form, Phoenix.Component.to_form(message_params, as: :message))
        |> render(:club)
    end
  end

  defp selected_club(conn, club_id) do
    Enum.find(conn.assigns.current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp sender_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp sender_name(_sender), do: "Club member"

  defp member_receipt_groups(receipts) do
    receipts_by_status = Enum.group_by(receipts, & &1.status)
    extra_statuses = Map.keys(receipts_by_status) -- @member_receipt_status_order

    (@member_receipt_status_order ++ Enum.sort(extra_statuses))
    |> Enum.map(fn status ->
      status_receipts = Map.get(receipts_by_status, status, [])
      presentation = MemberReceiptPresentation.present_status(status)

      %{
        status: status,
        status_label: presentation.label,
        status_icon: presentation.icon,
        count: Enum.count(status_receipts),
        receipts: status_receipts
      }
    end)
    |> Enum.reject(&(&1.count == 0))
  end

  defp current_member_for_identity(_members, nil), do: nil

  defp current_member_for_identity(members, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    Enum.find(members, fn member -> Accounts.normalize_email(member.email) == identity_email end)
  end

  defp put_default_sender(message_params, nil), do: message_params

  defp put_default_sender(message_params, current_member) do
    case Map.get(message_params, "sender_id") do
      value when value in [nil, ""] -> Map.put(message_params, "sender_id", current_member.id)
      _value -> message_params
    end
  end

  defp with_member_initials(member) do
    Map.put(member, :initials, initials(member.name))
  end

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn <<first::utf8, _rest::binary>> -> String.upcase(<<first::utf8>>) end)
    |> case do
      "" -> "?"
      value -> value
    end
  end

  defp initials(_name), do: "?"

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end

  defp forbidden(conn) do
    conn
    |> send_resp(:forbidden, "Forbidden")
    |> halt()
  end

  defp format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")
end
