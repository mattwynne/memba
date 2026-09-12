defmodule MembaWeb.MemberComponentsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.MemberComponents

  describe "member_list/1" do
    test "renders a single current member row with roles and no first-member banner" do
      member_id = Memba.ID.generate(:person)

      html =
        render_member_list(
          rows: [
            %{
              id: member_id,
              name: "Alice Adams",
              initials: "AA",
              roles: ["Chair", "Treasurer"]
            }
          ],
          active_member_count: 1,
          current_member: %{id: member_id, name: "Alice Adams"}
        )

      assert_selector(
        html,
        "#active-members-list[data-active-member-count='1'][data-active-members-state='first-member']"
      )

      assert_selector(
        html,
        "#club-member-#{member_id}[data-testid='club-member-row']" <>
          "[data-member-id='#{member_id}'][data-current-member='true']"
      )

      assert_text(html, "#club-member-#{member_id} .member-row__name", "Alice Adams")
      assert_text(html, "#club-member-#{member_id} .member-row__avatar", "AA")

      assert_text(
        html,
        "#club-member-#{member_id} [data-testid='club-member-current-indicator']",
        "You"
      )

      assert_text(html, "#club-member-#{member_id} .member-row__role", "Chair")
      assert_text(html, "#club-member-#{member_id} .member-row__role", "Treasurer")
      refute_selector(html, "#active-members-empty-state")
    end

    test "renders ordinary member rows without current markers" do
      alice_id = Memba.ID.generate(:person)
      bob_id = Memba.ID.generate(:person)

      html =
        render_member_list(
          rows: [
            %{id: alice_id, name: "Alice Adams", initials: "AA", roles: []},
            %{id: bob_id, name: "Bob Builder", initials: "BB", roles: []}
          ],
          active_member_count: 2,
          current_member: %{id: Memba.ID.generate(:person), name: "Carol Canoe"}
        )

      assert_selector(
        html,
        "#active-members-list[data-active-member-count='2'][data-active-members-state='active-members']"
      )

      assert_text(html, "#club-member-#{alice_id} .member-row__name", "Alice Adams")
      assert_text(html, "#club-member-#{bob_id} .member-row__name", "Bob Builder")
      assert_selector(html, "#club-member-#{alice_id}[data-current-member='false']")
      assert_selector(html, "#club-member-#{bob_id}[data-current-member='false']")

      refute_selector(
        html,
        "#club-member-#{alice_id} [data-testid='club-member-current-indicator']"
      )

      refute_selector(
        html,
        "#club-member-#{bob_id} [data-testid='club-member-current-indicator']"
      )

      refute_selector(html, "#active-members-empty-state")
    end
  end

  describe "conversation_row/1" do
    test "renders the row link, subject, and sender information" do
      message_id = Memba.ID.generate(:message)
      originator_id = Memba.ID.generate(:person)

      html =
        render_component(&MemberComponents.conversation_row/1, %{
          row:
            conversation_row(%{
              message_id: message_id,
              href: "/messages/#{message_id}?group_id=group-123",
              originator_id: originator_id,
              originator_name: "Bob Builder",
              originator_initials: "BB",
              subject: "Weekend conditions"
            })
        })

      assert_selector(
        html,
        "#member-message-#{message_id}[data-testid='club-message-row']" <>
          "[data-message-id='#{message_id}'][data-message-subject='Weekend conditions']"
      )

      assert_selector(
        html,
        "#member-message-#{message_id} [data-testid='club-message-link']" <>
          "[href='/messages/#{message_id}?group_id=group-123']"
      )

      assert_text(
        html,
        "#member-message-#{message_id} .conversation__subject",
        "Weekend conditions"
      )

      assert_text(
        html,
        "#member-message-#{message_id} [data-testid='message-originator-initials']",
        "BB"
      )

      assert_selector(
        html,
        "#member-message-#{message_id} [data-testid='message-started-by']" <>
          "[data-originator-id='#{originator_id}'][data-originator-name='Bob Builder']"
      )

      assert_text(
        html,
        "#member-message-#{message_id} [data-testid='message-started-by']",
        "Started by Bob Builder"
      )
    end
  end

  describe "participant_avatar_stack/1" do
    test "renders participants in order with overflow and suppresses an empty stack" do
      participants = [
        %{id: Memba.ID.generate(:person), name: "Carol Canoe", initials: "CC"},
        %{id: Memba.ID.generate(:person), name: "Dana Downhill", initials: "DD"},
        %{id: Memba.ID.generate(:person), name: "Elliot Explorer", initials: "EE"}
      ]

      html =
        render_component(&MemberComponents.participant_avatar_stack/1, %{
          participants: participants,
          additional_count: 2
        })

      assert_selector(
        html,
        "[data-testid='message-participant-avatar-stack'][aria-label='Conversation participants']"
      )

      assert participant_names(html) == ["Carol Canoe", "Dana Downhill", "Elliot Explorer"]

      assert_text(
        html,
        "[data-testid='message-participant-overflow'][aria-label='2 more participants']",
        "+2"
      )

      empty_html =
        render_component(&MemberComponents.participant_avatar_stack/1, %{
          participants: [],
          additional_count: 0
        })

      refute_selector(empty_html, "[data-testid='message-participant-avatar-stack']")
    end
  end

  describe "conversation_list/1" do
    test "renders the empty conversation state with caller-supplied action slot" do
      assigns = %{rows: []}

      html =
        rendered_to_string(~H"""
        <MemberComponents.conversation_list rows={@rows}>
          <:empty_action>
            <a id="empty-send-link" href="/messages/new?group_id=group-123">
              Send the first message
            </a>
          </:empty_action>
        </MemberComponents.conversation_list>
        """)

      assert_selector(html, "#member-message-list")
      assert_text(html, "#member-message-list-empty", "No club messages yet")

      assert_text(
        html,
        "#member-message-list-empty",
        "When a member sends a message, it will appear here."
      )

      assert_selector(html, "#empty-send-link[href='/messages/new?group_id=group-123']")
      refute_selector(html, "[data-testid='club-message-row']")
    end
  end

  defp render_member_list(assigns) do
    assigns = Map.new(assigns)

    render_component(&MemberComponents.member_list/1, assigns)
  end

  defp conversation_row(overrides) do
    Map.merge(
      %{
        message_id: Memba.ID.generate(:message),
        href: "/messages/message-123",
        originator_id: Memba.ID.generate(:person),
        originator_name: "Club member",
        originator_initials: "CM",
        subject: "Club update",
        body: "Trail is clear to the lake.",
        sent_at_label: "Jun 03, 2026",
        reply_count: 0,
        latest_replier_id: nil,
        latest_replier_name: nil,
        reply_activity_label: "No replies yet",
        participants: [],
        additional_participant_count: 0
      },
      overrides
    )
  end

  defp participant_names(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[data-testid='message-participant-avatar']")
    |> LazyHTML.attribute("data-participant-name")
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component not to include selector #{inspect(selector)}"
  end

  defp assert_text(html, selector, text) do
    assert html
           |> LazyHTML.from_fragment()
           |> LazyHTML.query(selector)
           |> LazyHTML.text()
           |> String.contains?(text),
           "Expected rendered component selector #{inspect(selector)} to include text #{inspect(text)}"
  end
end
