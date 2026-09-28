defmodule Memba.Messaging.MemberMessageEmailTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.MemberMessageEmail
  alias Memba.Messaging.OutboundMessageID
  alias Memba.Membership.SystemGroups
  alias MembaWeb.ClubSite

  test "Admin root messages use the club as the From identity" do
    club_id = Memba.ID.generate(:club)

    request =
      email_delivery_request(
        club_id: club_id,
        club_name: "Kootenay Mountaineering Club",
        audience_group_id: SystemGroups.admin_group_id(club_id),
        sender_name: "Alice Adams"
      )

    assert MemberMessageEmail.from_display_name(request) ==
             "Kootenay Mountaineering Club via Memba"
  end

  test "Admin root messages identify the private audience throughout the email copy" do
    club_id = Memba.ID.generate(:club)

    request =
      email_delivery_request(
        club_id: club_id,
        club_name: "Kootenay Mountaineering Club",
        club_slug: "kmc",
        audience_group_id: SystemGroups.admin_group_id(club_id),
        audience_group_name: "Admin",
        sender_name: "Alice Adams"
      )

    html = MemberMessageEmail.html_body(request)

    assert html =~ "to the Admin group at Kootenay Mountaineering Club"
    assert html =~ "Reply to this email to post back to"
    assert html =~ "active member of the Admin group at Kootenay Mountaineering Club"
    refute html =~ "to all members"
  end

  test "root HTML promotes a typed targeted-add URL for the current club without a magic subject" do
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    add_url = ClubSite.url("kmc", "/groups/#{group_id}/members/add/#{person_id}")

    body = """
    Eve <Admin> would like to join Board & Friends.

    Add Eve <Admin> to Board & Friends:
    #{add_url}

    You'll confirm on the website before Eve is added.
    """

    request =
      email_delivery_request(
        club_slug: "kmc",
        subject: "An ordinary member message",
        body: body
      )

    html = MemberMessageEmail.html_body(request)

    assert html =~ ~s(class="btn")
    assert html =~ "Add Eve &lt;Admin&gt; to Board &amp; Friends"
    assert html =~ ~s(href="#{add_url}")
    assert html =~ add_url
    refute html =~ "Eve <Admin>"
    assert MemberMessageEmail.text_body(request) == body
  end

  test "unsafe or malformed targeted-add candidates remain escaped non-action text" do
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    other_group_id = Memba.ID.generate(:group)
    path = "/groups/#{group_id}/members/add/#{person_id}"
    current_club_url = ClubSite.url("kmc", path)
    current_uri = URI.parse(current_club_url)

    unsafe_urls = [
      ClubSite.url("neighbour", path),
      "#{current_uri.scheme}://#{current_uri.host}.attacker.test:#{current_uri.port}#{path}",
      "https://example.test#{path}",
      ClubSite.root_url(path),
      String.replace_prefix(current_club_url, "http://", "https://"),
      "#{current_uri.scheme}://#{current_uri.host}:#{current_uri.port + 1}#{path}",
      path,
      "#{current_club_url}?confirm=true",
      "#{current_club_url}#confirm",
      "#{current_uri.scheme}://member@#{current_uri.host}:#{current_uri.port}#{path}",
      ClubSite.url("kmc", "/groups/#{group_id}/members/#{person_id}"),
      ClubSite.url("kmc", "#{path}/extra"),
      ClubSite.url("kmc", "/groups/#{person_id}/members/add/#{group_id}"),
      ClubSite.url("kmc", "/groups/#{other_group_id}/members/add/not-a-person-id"),
      String.replace(current_club_url, "grp_", "grp%5F")
    ]

    Enum.each(unsafe_urls, fn unsafe_url ->
      body = """
      <script>alert("outside")</script>

      Add Eve <Admin> to Board & Friends:
      #{unsafe_url}
      """

      html =
        email_delivery_request(
          club_slug: "kmc",
          subject: "Access request: Board",
          body: body
        )
        |> MemberMessageEmail.html_body()

      refute html =~ ~s(class="btn")
      refute html =~ ~s(href="#{unsafe_url}")
      assert html =~ "&lt;script&gt;alert(&quot;outside&quot;)&lt;/script&gt;"
      assert html =~ "Add Eve &lt;Admin&gt; to Board &amp; Friends:"
      refute html =~ ~s(<script>)
      refute html =~ "Eve <Admin>"
    end)
  end

  test "subject-only spoofing and reply bodies cannot create a targeted-add action" do
    group_id = Memba.ID.generate(:group)
    person_id = Memba.ID.generate(:person)
    add_url = ClubSite.url("kmc", "/groups/#{group_id}/members/add/#{person_id}")

    subject_only_html =
      email_delivery_request(
        club_slug: "kmc",
        subject: "Access request: Board",
        body: "Please add Eve to Board."
      )
      |> MemberMessageEmail.html_body()

    reply_html =
      email_delivery_request(
        club_slug: "kmc",
        subject: "Access request: Board",
        reply_to_message_id: Memba.ID.generate(:message),
        body: "Add Eve to Board:\n#{add_url}"
      )
      |> MemberMessageEmail.html_body()

    refute subject_only_html =~ ~s(class="btn")
    refute reply_html =~ ~s(class="btn")
    refute reply_html =~ ~s(href="#{add_url}")
    assert reply_html =~ add_url
  end

  test "multiple valid targeted-add candidates are not promoted" do
    first_url =
      ClubSite.url(
        "kmc",
        "/groups/#{Memba.ID.generate(:group)}/members/add/#{Memba.ID.generate(:person)}"
      )

    second_url =
      ClubSite.url(
        "kmc",
        "/groups/#{Memba.ID.generate(:group)}/members/add/#{Memba.ID.generate(:person)}"
      )

    html =
      email_delivery_request(
        club_slug: "kmc",
        body: """
        Add Eve to Board:
        #{first_url}

        Add Eve to Trips:
        #{second_url}
        """
      )
      |> MemberMessageEmail.html_body()

    refute html =~ ~s(class="btn")
    refute html =~ ~s(href="#{first_url}")
    refute html =~ ~s(href="#{second_url}")
    assert html =~ first_url
    assert html =~ second_url
  end

  test "Everyone root messages keep the member sender as the From identity" do
    club_id = Memba.ID.generate(:club)

    request =
      email_delivery_request(
        club_id: club_id,
        club_name: "Kootenay Mountaineering Club",
        audience_group_id: SystemGroups.everyone_group_id(club_id),
        sender_name: "Alice Adams"
      )

    assert MemberMessageEmail.from_display_name(request) == "Alice Adams via Memba"
  end

  test "reply notifications use the club email subdomain destination and preserve threading headers" do
    request =
      email_delivery_request(
        club_name: "Kootenay Mountaineering Club",
        club_slug: "kmc",
        conversation_id: Memba.ID.generate(:message),
        reply_to_message_id: Memba.ID.generate(:message),
        in_reply_to_outbound_message_id: "<memba.parent@example.test>",
        references_outbound_message_ids: [
          "<memba.root@example.test>",
          "<memba.parent@example.test>"
        ]
      )

    assert MemberMessageEmail.reply_to(request) ==
             {"Kootenay Mountaineering Club", "everyone@kmc.clubs.memba.io"}

    refute MemberMessageEmail.reply_to(request) ==
             {"Kootenay Mountaineering Club", "kmc@clubs.memba.io"}

    assert MemberMessageEmail.message_id(request) == request.outbound_message_id

    assert MemberMessageEmail.threading_headers(request) == [
             {"In-Reply-To", "<memba.parent@example.test>"},
             {"References", "<memba.root@example.test> <memba.parent@example.test>"}
           ]
  end

  defp email_delivery_request(overrides) do
    message_id = Keyword.get_lazy(overrides, :message_id, fn -> Memba.ID.generate(:message) end)

    delivery_id =
      Keyword.get_lazy(overrides, :delivery_id, fn -> Memba.ID.generate(:delivery) end)

    %EmailDeliveryRequest{
      message_id: message_id,
      club_id: Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end),
      delivery_id: delivery_id,
      outbound_message_id:
        Keyword.get(
          overrides,
          :outbound_message_id,
          OutboundMessageID.for_delivery(delivery_id, message_id)
        ),
      recipient_id:
        Keyword.get_lazy(overrides, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice Adams"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.com"),
      audience_group_id: Keyword.get(overrides, :audience_group_id),
      audience_group_name: Keyword.get(overrides, :audience_group_name),
      club_name: Keyword.get(overrides, :club_name, "Kootenay Mountaineering Club"),
      club_slug: Keyword.get(overrides, :club_slug),
      sender_name: Keyword.get(overrides, :sender_name, "Bob Barker"),
      sender_address: Keyword.get(overrides, :sender_address, "bob@example.com"),
      conversation_id: Keyword.get(overrides, :conversation_id),
      reply_to_message_id: Keyword.get(overrides, :reply_to_message_id),
      in_reply_to_outbound_message_id: Keyword.get(overrides, :in_reply_to_outbound_message_id),
      references_outbound_message_ids: Keyword.get(overrides, :references_outbound_message_ids),
      conversation_url: Keyword.get(overrides, :conversation_url),
      stop_follow_url: Keyword.get(overrides, :stop_follow_url),
      reply_to_sender_name: Keyword.get(overrides, :reply_to_sender_name),
      reply_to_body: Keyword.get(overrides, :reply_to_body),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end
end
