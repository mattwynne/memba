defmodule Memba.Membership.GroupWelcomeEmail do
  @moduledoc """
  Composes and delivers the transactional welcome for a new custom-group member.

  Callers provide the already-resolved club, group, recipient, actor, and normal
  authenticated group URL. This module owns only provider-neutral email
  composition and the handoff to `Memba.Mailer`; deciding when a membership
  transition warrants delivery remains the admitting use case's responsibility.
  """

  import Swoosh.Email

  alias Memba.ClubInboundEmailAddress
  alias Memba.EmailTemplates
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Slug
  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

  @fallback_from {"Memba", "messages@mail.memba.io"}

  @doc """
  Build and deliver a custom-group welcome email.

  Required attributes are:

    * `:club` - a map or struct with `:name` and `:slug`
    * `:group` - a map or struct with `:name`; `:email_slug` enables reply-by-email
    * `:recipient` - a map or struct with `:name` and verified primary `:email`
    * `:added_by` - a map or struct with the admitting person's `:name`
    * `:group_url` - the ordinary authenticated group page URL

  Club, group, recipient, and actor IDs are optional provider metadata. Matching
  recipient and actor person IDs select the self-add wording.
  """
  def deliver(attrs) when is_map(attrs) do
    with {:ok, context} <- welcome_context(attrs),
         {:ok, recipient_email} <- recipient_email(context.recipient),
         {:ok, group_url} <- group_url(attrs) do
      context
      |> Map.put(:recipient_email, recipient_email)
      |> Map.put(:group_url, group_url)
      |> welcome_email()
      |> deliver_email()
    end
  rescue
    exception ->
      {:error,
       {:group_welcome_email_delivery_exception, exception.__struct__,
        Exception.message(exception)}}
  end

  def deliver(_attrs), do: {:error, :invalid_group_welcome_email_attrs}

  defp welcome_context(attrs) do
    club = option_value(attrs, [:club])
    group = option_value(attrs, [:group])
    recipient = option_value(attrs, [:recipient])
    added_by = option_value(attrs, [:added_by, :actor])

    with {:ok, club_name} <- required_header_text(club, [:name, :club_name], :invalid_club),
         {:ok, club_slug} <- required_slug(club, [:slug, :club_slug], :invalid_club),
         {:ok, group_name} <- required_header_text(group, [:name, :group_name], :invalid_group),
         {:ok, recipient_name} <-
           required_header_text(recipient, [:name, :recipient_name], :invalid_recipient),
         {:ok, actor_name} <-
           required_header_text(added_by, [:name, :actor_name], :invalid_added_by) do
      {:ok,
       %{
         club: %{
           id: metadata_value(club, [:club_id]),
           name: club_name,
           slug: club_slug
         },
         group: %{
           id: metadata_value(group, [:group_id]),
           email_slug: optional_slug(group, [:email_slug, :group_email_slug]),
           name: group_name
         },
         recipient: %{
           id: metadata_value(recipient, [:person_id, :recipient_person_id]),
           name: recipient_name,
           email: option_value(recipient, [:email, :primary_email, :recipient_email])
         },
         actor: %{
           id: metadata_value(added_by, [:person_id, :actor_person_id]),
           name: actor_name
         }
       }}
    end
  end

  defp required_header_text(source, keys, error) do
    source
    |> option_value(keys)
    |> EmailTemplates.sanitize_header_text()
    |> case do
      "" -> {:error, error}
      text -> {:ok, text}
    end
  end

  defp required_slug(source, keys, error) do
    source
    |> option_value(keys)
    |> Slug.normalize_for_lookup()
    |> case do
      {:ok, slug} -> {:ok, slug}
      {:error, _reason} -> {:error, error}
    end
  end

  defp optional_slug(source, keys) do
    case source |> option_value(keys) |> Slug.normalize_for_lookup() do
      {:ok, slug} -> slug
      {:error, _reason} -> nil
    end
  end

  defp metadata_value(source, keys) do
    source
    |> option_value(keys)
    |> EmailTemplates.sanitize_header_text()
  end

  defp recipient_email(recipient) do
    case EmailAddresses.normalize_email(recipient.email) do
      {:ok, %{normalized_email: normalized_email}} -> {:ok, normalized_email}
      {:error, :invalid_email} -> {:error, :invalid_email}
    end
  end

  defp group_url(attrs) do
    attrs
    |> option_value([:group_url, :url])
    |> case do
      url when is_binary(url) ->
        case String.trim(url) do
          "" -> {:error, :invalid_group_url}
          url -> {:ok, url}
        end

      _url ->
        {:error, :invalid_group_url}
    end
  end

  defp welcome_email(context) do
    new()
    |> from(from_address(context))
    |> to({context.recipient.name, context.recipient_email})
    |> maybe_reply_to(group_email_address(context))
    |> subject(subject(context))
    |> text_body(welcome_text_body(context))
    |> html_body(welcome_html_body(context))
    |> put_provider_options(context)
  end

  defp from_address(context) do
    from_address = configured_from_address() || @fallback_from
    sender_name = "#{context.club.name} via Memba"

    case from_address do
      {_name, address} -> {sender_name, address}
      address -> {sender_name, address}
    end
  end

  defp configured_from_address do
    case selected_provider() do
      Resend ->
        provider_from_address(Resend)

      Postmark ->
        provider_from_address(Postmark)

      Local ->
        provider_from_address(Postmark)

      _provider ->
        provider_from_address(Postmark) || provider_from_address(Resend)
    end
  end

  defp selected_provider do
    Application.get_env(:memba, :messaging_email_delivery_provider)
  end

  defp provider_from_address(provider) do
    :memba
    |> Application.get_env(provider, [])
    |> Keyword.get(:from)
    |> normalize_address()
  end

  defp normalize_address({_name, address} = named_address) when is_binary(address),
    do: named_address

  defp normalize_address(address) when is_binary(address) do
    case String.trim(address) do
      "" -> nil
      address -> address
    end
  end

  defp normalize_address(_address), do: nil

  defp group_email_address(context) do
    case ClubInboundEmailAddress.address(context.club.slug, context.group.email_slug) do
      nil -> nil
      address -> {context.group.name, address}
    end
  end

  defp maybe_reply_to(email, nil), do: email
  defp maybe_reply_to(email, address), do: reply_to(email, address)

  defp put_provider_options(email, context) do
    if selected_provider() == Resend do
      put_provider_option(email, :tags, provider_tags(context))
    else
      put_provider_option(email, :metadata, provider_metadata(context))
    end
  end

  defp provider_tags(context) do
    [
      %{name: "memba_email_kind", value: "group_welcome"},
      optional_tag("memba_club_id", context.club.id),
      optional_tag("memba_group_id", context.group.id),
      optional_tag("memba_recipient_id", context.recipient.id),
      optional_tag("memba_actor_id", context.actor.id)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp optional_tag(_name, ""), do: nil
  defp optional_tag(name, value), do: %{name: name, value: value}

  defp provider_metadata(context) do
    %{
      "memba_email_kind" => "group_welcome",
      "memba_club_id" => context.club.id,
      "memba_group_id" => context.group.id,
      "memba_recipient_id" => context.recipient.id,
      "memba_actor_id" => context.actor.id
    }
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Map.new()
  end

  defp welcome_text_body(context) do
    """
    Hi #{first_name(context.recipient.name)},

    #{addition_copy(context)}, a private group inside #{context.club.name}.

    You can read everything already in it, take part in its conversations on the website, and you'll get its emails from now on.

    Earlier #{context.group.name} emails aren't resent — the full history is on the website.

    Open #{context.group.name}:

    #{context.group_url}
    """ <> group_email_text(context)
  end

  defp group_email_text(context) do
    case group_email_address(context) do
      nil ->
        ""

      {_name, address} ->
        """

        To start a #{context.group.name} conversation by email, write to #{address}. Only #{context.group.name} members will see it.
        """
    end
  end

  defp welcome_html_body(context) do
    content = [
      EmailTemplates.group_header(context.group.name,
        label: context.club.name,
        border_bottom: true
      ),
      EmailTemplates.card_section(
        [
          EmailTemplates.paragraph("You've been added to a group",
            margin: "0 0 5px",
            color: "#7d877f",
            font_size: "12px"
          ),
          EmailTemplates.heading(addition_copy(context), margin: "0 0 18px"),
          EmailTemplates.paragraph("Hi #{first_name(context.recipient.name)},"),
          EmailTemplates.paragraph(
            "#{context.group.name} is a private group inside #{context.club.name}. " <>
              "As a member you can read everything already in it, take part in its " <>
              "conversations on the website, and you'll get its emails from now on."
          ),
          EmailTemplates.paragraph(
            "Earlier #{context.group.name} emails aren't resent — the full history is on the website.",
            margin: "0 0 20px"
          ),
          EmailTemplates.primary_action("Open #{context.group.name}", context.group_url,
            width: "180px"
          ),
          group_email_html(context)
        ],
        padding: "18px 28px 22px"
      )
    ]

    EmailTemplates.render_shell(
      title: subject(context),
      preheader: "#{addition_copy(context)}, a private group in #{context.club.name}.",
      content: content,
      footer:
        EmailTemplates.memba_footer(
          group_name: context.club.name,
          recipient_email: context.recipient_email,
          reason: delivery_reason(context)
        )
    )
  end

  defp group_email_html(context) do
    case group_email_address(context) do
      nil ->
        ""

      {_name, address} ->
        escaped_group_name = EmailTemplates.escaped_text(context.group.name)
        escaped_address = EmailTemplates.escaped_text(address)

        """
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"><tr>
          <td style="background:#ecf2ee; border:1px solid #d2e0d7; border-radius:10px; padding:12px 14px; font-size:13.5px; line-height:1.55; color:#173a35;">
            To start a #{escaped_group_name} conversation by email, write to <a href="mailto:#{escaped_address}" style="color:#173a35; font-weight:600; text-decoration:none;">#{escaped_address}</a>. Only #{escaped_group_name} members will see it.
          </td>
        </tr></table>
        """
    end
  end

  defp addition_copy(context) do
    if self_add?(context) do
      "You added yourself to #{context.group.name}"
    else
      "#{context.actor.name} added you to #{context.group.name}"
    end
  end

  defp delivery_reason(context) do
    if self_add?(context) do
      "You added yourself to #{context.group.name}."
    else
      "#{context.actor.name} added you to #{context.group.name}."
    end
  end

  defp self_add?(context) do
    context.recipient.id != "" and context.recipient.id == context.actor.id
  end

  defp subject(context), do: "[#{context.club.slug}] You've been added to #{context.group.name}"

  defp first_name(name) do
    name
    |> String.split(~r/\s+/u, parts: 2, trim: true)
    |> List.first(name)
  end

  defp option_value(opts, keys) when is_list(opts) do
    if Keyword.keyword?(opts) do
      Enum.find_value(keys, &Keyword.get(opts, &1))
    end
  end

  defp option_value(%{} = opts, keys) do
    Enum.find_value(keys, fn key ->
      Map.get(opts, key) || Map.get(opts, Atom.to_string(key))
    end)
  end

  defp option_value(_opts, _keys), do: nil

  defp deliver_email(email) do
    email
    |> Memba.Mailer.deliver()
    |> normalize_delivery_result()
  end

  defp normalize_delivery_result({:ok, _result}), do: :ok

  defp normalize_delivery_result({:error, reason}),
    do: {:error, {:group_welcome_email_delivery_error, reason}}

  defp normalize_delivery_result(result) do
    {:error, {:group_welcome_email_delivery_error, {:unexpected_delivery_result, result}}}
  end
end
