defmodule MembaWeb.CoreComponentsTest do
  use MembaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MembaWeb.CoreComponents

  describe "avatar/1" do
    test "renders the initials text" do
      html = render_avatar(initials: "MW")

      assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "MW"
      assert_class(html, "div.avatar", "avatar")
      assert_class(html, "div.avatar", "avatar-placeholder")
    end

    test "maps each size to its width class" do
      for {size, expected_class} <- [sm: "w-7", md: "w-9", lg: "w-12"] do
        html = render_avatar(initials: "MW", size: size)

        assert_class(html, "div.avatar > div", expected_class)
      end
    end

    test "picks a deterministic sage background from the cycle" do
      first_html = render_avatar(initials: "MW")
      second_html = render_avatar(initials: "MW")

      [first_bg] = avatar_bg_classes(first_html)
      [second_bg] = avatar_bg_classes(second_html)

      assert first_bg == second_bg
      assert first_bg in ~w(bg-sage-200 bg-sage-300 bg-sage-100 bg-sage-400 bg-sage-50)
    end

    test "forwards member-page attributes while keeping shared avatar classes" do
      html =
        render_avatar(
          id: "member-avatar",
          "data-testid": "club-member-row",
          title: "Alice Adams",
          initials: "AA",
          class: "shadow-sm"
        )

      assert_selector(
        html,
        "div#member-avatar.avatar.avatar-placeholder.shadow-sm[data-testid='club-member-row'][title='Alice Adams']"
      )
    end
  end

  describe "status_badge/1" do
    test "renders each semantic tone class" do
      for {tone, expected_class} <- [
            {"success", "badge-success"},
            {"info", "badge-info"},
            {"warning", "badge-warning"},
            {"error", "badge-error"}
          ] do
        html = render_status_badge(tone: tone, label: "Ready")

        assert_class(html, "span.badge", "badge")
        assert_class(html, "span.badge", "badge-soft")
        assert_class(html, "span.badge", expected_class)
      end
    end

    test "renders neutral without a colored badge class" do
      html = render_status_badge(tone: "neutral", label: "Ready")

      assert_class(html, "span.badge", "badge")
      assert_class(html, "span.badge", "badge-soft")
      refute_class(html, "span.badge", "badge-success")
      refute_class(html, "span.badge", "badge-info")
      refute_class(html, "span.badge", "badge-warning")
      refute_class(html, "span.badge", "badge-error")
    end

    test "renders the label text" do
      html = render_status_badge(label: "Active")

      assert html |> LazyHTML.from_fragment() |> LazyHTML.text() =~ "Active"
    end

    test "renders the leading dot" do
      html = render_status_badge(label: "Active")

      assert_selector(html, "span.badge span.rounded-full.bg-current")
      assert_class(html, "span.badge span.rounded-full.bg-current", "size-1.5")
    end

    test "forwards member receipt status attributes while keeping tone classes" do
      html =
        render_status_badge(
          tone: "warning",
          label: "Sending",
          "data-testid": "receipt-status",
          "data-receipt-status": "sent",
          "aria-label": "Delivery status for Alice Adams: Sending"
        )

      assert_selector(
        html,
        "span.badge.badge-soft.badge-warning[data-testid='receipt-status'][data-receipt-status='sent'][aria-label='Delivery status for Alice Adams: Sending']"
      )
    end
  end

  describe "button/1" do
    test "renders each variant class" do
      for {variant, expected_class} <- [
            {"primary", "btn-primary"},
            {"secondary", "btn-soft"},
            {"ghost", "btn-ghost"},
            {"danger", "btn-error"}
          ] do
        html = render_button(variant: variant)

        assert_class(html, "button", "btn")
        assert_class(html, "button", expected_class)
      end
    end

    test "renders each size class" do
      for {size, expected_class} <- [{"sm", "btn-sm"}, {"lg", "btn-lg"}] do
        html = render_button(size: size)

        assert_class(html, "button", "btn")
        assert_class(html, "button", expected_class)
      end
    end

    test "renders no size class by default" do
      html = render_button()

      refute_class(html, "button", "btn-sm")
      refute_class(html, "button", "btn-lg")
    end

    test "keeps variant and size classes when callers add layout classes" do
      html = render_button(variant: "ghost", size: "lg", class: "w-full justify-start")

      assert_class(html, "button", "btn")
      assert_class(html, "button", "btn-ghost")
      assert_class(html, "button", "btn-lg")
      assert_class(html, "button", "w-full")
      assert_class(html, "button", "justify-start")
    end

    test "renders disabled attribute" do
      html = render_button(disabled: true)

      assert_selector(html, "button[disabled]")
    end

    test "renders a button without navigation attributes" do
      html = render_button(rest: %{type: "submit", form: "external-form"})

      assert_selector(html, "button[type='submit'][form='external-form']")
      refute_selector(html, "a")
    end

    test "renders a link with href" do
      html = render_button(rest: %{href: "/clubs"})

      assert_selector(html, "a[href='/clubs']")
      refute_selector(html, "button")
    end

    test "renders a link with navigate" do
      html = render_button(rest: %{navigate: "/clubs"})

      assert_selector(
        html,
        "a[href='/clubs'][data-phx-link='redirect'][data-phx-link-state='push']"
      )

      refute_selector(html, "button")
    end

    test "renders a link with patch" do
      html = render_button(rest: %{patch: "/clubs?page=2"})

      assert_selector(
        html,
        "a[href='/clubs?page=2'][data-phx-link='patch'][data-phx-link-state='push']"
      )

      refute_selector(html, "button")
    end

    test "preserves enabled link attributes used for non-navigation link actions" do
      html = render_button(rest: %{href: "/exports/members.csv", download: "members.csv"})

      assert_selector(html, "a[href='/exports/members.csv'][download='members.csv']")
      refute_selector(html, "button")
    end

    test "renders disabled link-styled actions as non-interactive text" do
      html =
        render_button(
          disabled: true,
          rest: %{
            id: "disabled-export",
            href: "/exports/members.csv",
            method: "delete",
            download: "members.csv",
            "data-testid": "export-action",
            "aria-label": "Export members",
            "phx-click": "export"
          }
        )

      assert_selector(
        html,
        "span#disabled-export.btn[aria-disabled='true'][data-testid='export-action'][aria-label='Export members']"
      )

      refute_selector(html, "a")
      refute_selector(html, "button")
      refute_selector(html, "[href]")
      refute_selector(html, "[method]")
      refute_selector(html, "[download]")
      refute_selector(html, "[phx-click]")
    end
  end

  describe "input/1" do
    test "connects visible text input errors to the control without dropping caller help" do
      html =
        render_input(
          id: "email-input",
          name: "user[email]",
          type: "email",
          label: "Email",
          errors: ["Enter a valid email address."],
          rest: %{"aria-describedby" => "email-help"}
        )

      assert_selector(
        html,
        "input#email-input[aria-invalid='true'][aria-describedby='email-help email-input-error-1'].input-error"
      )

      assert_text(html, "p#email-input-error-1", "Enter a valid email address.")
    end

    test "removes automatic invalid state when an input has recovered" do
      html =
        render_input(
          id: "email-input",
          name: "user[email]",
          type: "email",
          label: "Email",
          errors: [],
          rest: %{"aria-describedby" => "email-help"}
        )

      assert_selector(html, "input#email-input[aria-describedby='email-help']")
      refute_selector(html, "input#email-input[aria-invalid]")
      refute_selector(html, "#email-input-error-1")
    end

    test "preserves caller-managed invalid state when no component errors are present" do
      html =
        render_input(
          id: "slug-input",
          name: "club[slug]",
          label: "Slug",
          errors: [],
          rest: %{"aria-invalid" => "true", "aria-describedby" => "slug-help slug-feedback"}
        )

      assert_selector(
        html,
        "input#slug-input[aria-invalid='true'][aria-describedby='slug-help slug-feedback']"
      )
    end

    test "uses form field errors only after LiveView reports the field was used" do
      unused_form =
        Phoenix.Component.to_form(
          %{"email" => "not-an-email", "_unused_email" => ""},
          as: :user,
          errors: [email: {"is invalid", []}]
        )

      used_form =
        Phoenix.Component.to_form(%{"email" => "not-an-email"},
          as: :user,
          errors: [email: {"is invalid", []}]
        )

      unused_html = render_input(field: unused_form[:email], id: "unused-email", type: "email")
      used_html = render_input(field: used_form[:email], id: "used-email", type: "email")

      refute_selector(unused_html, "#unused-email-error-1")
      refute_selector(unused_html, "#unused-email[aria-invalid]")
      assert_selector(used_html, "#used-email[aria-invalid='true']")
      assert_text(used_html, "#used-email-error-1", "is invalid")
    end

    test "connects visible textarea, select, and checkbox errors to their controls" do
      textarea_html =
        render_input(
          id: "bio-input",
          name: "profile[bio]",
          type: "textarea",
          label: "Bio",
          errors: ["Tell us more."],
          rest: %{rows: "4"}
        )

      assert_selector(
        textarea_html,
        "textarea#bio-input[aria-invalid='true'][aria-describedby='bio-input-error-1'].textarea-error"
      )

      assert_text(textarea_html, "#bio-input-error-1", "Tell us more.")

      select_html =
        render_input(
          id: "role-input",
          name: "profile[role]",
          type: "select",
          label: "Role",
          options: [{"Admin", "admin"}, {"Member", "member"}],
          errors: ["Choose a role."],
          prompt: "Choose one"
        )

      assert_selector(
        select_html,
        "select#role-input[aria-invalid='true'][aria-describedby='role-input-error-1'].select-error"
      )

      assert_text(select_html, "#role-input-error-1", "Choose a role.")

      checkbox_html =
        render_input(
          id: "terms-input",
          name: "profile[terms]",
          type: "checkbox",
          label: "Accept terms",
          errors: ["Accept the terms."],
          checked: false
        )

      assert_selector(
        checkbox_html,
        "input#terms-input[type='checkbox'][aria-invalid='true'][aria-describedby='terms-input-error-1'].checkbox"
      )

      assert_text(checkbox_html, "#terms-input-error-1", "Accept the terms.")
      assert_selector(checkbox_html, "input[type='hidden'][name='profile[terms]'][value='false']")
      refute_selector(checkbox_html, "input[type='hidden'][aria-invalid]")
    end

    test "escapes error messages instead of injecting raw HTML" do
      html =
        render_input(
          id: "safe-input",
          name: "safe[input]",
          errors: ["<script>alert('x')</script>"]
        )

      assert html =~ "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;"
      refute html =~ "<script>"
    end
  end

  describe "context_kebab_menu/1" do
    test "uses native disclosure semantics with ordinary actions" do
      html = render_context_kebab_menu()

      assert_selector(
        html,
        "details#message-menu.context-menu.dropdown.dropdown-end > " <>
          "summary#message-menu-button.context-menu__button" <>
          "[aria-controls='message-menu-content'][aria-label='Message options']"
      )

      assert_selector(
        html,
        "details#message-menu > div#message-menu-content.dropdown-content.context-menu__content"
      )

      assert_selector(html, "a#delivery-link[href='/messages/msg_123/delivery']")
      refute_selector(html, "[role='menu']")
      refute_selector(html, "[role='menuitem']")
      refute_selector(html, "[aria-haspopup]")
      refute_selector(html, "summary[tabindex]")
    end
  end

  defp render_status_badge(assigns) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put_new(:label, "Ready")

    render_component(&CoreComponents.status_badge/1, assigns)
  end

  defp render_avatar(assigns) do
    render_component(&CoreComponents.avatar/1, Map.new(assigns))
  end

  defp render_button(assigns \\ []) do
    assigns =
      assigns
      |> Map.new()
      |> Map.put(:inner_block, [%{inner_block: fn _, _ -> "Save" end}])

    render_component(&CoreComponents.button/1, assigns)
  end

  defp render_input(assigns) do
    render_component(&CoreComponents.input/1, Map.new(assigns))
  end

  defp render_context_kebab_menu do
    render_component(&CoreComponents.context_kebab_menu/1, %{
      id: "message-menu",
      button_id: "message-menu-button",
      content_id: "message-menu-content",
      label: "Message options",
      inner_block: [
        %{
          inner_block: fn _, _ ->
            Phoenix.HTML.raw(
              ~s(<a id="delivery-link" href="/messages/msg_123/delivery">Delivery details</a>)
            )
          end
        }
      ]
    })
  end

  defp assert_selector(html, selector) do
    assert html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component to include selector #{inspect(selector)}"
  end

  defp refute_selector(html, selector) do
    refute html |> LazyHTML.from_fragment() |> LazyHTML.query(selector) |> Enum.any?(),
           "Expected rendered component not to include selector #{inspect(selector)}"
  end

  defp assert_text(html, selector, expected_text) do
    text =
      html
      |> LazyHTML.from_fragment()
      |> LazyHTML.query(selector)
      |> LazyHTML.text()

    assert text =~ expected_text,
           "Expected #{inspect(selector)} to include #{inspect(expected_text)}, got #{inspect(text)}"
  end

  defp assert_class(html, selector, expected_class) do
    assert expected_class in classes(html, selector),
           "Expected #{inspect(selector)} to include class #{inspect(expected_class)}"
  end

  defp refute_class(html, selector, unexpected_class) do
    refute unexpected_class in classes(html, selector),
           "Expected #{inspect(selector)} not to include class #{inspect(unexpected_class)}"
  end

  defp classes(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute("class")
    |> List.first("")
    |> String.split()
  end

  defp avatar_bg_classes(html) do
    html
    |> classes("div.avatar > div")
    |> Enum.filter(&String.starts_with?(&1, "bg-sage-"))
  end
end
