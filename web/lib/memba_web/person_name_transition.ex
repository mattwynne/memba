defmodule MembaWeb.PersonNameTransition do
  @moduledoc "Name-edit workflow feedback at the web boundary."

  def error_message(:invalid_name), do: "Enter the name your clubs should see."
  def error_message(:name_too_long), do: "That name is too long."
end
