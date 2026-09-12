defmodule MembaWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: MembaWeb.Gettext

  alias Phoenix.LiveView.JS

  @avatar_bg_cycle ~w(bg-sage-200 bg-sage-300 bg-sage-100 bg-sage-400 bg-sage-50)

  attr :initials, :string, required: true
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :class, :string, default: nil
  attr :rest, :global

  def avatar(assigns) do
    ~H"""
    <div class={["avatar avatar-placeholder", @class]} {@rest}>
      <div class={[size_w(@size), "rounded-full text-sage-800", avatar_bg(@initials)]}>
        <span class={size_text(@size)}>{@initials}</span>
      </div>
    </div>
    """
  end

  attr :tone, :string, default: "neutral", values: ~w(success info warning error neutral)
  attr :label, :string, required: true
  attr :rest, :global

  def status_badge(assigns) do
    ~H"""
    <span class={["badge badge-soft gap-1.5", tone_class(@tone)]} {@rest}>
      <span class="size-1.5 rounded-full bg-current"></span>{@label}
    </span>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash
        id="welcome-back"
        kind={:info}
        phx-mounted={show("#welcome-back") |> JS.remove_attribute("hidden")}
        hidden
      >
        Welcome Back!
      </.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end top-20 z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download form name value type disabled)
  attr :class, :any, default: nil
  attr :variant, :string, default: "primary", values: ~w(primary secondary ghost danger)
  attr :size, :string, default: nil, values: [nil, "sm", "lg"]
  attr :disabled, :boolean, default: false
  slot :inner_block, required: true

  def button(assigns) do
    variants = %{
      "primary" => "btn-primary",
      "secondary" => "btn-soft",
      "ghost" => "btn-ghost",
      "danger" => "btn-error"
    }

    sizes = %{nil => nil, "sm" => "btn-sm", "lg" => "btn-lg"}

    assigns =
      assigns
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:variant, fn -> "primary" end)
      |> assign_new(:size, fn -> nil end)
      |> assign_new(:disabled, fn -> false end)

    assigns =
      assign(assigns, :button_class, [
        "btn",
        Map.fetch!(variants, assigns.variant),
        Map.fetch!(sizes, assigns.size),
        assigns.class
      ])

    rest = assigns.rest

    cond do
      link_action?(rest) and assigns.disabled ->
        assigns = assign(assigns, :rest, disabled_link_action_rest(rest))

        ~H"""
        <span class={@button_class} aria-disabled="true" {@rest}>
          {render_slot(@inner_block)}
        </span>
        """

      link_action?(rest) ->
        ~H"""
        <.link class={@button_class} {@rest}>
          {render_slot(@inner_block)}
        </.link>
        """

      true ->
        ~H"""
        <button class={@button_class} disabled={@disabled} {@rest}>
          {render_slot(@inner_block)}
        </button>
        """
    end
  end

  attr :id, :string, required: true
  attr :button_id, :string, default: nil
  attr :content_id, :string, default: nil
  attr :label, :string, default: "More options"
  attr :rest, :global
  slot :inner_block, required: true

  def context_kebab_menu(assigns) do
    assigns =
      assigns
      |> assign(:button_id, assigns.button_id || "#{assigns.id}-button")
      |> assign(:content_id, assigns.content_id || "#{assigns.id}-content")

    ~H"""
    <details id={@id} class="context-menu dropdown dropdown-end" {@rest}>
      <summary
        id={@button_id}
        aria-controls={@content_id}
        aria-label={@label}
        class="context-menu__button"
      >
        <.icon name="hero-ellipsis-vertical" />
      </summary>
      <div id={@content_id} class="dropdown-content context-menu__content">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  defp link_action?(rest) do
    rest_attribute(rest, "href") || rest_attribute(rest, "navigate") || rest_attribute(rest, "patch")
  end

  defp disabled_link_action_rest(rest) do
    rest
    |> Enum.reject(fn {key, _value} -> disabled_link_action_attribute?(key) end)
    |> Map.new()
  end

  defp disabled_link_action_attribute?(key) do
    key = to_string(key)

    key in ~w(href navigate patch method download form type name value disabled role tabindex target rel aria-disabled) or
      String.starts_with?(key, "phx-")
  end

  defp size_w(:sm), do: "w-7"
  defp size_w(:md), do: "w-9"
  defp size_w(:lg), do: "w-12"

  defp size_text(:sm), do: "text-xs font-semibold"
  defp size_text(:md), do: "text-sm font-semibold"
  defp size_text(:lg), do: "text-base font-semibold"

  defp avatar_bg(initials) do
    Enum.at(@avatar_bg_cycle, rem(:erlang.phash2(initials), length(@avatar_bg_cycle)))
  end

  defp tone_class("success"), do: "badge-success"
  defp tone_class("info"), do: "badge-info"
  defp tone_class("warning"), do: "badge-warning"
  defp tone_class("error"), do: "badge-error"
  defp tone_class(_tone), do: nil

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assigns
      |> assign_new(:checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)
      |> assign_input_accessibility()

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            aria-describedby={@aria_describedby}
            aria-invalid={@aria_invalid}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={{msg, error_id} <- @errors_with_ids} id={error_id}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    assigns = assign_input_accessibility(assigns)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          aria-describedby={@aria_describedby}
          aria-invalid={@aria_invalid}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={{msg, error_id} <- @errors_with_ids} id={error_id}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    assigns = assign_input_accessibility(assigns)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          aria-describedby={@aria_describedby}
          aria-invalid={@aria_invalid}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={{msg, error_id} <- @errors_with_ids} id={error_id}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    assigns = assign_input_accessibility(assigns)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          aria-describedby={@aria_describedby}
          aria-invalid={@aria_invalid}
          {@rest}
        />
      </label>
      <.error :for={{msg, error_id} <- @errors_with_ids} id={error_id}>{msg}</.error>
    </div>
    """
  end

  defp assign_input_accessibility(assigns) do
    rest = assigns[:rest] || %{}
    errors = assigns[:errors] || []
    supplied_describedby = rest_attribute(rest, "aria-describedby")
    supplied_aria_invalid = rest_attribute(rest, "aria-invalid")

    errors_with_ids =
      errors
      |> Enum.with_index(1)
      |> Enum.map(fn {msg, index} -> {msg, input_error_id(assigns[:id], index)} end)

    error_ids =
      errors_with_ids
      |> Enum.map(fn {_msg, id} -> id end)
      |> Enum.reject(&is_nil/1)

    assigns
    |> assign(:rest, drop_rest_attributes(rest, ["aria-describedby", "aria-invalid"]))
    |> assign(:errors, errors)
    |> assign(:errors_with_ids, errors_with_ids)
    |> assign(:aria_describedby, aria_describedby(supplied_describedby, error_ids))
    |> assign(:aria_invalid, aria_invalid(supplied_aria_invalid, errors))
  end

  defp input_error_id(nil, _index), do: nil
  defp input_error_id("", _index), do: nil
  defp input_error_id(id, index), do: "#{id}-error-#{index}"

  defp rest_attribute(rest, name) do
    rest
    |> Enum.find_value(fn {key, value} -> if to_string(key) == name, do: value end)
  end

  defp drop_rest_attributes(rest, names) do
    Map.reject(rest, fn {key, _value} -> to_string(key) in names end)
  end

  defp aria_describedby(supplied_describedby, error_ids) do
    supplied_describedby
    |> describedby_tokens()
    |> Kernel.++(error_ids)
    |> Enum.uniq()
    |> Enum.join(" ")
    |> blank_to_nil()
  end

  defp describedby_tokens(nil), do: []

  defp describedby_tokens(tokens) when is_binary(tokens) do
    tokens
    |> String.split(~r/\s+/, trim: true)
    |> Enum.reject(&(&1 == ""))
  end

  defp describedby_tokens(tokens), do: describedby_tokens(to_string(tokens))

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp aria_invalid(_supplied_aria_invalid, [_error | _errors]), do: "true"
  defp aria_invalid(supplied_aria_invalid, _errors), do: supplied_aria_invalid

  # Helper used by inputs to generate form errors
  attr :id, :string, default: nil
  slot :inner_block, required: true

  defp error(assigns) do
    ~H"""
    <p id={@id} class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com) or a bundled monochrome brand icon.

  Brand icons (`brand-canadian-maple-leaf` and `brand-github`) use `currentColor`
  and inline SVG so they need no third-party runtime requests.

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def icon(%{name: "brand-canadian-maple-leaf"} = assigns) do
    ~H"""
    <svg viewBox="0 0 512 512" fill="currentColor" class={@class} focusable="false" {@rest}>
      <path d="M383.8 351.7c2.5-2.5 105.2-92.4 105.2-92.4l-17.5-7.5c-10-4.9-7.4-11.5-5-17.4 2.4-7.6 20.1-67.3 20.1-67.3s-47.7 10-57.7 12.5c-7.5 2.4-10-2.5-12.5-7.5s-15-32.4-15-32.4-52.6 59.9-55.1 62.3c-10 7.5-20.1 0-17.6-10 0-10 27.6-129.6 27.6-129.6s-30.1 17.4-40.1 22.4c-7.5 5-12.6 5-17.6-5C293.5 72.3 255.9 0 255.9 0s-37.5 72.3-42.5 79.8c-5 10-10 10-17.6 5-10-5-40.1-22.4-40.1-22.4S183.3 182 183.3 192c2.5 10-7.5 17.5-17.6 10-2.5-2.5-55.1-62.3-55.1-62.3S98.1 167 95.6 172s-5 9.9-12.5 7.5C73 177 25.4 167 25.4 167s17.6 59.7 20.1 67.3c2.4 6 5 12.5-5 17.4L23 259.3s102.6 89.9 105.2 92.4c5.1 5 10 7.5 5.1 22.5-5.1 15-10.1 35.1-10.1 35.1s95.2-20.1 105.3-22.6c8.7-.9 18.3 2.5 18.3 12.5S241 512 241 512h30s-5.8-102.7-5.8-112.8 9.5-13.4 18.4-12.5c10 2.5 105.2 22.6 105.2 22.6s-5-20.1-10-35.1 0-17.5 5-22.5z" />
    </svg>
    """
  end

  def icon(%{name: "brand-github"} = assigns) do
    ~H"""
    <svg viewBox="0 0 24 24" fill="currentColor" class={@class} focusable="false" {@rest}>
      <path d="M12 .75a11.25 11.25 0 0 0-3.56 21.92c.56.1.77-.24.77-.54v-2.1c-3.13.68-3.79-1.33-3.79-1.33-.51-1.3-1.25-1.65-1.25-1.65-1.02-.7.08-.68.08-.68 1.13.08 1.72 1.16 1.72 1.16 1 1.72 2.63 1.22 3.27.94.1-.73.4-1.22.72-1.5-2.5-.29-5.13-1.25-5.13-5.56 0-1.23.44-2.23 1.16-3.02-.12-.28-.5-1.43.11-2.98 0 0 .95-.3 3.1 1.16a10.8 10.8 0 0 1 5.63 0c2.15-1.46 3.1-1.16 3.1-1.16.61 1.55.23 2.7.11 2.98.72.79 1.16 1.79 1.16 3.02 0 4.32-2.63 5.27-5.14 5.55.4.35.76 1.04.76 2.09v3.08c0 .3.2.65.78.54A11.25 11.25 0 0 0 12 .75Z" />
    </svg>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(MembaWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MembaWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
