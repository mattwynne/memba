defmodule MembaWeb.MemberComponentsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MembaWeb.MemberComponents

  describe "member_list/1" do
    test "renders the designed empty custom-group state for zero members" do
      html =
        render_member_list(
          rows: [],
          active_member_count: 0,
          current_member: %{id: Memba.ID.generate(:person), name: "Dana Diaz"},
          group_name: "Board"
        )

      assert_selector(
        html,
        "#active-members-list[data-active-member-count='0'][data-active-members-state='empty']"
      )

      assert_text(html, "#active-members-empty-state", "Board has no members.")

      assert_text(
        html,
        "#active-members-empty-state",
        "Its conversations and emails are kept; whoever you add next will see them all."
      )

      refute_selector(html, "[data-testid='club-member-row']")
    end

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

  describe "custom_group_membership_guidance/1" do
    test "explains a group member's admission authority without implying club authority" do
      html =
        render_component(&MemberComponents.custom_group_membership_guidance/1, %{
          club_name: "Alpine Club",
          group_name: "Board",
          viewer_access: :participating_member
        })

      assert_selector(
        html,
        "#member-group-membership-guidance.members-note" <>
          "[data-viewer-access='participating_member']"
      )

      assert_text(html, "#member-group-membership-guidance", "Board members can read every")

      assert_text(
        html,
        "#member-group-membership-guidance",
        "Anyone in Board can add other"
      )

      assert_text(html, "#member-group-membership-guidance strong", "Alpine Club")

      assert_text(
        html,
        "#member-group-membership-guidance",
        "that never changes their club membership"
      )
    end

    test "explains an outside admin's admission authority without implying group access" do
      html =
        render_component(&MemberComponents.custom_group_membership_guidance/1, %{
          club_name: "Alpine Club",
          group_name: "Board",
          viewer_access: :outside_admin
        })

      assert_selector(
        html,
        "#member-group-membership-guidance.members-note[data-viewer-access='outside_admin']"
      )

      assert_text(
        html,
        "#member-group-membership-guidance",
        "As a club admin you can too"
      )

      assert_text(html, "#member-group-membership-guidance strong", "Alpine Club")

      assert_text(
        html,
        "#member-group-membership-guidance",
        "that never changes anyone's club membership"
      )
    end
  end

  describe "custom_group_member_picker/1" do
    test "renders searchable active-club candidates with stable admission identities" do
      dana_membership_id = Memba.ID.generate(:membership)
      dana_person_id = Memba.ID.generate(:person)

      html =
        render_component(&MemberComponents.custom_group_member_picker/1, %{
          club_name: "Alpine Club",
          group_name: "Board",
          candidates: [
            %{
              membership_id: dana_membership_id,
              id: dana_person_id,
              name: "Dana Diaz",
              initials: "DD",
              roles: ["Admin"]
            }
          ],
          query: "dan",
          search_form: to_form(%{"query" => "dan"}, as: :member_search)
        })

      assert_selector(
        html,
        "#custom-group-member-picker.picker[aria-labelledby='custom-group-member-picker-title']"
      )

      assert_text(html, "#custom-group-member-picker-title", "Add to Board")

      assert_selector(
        html,
        "#custom-group-member-search-form[phx-change='filter_custom_group_member_candidates'] " <>
          "#custom-group-member-search[type='search'][name='member_search[query]'][value='dan']"
      )

      refute_selector(html, "#custom-group-member-search[phx-keyup]")

      assert_selector(
        html,
        "#custom-group-member-picker[phx-window-keydown][phx-key='Escape']"
      )

      assert_selector(
        html,
        "#custom-group-member-candidate-#{dana_person_id}[role='listitem']" <>
          "[data-membership-id='#{dana_membership_id}'][data-person-id='#{dana_person_id}']"
      )

      assert_text(
        html,
        "#custom-group-member-candidate-#{dana_person_id} .pick-row__name",
        "Dana Diaz"
      )

      assert_text(
        html,
        "#custom-group-member-candidate-#{dana_person_id} .pick-row__meta",
        "Club admin"
      )

      assert_selector(
        html,
        "#custom-group-member-candidate-add-#{dana_person_id}" <>
          ".btn-outline.btn-primary[data-custom-group-member-action='add']"
      )

      assert_selector(
        html,
        "#custom-group-member-picker-close[phx-click]"
      )
    end

    test "explains when no eligible club members remain" do
      html =
        render_component(&MemberComponents.custom_group_member_picker/1, %{
          club_name: "Alpine Club",
          group_name: "Board",
          candidates: [],
          query: "",
          search_form: to_form(%{"query" => ""}, as: :member_search)
        })

      assert_text(
        html,
        "#custom-group-member-picker-empty",
        "Everyone in Alpine Club is already in Board."
      )

      refute_selector(html, "[data-testid='custom-group-member-candidate']")
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
    assigns =
      assigns
      |> Map.new()
      |> Map.put_new(:group_name, "Board")

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
