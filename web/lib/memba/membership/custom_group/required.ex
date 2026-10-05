defmodule Memba.Membership.CustomGroup.Required do
  @moduledoc false

  def fetch(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} ->
        {:ok, value}

      :error ->
        case Map.fetch(attrs, Atom.to_string(key)) do
          {:ok, value} -> {:ok, value}
          :error -> {:error, {:missing_required_attribute, key}}
        end
    end
  end
end
