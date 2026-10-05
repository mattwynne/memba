defmodule LiveQuery.Binding do
  @moduledoc """
  Manages a live-query lifecycle inside its owning LiveView process.

  The binding keeps registration metadata in one reserved socket assign. Each
  registration installs exactly one public result assign. Connected binding
  subscribes before reading, notifications refresh only matching registrations,
  and successful reads replace a result and its opaque interests together.

  Duplicate and out-of-order notifications are treated as invalidation hints:
  every currently matching notification rereads current state rather than
  applying the notification as a state patch.

  Access errors are returned to the owning LiveView as `{query_id, reason}`
  entries. The failed query's public result is cleared and its interests are
  emptied, while navigation, flash, raising, and other private-surface policy
  remain the owner's responsibility. The binding creates no process of its own.
  """

  alias LiveQuery.Query
  alias LiveQuery.Source

  @binding_assign :__live_query_binding__

  @type query_error :: {query_id :: term(), reason :: term()}
  @type result ::
          {:ok, Phoenix.LiveView.Socket.t()}
          | {:error, [query_error()], Phoenix.LiveView.Socket.t()}

  @doc """
  Registers and reads one query.

  A disconnected socket reads without subscribing. A connected socket
  subscribes its owning process before the read. Only one subscription is made
  for all registrations sharing the same source.
  """
  @spec bind(Phoenix.LiveView.Socket.t(), Query.t(), term(), Source.t()) :: result()
  def bind(socket, %Query{} = query, inputs, %Source{} = source) do
    with :ok <- source_compatible(socket, source, query.id),
         :ok <- registration_available(socket, query),
         {:ok, socket, mailbox_before} <- prepare_connected_bind(socket, source, query.id) do
      registration = %{query: query, inputs: inputs, interests: []}

      socket
      |> read_and_install(registration)
      |> reconcile_bind_window(mailbox_before, query.id)
    else
      {:error, errors, socket} -> {:error, errors, socket}
    end
  end

  @doc """
  Replaces an existing registration's route-dependent inputs.

  The new read replaces the old result and interests. If it fails, the old
  result is cleared and the old interests cannot trigger another refresh.
  """
  @spec rebind(Phoenix.LiveView.Socket.t(), term(), term()) :: result()
  def rebind(socket, query_id, inputs) do
    case fetch_registration(socket, query_id) do
      {:ok, registration} ->
        mailbox_before = if connected_and_subscribed?(socket), do: mailbox(), else: nil
        registration = %{registration | inputs: inputs}

        socket
        |> read_and_install(registration)
        |> reconcile_bind_window(mailbox_before, query_id)

      :error ->
        {:error, [{query_id, :not_registered}], socket}
    end
  end

  @doc """
  Classifies one source notification and refreshes matching registrations.

  Successful query refreshes replace only that query's result assign and
  interests. Access errors are accumulated and returned to the LiveView owner
  after all affected registrations have had a chance to refresh.
  """
  @spec handle_notification(Phoenix.LiveView.Socket.t(), term()) ::
          {:ignored, Phoenix.LiveView.Socket.t()} | result()
  def handle_notification(socket, notification) do
    case binding_state(socket) do
      %{source: %Source{} = source} ->
        case Source.classify(source, notification) do
          :ignore ->
            {:ignored, socket}

          {:ok, invalidations} when is_list(invalidations) ->
            refresh_matching(socket, invalidations, MapSet.new())

          other ->
            {:error, [{:source, {:invalid_classification, other}}], socket}
        end

      _binding ->
        {:ignored, socket}
    end
  end

  defp prepare_connected_bind(socket, source, query_id) do
    mailbox_before = if Phoenix.LiveView.connected?(socket), do: mailbox(), else: nil
    state = binding_state(socket)

    cond do
      not Phoenix.LiveView.connected?(socket) ->
        {:ok, put_binding(socket, %{state | source: source}), nil}

      state.subscribed? ->
        {:ok, socket, mailbox_before}

      true ->
        socket = put_binding(socket, %{state | source: source})

        case Source.subscribe(source) do
          :ok ->
            {:ok, put_binding(socket, %{binding_state(socket) | subscribed?: true}),
             mailbox_before}

          {:error, reason} ->
            {:error, [{query_id, {:subscription_failed, reason}}], socket}

          other ->
            {:error, [{query_id, {:invalid_subscription_result, other}}], socket}
        end
    end
  end

  defp read_and_install(socket, %{query: query} = registration) do
    case Query.load(query, registration.inputs) do
      {:ok, result, interests} when is_list(interests) ->
        registration = %{registration | interests: interests}

        socket =
          socket
          |> Phoenix.Component.assign(query.assign, result)
          |> put_registration(query.id, registration)

        {:ok, socket}

      {:error, reason} ->
        socket =
          socket
          |> Phoenix.Component.assign(query.assign, nil)
          |> put_registration(query.id, %{registration | interests: []})

        {:error, reason, socket}

      other ->
        reason = {:invalid_query_result, other}

        socket =
          socket
          |> Phoenix.Component.assign(query.assign, nil)
          |> put_registration(query.id, %{registration | interests: []})

        {:error, reason, socket}
    end
  end

  defp reconcile_bind_window(read_result, nil, query_id),
    do: public_read_result(read_result, query_id)

  defp reconcile_bind_window(read_result, mailbox_before, query_id) do
    socket = read_result_socket(read_result)
    source = binding_state(socket).source

    {notifications, invalidations} =
      mailbox_before
      |> new_mailbox_messages(mailbox())
      |> Enum.reduce({[], []}, fn message, {notifications, invalidations} ->
        case Source.classify(source, message) do
          {:ok, message_invalidations} when is_list(message_invalidations) ->
            {[message | notifications], message_invalidations ++ invalidations}

          _ignored_or_invalid ->
            {notifications, invalidations}
        end
      end)

    Enum.each(Enum.reverse(notifications), &consume_message/1)

    if notifications == [] do
      public_read_result(read_result, query_id)
    else
      refresh_matching(socket, Enum.reverse(invalidations), MapSet.new([query_id]))
    end
  end

  defp read_result_socket({:ok, socket}), do: socket
  defp read_result_socket({:error, _reason, socket}), do: socket

  defp public_read_result({:ok, socket}, _query_id), do: {:ok, socket}

  defp public_read_result({:error, reason, socket}, query_id),
    do: {:error, [{query_id, reason}], socket}

  defp refresh_matching(socket, invalidations, forced_query_ids) do
    state = binding_state(socket)

    query_ids =
      Enum.filter(state.order, fn query_id ->
        MapSet.member?(forced_query_ids, query_id) or
          registration_matches?(
            Map.fetch!(state.registrations, query_id),
            invalidations,
            state.source
          )
      end)

    case query_ids do
      [] ->
        {:ignored, socket}

      query_ids ->
        {socket, errors} =
          Enum.reduce(query_ids, {socket, []}, fn query_id, {socket, errors} ->
            registration = Map.fetch!(binding_state(socket).registrations, query_id)

            case read_and_install(socket, registration) do
              {:ok, socket} -> {socket, errors}
              {:error, reason, socket} -> {socket, [{query_id, reason} | errors]}
            end
          end)

        case Enum.reverse(errors) do
          [] -> {:ok, socket}
          errors -> {:error, errors, socket}
        end
    end
  end

  defp registration_matches?(registration, invalidations, source) do
    Enum.any?(registration.interests, fn interest ->
      Enum.any?(invalidations, &Source.matches?(source, interest, &1))
    end)
  end

  defp source_compatible(socket, source, query_id) do
    case binding_state(socket).source do
      nil -> :ok
      ^source -> :ok
      _other -> {:error, [{query_id, :different_source}], socket}
    end
  end

  defp registration_available(socket, query) do
    state = binding_state(socket)

    cond do
      Map.has_key?(state.registrations, query.id) ->
        {:error, [{query.id, :already_registered}], socket}

      Enum.any?(state.registrations, fn {_id, registration} ->
        registration.query.assign == query.assign
      end) ->
        {:error, [{query.id, {:assign_already_registered, query.assign}}], socket}

      true ->
        :ok
    end
  end

  defp fetch_registration(socket, query_id) do
    Map.fetch(binding_state(socket).registrations, query_id)
  end

  defp put_registration(socket, query_id, registration) do
    state = binding_state(socket)

    order =
      if Map.has_key?(state.registrations, query_id) do
        state.order
      else
        state.order ++ [query_id]
      end

    put_binding(socket, %{
      state
      | order: order,
        registrations: Map.put(state.registrations, query_id, registration)
    })
  end

  defp connected_and_subscribed?(socket) do
    Phoenix.LiveView.connected?(socket) and binding_state(socket).subscribed?
  end

  defp binding_state(socket) do
    Map.get(socket.assigns, @binding_assign, %{
      source: nil,
      subscribed?: false,
      order: [],
      registrations: %{}
    })
  end

  defp put_binding(socket, state) do
    Phoenix.Component.assign(socket, @binding_assign, state)
  end

  defp mailbox do
    {:messages, messages} = Process.info(self(), :messages)
    messages
  end

  defp new_mailbox_messages(messages_before, messages_after) do
    Enum.reduce(messages_before, messages_after, fn message, remaining ->
      List.delete(remaining, message)
    end)
  end

  defp consume_message(message) do
    receive do
      ^message -> :ok
    after
      0 -> :already_consumed
    end
  end
end
