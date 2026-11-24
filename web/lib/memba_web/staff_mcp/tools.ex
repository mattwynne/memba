defmodule MembaWeb.StaffMCP.Tools do
  @moduledoc false

  alias Memba.ID
  alias Memba.Membership.{ClubCommands, ClubGroupQueries, CommandDispatch}
  alias Memba.Membership.{ClubMemberInvitationEmail, InvitationIssuanceWorkflow}
  alias Memba.Membership.{PersonCommands, PersonEmailAddressCommands, PersonQueries}
  alias Memba.Membership.ClubMember.Remove
  alias Memba.Membership.Slug
  alias Memba.Messaging.{DeliveryQueries, MessageQueries}
  alias Memba.Onboarding
  alias MembaWeb.PersonEmailAddressTransition

  @club_fields ~w(club_id name slug)a
  @request_fields ~w(request_id requester_name requester_email requested_club_name note status
                     internal_rejection_notes triaged_by_staff_email triaged_at converted_club_id
                     converted_person_id converted_membership_id inserted_at)a
  @delivery_fields ~w(delivery_id message_id recipient_id recipient_name recipient_address channel
                      status reason message_subject event_at dispatch_status dispatch_attempt_count
                      dispatch_latest_error dispatch_latest_detail)a
  @message_fields ~w(message_id club_id sender_id conversation_id reply_to_message_id subject body
                     inserted_at)a
  @dispatch_fields ~w(delivery_id recipient_id recipient_name recipient_address channel status
                      attempt_count latest_error latest_detail last_dispatch_attempted_at sent_at
                      failed_at)a
  @receipt_fields ~w(delivery_id recipient_id recipient_name status reason)a
  @page [offset: :offset, limit: :limit]

  @tools [
    {"list_clubs", "List clubs and their site slugs.", [], @page, :read},
    {"get_club", "Get a club and a page of its active members.", [club_id: :club], @page, :read},
    {"suggest_club_slug", "Suggest and check the availability of a club slug from its name.",
     [name: :text], [], :read},
    {"create_club", "Create a club. Supply a stable club ID if retrying after a timeout.",
     [name: :text], [slug: :text, club_id: :club], :write},
    {"update_club", "Update a club's name and site slug.",
     [club_id: :club, name: :text, slug: :text], [], :write},
    {"remove_club_member", "Remove an active club membership.", [membership_id: :membership], [],
     :destructive},
    {"list_people", "List people, email addresses, and club memberships.", [], @page, :read},
    {"get_person", "Get a person's email addresses and verification status.",
     [person_id: :person], [], :read},
    {"create_person", "Create a person and set their primary and alternate email addresses.",
     [name: :text, email_addresses: :email_addresses], [person_id: :person], :write},
    {"replace_person_email_addresses",
     "Replace the person's full email address set. Exactly one address must be primary.",
     [person_id: :person, email_addresses: :email_addresses], [], :destructive},
    {"invite_club_member",
     "Email an invitation to join a club. Reissues an existing pending invitation.",
     [club_id: :club, email: :text], [], :write},
    {"list_onboarding_requests", "List active club onboarding requests.", [], @page, :read},
    {"get_onboarding_request", "Get an onboarding request and its triage status.",
     [request_id: :onboarding_request], [], :read},
    {"convert_onboarding_request",
     "Approve a request, create its club, and send the welcome email.",
     [request_id: :onboarding_request, name: :text], [slug: :text], :write},
    {"reject_onboarding_request", "Reject an active request and record internal notes.",
     [request_id: :onboarding_request, internal_rejection_notes: :text], [], :destructive},
    {"list_messages", "List messages with their club and sender details.", [], @page, :read},
    {"get_message", "Get a message, recipient dispatch details, and member receipts.",
     [message_id: :message], @page, :read},
    {"list_deliveries", "List email deliverability and dispatch diagnostics.", [],
     [message_id: :message] ++ @page, :read}
  ]

  def list do
    Enum.map(@tools, fn {name, description, required, optional, kind} ->
      %{
        name: name,
        description: description,
        inputSchema: object_schema(required, optional),
        annotations: %{
          readOnlyHint: kind == :read,
          destructiveHint: kind == :destructive,
          openWorldHint: name in ["invite_club_member", "convert_onboarding_request"]
        }
      }
    end)
  end

  def call(name, arguments, staff_email) do
    case List.keyfind(@tools, name, 0) do
      {^name, _description, required, optional, _kind} ->
        if valid_object?(arguments, required, optional) do
          name |> run(arguments, staff_email) |> tool_result()
        else
          {:error, "Arguments do not match the tool's input schema"}
        end

      nil ->
        {:error, "Unknown tool"}
    end
  end

  defp run("list_clubs", args, _email),
    do: ClubGroupQueries.list_clubs() |> page(args, &Map.take(&1, @club_fields))

  defp run("get_club", %{"club_id" => id} = args, _email) do
    with {:ok, club} <- found(ClubGroupQueries.get_club(id)) do
      members = ClubGroupQueries.list_active_members_of_club(id)
      member_page = page(members, args, &Map.put(&1, :person_id, &1.id))

      club_details =
        club |> Map.take(@club_fields) |> Map.put(:site_url, MembaWeb.ClubSite.url(club))

      Map.put(member_page, :club, club_details)
    end
  end

  defp run("suggest_club_slug", %{"name" => name}, _email) do
    with {:ok, slug} <- name |> Slug.default_from_name() |> Slug.validate() do
      %{slug: slug, available: is_nil(ClubGroupQueries.get_club_by_slug(slug))}
    end
  end

  defp run("create_club", args, _email) do
    id = Map.get_lazy(args, "club_id", fn -> ID.generate(:club) end)
    args |> Map.put("club_id", id) |> ClubCommands.prepare_create() |> dispatch(%{club_id: id})
  end

  defp run("update_club", %{"club_id" => id} = args, _email),
    do: args |> ClubCommands.prepare_update() |> dispatch(%{club_id: id})

  defp run("remove_club_member", %{"membership_id" => id} = args, _email),
    do: args |> Remove.prepare() |> dispatch(%{membership_id: id})

  defp run("list_people", args, _email), do: page(PersonQueries.list_operator_people(), args)

  defp run("get_person", %{"person_id" => id}, _email) do
    with {:ok, person} <- found(PersonQueries.get_person(id)) do
      addresses =
        Enum.map(PersonQueries.list_person_email_addresses(id), fn address ->
          %{email: address.email, is_primary: address.primary?, verified_at: address.verified_at}
        end)

      %{person_id: id, name: person.name, email_addresses: addresses}
    end
  end

  defp run("create_person", args, _email) do
    id = Map.get_lazy(args, "person_id", fn -> ID.generate(:person) end)

    args
    |> Map.put("person_id", id)
    |> PersonCommands.prepare_create()
    |> dispatch(%{person_id: id})
  end

  defp run("replace_person_email_addresses", %{"person_id" => id} = args, _email) do
    with :ok <-
           args
           |> PersonEmailAddressCommands.prepare_replace()
           |> PersonEmailAddressTransition.dispatch_prepared(consistency: :strong) do
      %{person_id: id}
    end
  end

  defp run("invite_club_member", %{"club_id" => id, "email" => email} = args, _staff_email) do
    with {:ok, club} <- found(ClubGroupQueries.get_club(id)),
         {:ok, invitation} <- InvitationIssuanceWorkflow.invite(args, consistency: :strong) do
      url =
        MembaWeb.Endpoint.url() <>
          "/invitations/club-members/" <>
          URI.encode(invitation.invitation_token, &URI.char_unreserved?/1)

      result =
        ClubMemberInvitationEmail.deliver(%{
          email: email,
          club: club,
          invitation_id: invitation.invitation_id,
          invitation_url: url
        })

      %{invitation_id: invitation.invitation_id, email_status: email_status(result)}
    end
  end

  defp run("list_onboarding_requests", args, _email),
    do: Onboarding.list_active_requests() |> page(args, &Map.take(&1, @request_fields))

  defp run("get_onboarding_request", %{"request_id" => id}, _email) do
    with {:ok, request} <- found(Onboarding.get_request(id)),
         do: Map.take(request, @request_fields)
  end

  defp run("convert_onboarding_request", %{"request_id" => id} = args, email) do
    with {:ok, conversion} <- Onboarding.convert_request_to_club(id, args, staff_email: email) do
      conversion
      |> Map.take([:club_id, :person_id, :membership_id])
      |> Map.put(:request_id, id)
      |> Map.put(:welcome_email_status, email_status(conversion.welcome_email))
    end
  end

  defp run("reject_onboarding_request", %{"request_id" => id} = args, email) do
    with {:ok, request} <- Onboarding.reject_request(id, args, staff_email: email),
         do: Map.take(request, @request_fields)
  end

  defp run("list_messages", args, _email), do: page(MessageQueries.list_operator_messages(), args)

  defp run("get_message", %{"message_id" => id} = args, _email) do
    with {:ok, message} <- found(MessageQueries.get_message(id)) do
      %{
        message: Map.take(message, @message_fields),
        dispatch:
          DeliveryQueries.list_recipient_deliveries(id)
          |> page(args, &Map.take(&1, @dispatch_fields)),
        receipts:
          DeliveryQueries.list_member_email_deliverys(id)
          |> page(args, &Map.take(&1, @receipt_fields))
      }
    end
  end

  defp run("list_deliveries", args, _email) do
    opts =
      case args do
        %{"message_id" => id} -> [message_id: id]
        _ -> []
      end

    DeliveryQueries.list_operator_deliveries(opts) |> page(args, &Map.take(&1, @delivery_fields))
  end

  defp found(nil), do: {:error, :not_found}
  defp found(record), do: {:ok, record}

  defp dispatch(preparation, result) do
    with {:ok, command} <- preparation do
      case CommandDispatch.dispatch(command, consistency: :strong) do
        :ok -> result
        {:ok, _execution} -> result
        {:error, _reason} = error -> error
      end
    end
  end

  defp email_status({:error, _reason}), do: "failed"
  defp email_status(_success), do: "sent"

  defp tool_result(%{} = result), do: {:ok, result}

  defp tool_result({:error, reason}) when is_atom(reason),
    do: {:tool_error, Atom.to_string(reason)}

  defp tool_result({:error, {reason, field}}) when is_atom(reason) and is_atom(field),
    do: {:tool_error, "#{reason}: #{field}"}

  defp tool_result({:error, %Ecto.Changeset{errors: errors}}) do
    fields = errors |> Keyword.keys() |> Enum.uniq() |> Enum.join(", ")
    {:tool_error, "Invalid fields: #{fields}"}
  end

  defp tool_result({:error, _reason}), do: {:tool_error, "Staff operation failed"}

  defp page(records, args, serialize \\ &Function.identity/1) do
    offset = Map.get(args, "offset", 0)
    limit = Map.get(args, "limit", 50)
    {items, remaining} = records |> Enum.drop(offset) |> Enum.split(limit)
    %{items: Enum.map(items, serialize), next_offset: if(remaining != [], do: offset + limit)}
  end

  defp object_schema(required, optional) do
    %{
      type: "object",
      properties: Map.new(required ++ optional, fn {key, type} -> {key, schema(type)} end),
      required: Keyword.keys(required),
      additionalProperties: false
    }
  end

  defp schema(:text), do: %{type: "string", minLength: 1}
  defp schema(:boolean), do: %{type: "boolean"}
  defp schema(:offset), do: %{type: "integer", minimum: 0}
  defp schema(:limit), do: %{type: "integer", minimum: 1, maximum: 100}

  defp schema(:email_addresses) do
    %{
      type: "array",
      minItems: 1,
      items: object_schema([email: :text, is_primary: :boolean], [])
    }
  end

  defp schema(id_type), do: %{type: "string", description: "Memba #{id_type} ID"}

  defp valid_object?(args, required, optional) when is_map(args) do
    valid_keys = Map.new(required ++ optional, fn {key, type} -> {Atom.to_string(key), type} end)

    Enum.all?(required, fn {key, _type} -> Map.has_key?(args, Atom.to_string(key)) end) and
      Enum.all?(args, fn {key, value} ->
        Map.has_key?(valid_keys, key) and valid_value?(Map.fetch!(valid_keys, key), value)
      end)
  end

  defp valid_object?(_args, _required, _optional), do: false

  defp valid_value?(:text, value), do: is_binary(value) and String.trim(value) != ""
  defp valid_value?(:boolean, value), do: is_boolean(value)
  defp valid_value?(:offset, value), do: is_integer(value) and value >= 0
  defp valid_value?(:limit, value), do: is_integer(value) and value in 1..100

  defp valid_value?(:email_addresses, value) do
    is_list(value) and value != [] and
      Enum.all?(value, &valid_object?(&1, [email: :text, is_primary: :boolean], []))
  end

  defp valid_value?(id_type, value), do: ID.valid?(id_type, value)
end
