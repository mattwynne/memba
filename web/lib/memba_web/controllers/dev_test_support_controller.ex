defmodule MembaWeb.DevTestSupportController do
  @moduledoc false

  use MembaWeb, :controller

  import Ecto.Query

  alias Memba.Accounts
  alias Memba.Accounts.SignInToken
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.EmailDeliveryProviders.Local, as: LocalEmailDeliveryProvider
  alias Memba.Repo

  @projection_versions_table :projection_versions
  @projectors [
    Memba.Membership.Projectors.Club,
    Memba.Membership.Projectors.ClubInvitation,
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Role,
    Memba.Membership.Projectors.Person,
    Memba.Messaging.Projectors.Message,
    Memba.Messaging.Projectors.ConversationGroupAccess,
    Memba.Messaging.Projectors.ConversationFollow,
    Memba.Messaging.Projectors.EmailDelivery,
    Memba.Messaging.Projectors.MemberEmailDelivery,
    Memba.Messaging.Projectors.MembaStaffEmailDelivery,
    Memba.Messaging.Projectors.InboundEmailSource
  ]
  @public_reset_tables [:auth_email_requests, :auth_sign_in_tokens, :onboarding_requests]

  @messaging_email_delivery_providers %{
    "fake" => Memba.Messaging.EmailDeliveryProviders.Fake,
    "local" => Memba.Messaging.EmailDeliveryProviders.Local,
    "unavailable" => Memba.Messaging.EmailDeliveryProviders.Unavailable
  }

  def expire_auth_link(conn, %{"email" => email}) do
    normalized_email = Accounts.normalize_email(email)
    expired_at = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)

    SignInToken
    |> where([token], token.email == ^normalized_email)
    |> order_by([token], desc: token.inserted_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      %SignInToken{} = token ->
        token
        |> Ecto.Changeset.change(expires_at: expired_at)
        |> Repo.update!()

      nil ->
        :ok
    end

    send_resp(conn, :no_content, "")
  end

  def reset_acceptance_state(conn, _params) do
    projector_child_ids = stop_event_sourced_projectors!()

    try do
      reset_event_store!()
      reset_public_tables!()
      reset_acceptance_application_state!()
    after
      start_event_sourced_projectors!(projector_child_ids)
    end

    send_resp(conn, :no_content, "")
  end

  def seed(conn, _params) do
    Memba.DevSeeds.run()
    Memba.DevSeeds.deliver_representative_emails()

    send_resp(conn, :no_content, "")
  end

  def stop_follow_url(conn, _params) do
    {:ok, token} =
      ConversationStopFollowToken.sign(%{
        club_id: "clb_11111111-1111-1111-1111-111111111111",
        conversation_id: "msg_30000000-0000-0000-0000-000000000001",
        member_id: "per_dddddddd-dddd-dddd-dddd-dddddddddddd"
      })

    json(conn, %{path: "/messages/conversations/stop-following/#{token}"})
  end

  def configure_messaging_email_delivery_provider(conn, %{"provider" => provider_name}) do
    with {:ok, provider} <- Map.fetch(@messaging_email_delivery_providers, provider_name),
         true <- Code.ensure_loaded?(provider) do
      Application.put_env(:memba, :messaging_email_delivery_provider, provider)

      send_resp(conn, :no_content, "")
    else
      _unknown_or_unavailable ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "unknown messaging email delivery provider"})
    end
  end

  def sign_in(conn, %{"email" => email}) do
    conn
    |> MembaWeb.IdentityAuth.log_in_identity(email)
    |> send_resp(:no_content, "")
  end

  def read_model_change_events(conn, _params) do
    Phoenix.PubSub.subscribe(Memba.PubSub, Memba.ReadModelChanges.topic())

    conn =
      conn
      |> put_resp_content_type("text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(:ok)

    case write_sse(conn, "ready", %{ready: true}) do
      {:ok, conn} -> stream_read_model_changes(conn)
      {:error, _reason} -> conn
    end
  end

  defp stream_read_model_changes(conn) do
    receive do
      {:read_model_changed, payload} ->
        case write_sse(conn, "read_model_changed", read_model_change_payload(payload)) do
          {:ok, conn} -> stream_read_model_changes(conn)
          {:error, _reason} -> conn
        end
    after
      30_000 ->
        case Plug.Conn.chunk(conn, ": heartbeat\n\n") do
          {:ok, conn} -> stream_read_model_changes(conn)
          {:error, _reason} -> conn
        end
    end
  end

  defp write_sse(conn, event, payload) do
    Plug.Conn.chunk(conn, "event: #{event}\ndata: #{Jason.encode!(payload)}\n\n")
  end

  defp read_model_change_payload(%{projector: projector, source_event: event} = payload) do
    %{
      projector: inspect(projector),
      source_event_type: inspect(event.__struct__),
      source_event: normalize_read_model_change_value(event),
      metadata: normalize_read_model_change_value(Map.get(payload, :metadata, %{})),
      changes: normalize_read_model_change_value(Map.get(payload, :changes, %{}))
    }
  end

  defp normalize_read_model_change_value(%{__struct__: _struct} = value) do
    value
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> normalize_read_model_change_value()
  end

  defp normalize_read_model_change_value(value) when is_map(value) do
    value
    |> Enum.map(fn {key, value} ->
      {read_model_change_key(key), normalize_read_model_change_value(value)}
    end)
    |> Map.new()
  end

  defp normalize_read_model_change_value(value) when is_list(value) do
    Enum.map(value, &normalize_read_model_change_value/1)
  end

  defp normalize_read_model_change_value(value) when is_tuple(value) do
    value
    |> Tuple.to_list()
    |> normalize_read_model_change_value()
  end

  defp normalize_read_model_change_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_read_model_change_value(value), do: value

  defp read_model_change_key(key) when is_atom(key), do: Atom.to_string(key)
  defp read_model_change_key(key) when is_binary(key), do: key
  defp read_model_change_key(key), do: inspect(key)

  defp stop_event_sourced_projectors! do
    for {child_id, pid, :worker, [module]} <- Supervisor.which_children(Memba.Supervisor),
        module in @projectors do
      if is_pid(pid) do
        :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
      end

      child_id
    end
  end

  defp start_event_sourced_projectors!(child_ids) do
    Enum.each(child_ids, fn child_id ->
      case Supervisor.restart_child(Memba.Supervisor, child_id) do
        {:ok, _pid} -> :ok
        {:ok, _pid, _info} -> :ok
        {:error, :running} -> :ok
      end
    end)
  end

  defp reset_event_store! do
    schema = event_store_schema()

    Repo.transaction(fn ->
      Repo.query!(~s(SET LOCAL search_path TO #{quote_identifier(schema)};))
      Repo.query!(~s(SET LOCAL eventstore.reset TO 'on';))

      Repo.query!("""
      TRUNCATE TABLE snapshots, subscriptions, stream_events, streams, events
      RESTART IDENTITY;
      """)

      Repo.query!("""
      INSERT INTO streams (stream_id, stream_uuid, stream_version)
      VALUES (0, '$all', 0);
      """)
    end)
  end

  defp reset_acceptance_application_state! do
    Application.put_env(:memba, :messaging_email_delivery_provider, LocalEmailDeliveryProvider)
  end

  defp reset_public_tables! do
    tables =
      :memba
      |> Application.get_env(:event_sourced_projection_tables, [])
      |> List.wrap()
      |> then(fn tables -> @public_reset_tables ++ [@projection_versions_table | tables] end)
      |> Enum.uniq()

    if tables != [] do
      table_names =
        tables
        |> Enum.map(&qualified_public_table_name/1)
        |> Enum.join(", ")

      Repo.query!("TRUNCATE TABLE #{table_names} RESTART IDENTITY CASCADE;")
    end
  end

  defp event_store_schema do
    Memba.EventStore.config()
    |> Keyword.fetch!(:schema)
    |> to_string()
  end

  defp qualified_public_table_name(table), do: ~s(public.#{quote_identifier(table)})

  defp quote_identifier(identifier) do
    escaped =
      identifier
      |> to_string()
      |> String.replace(~s("), ~s(""))

    ~s("#{escaped}")
  end
end
