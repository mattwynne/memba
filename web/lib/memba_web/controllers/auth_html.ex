defmodule MembaWeb.AuthHTML do
  @moduledoc """
  HTML views for shared magic-link authentication.
  """
  use MembaWeb, :html

  embed_templates "auth_html/*"
end
