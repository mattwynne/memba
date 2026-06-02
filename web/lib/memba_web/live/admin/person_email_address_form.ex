defmodule MembaWeb.Admin.PersonEmailAddressForm do
  @moduledoc false

  alias Memba.Membership.EmailAddresses

  @empty_params %{
    "name" => "",
    "primary_email_index" => "0",
    "email_addresses" => %{"0" => %{"email" => ""}}
  }

  def empty_params, do: @empty_params

  def params_for_person(nil, _email_addresses), do: @empty_params

  def params_for_person(person, email_addresses) do
    rows =
      email_addresses
      |> Enum.with_index()
      |> Map.new(fn {email_address, index} ->
        index = Integer.to_string(index)

        {index,
         %{"email" => email_address.email, "is_primary" => to_string(email_address.primary?)}}
      end)

    primary_index =
      email_addresses
      |> Enum.find_index(& &1.primary?)
      |> case do
        nil -> ""
        index -> Integer.to_string(index)
      end

    %{
      "name" => person.name,
      "primary_email_index" => primary_index,
      "email_addresses" => rows
    }
  end

  def rows(params) when is_map(params) do
    params
    |> raw_rows()
    |> apply_primary_index(Map.get(params, "primary_email_index", :missing))
    |> ensure_one_row()
  end

  def validate(params) when is_map(params) do
    rows = rows(params)
    email_addresses = Enum.map(rows, &row_email_address/1)

    with {:ok, name} <- validate_name(Map.get(params, "name")),
         {:ok, normalized_email_addresses} <- EmailAddresses.validate_set(email_addresses) do
      {:ok, %{name: name, email_addresses: normalized_email_addresses}}
    else
      {:error, :invalid_name} -> {:error, errors(name: "Enter a name.")}
      {:error, reason} -> {:error, errors_for_email_reason(reason, rows)}
    end
  end

  def with_server_error(params, reason) do
    {:error, errors_for_email_reason(reason, rows(params))}
  end

  def add_row(params) when is_map(params) do
    rows = rows(params)
    next_index = rows |> Enum.map(& &1.index) |> next_index()

    put_rows(params, rows ++ [%{index: next_index, email: "", primary?: false}])
  end

  def remove_row(params, remove_index) when is_map(params) do
    rows =
      params
      |> rows()
      |> Enum.reject(&(&1.index == remove_index))
      |> ensure_one_row()

    rows =
      if Enum.any?(rows, & &1.primary?) do
        rows
      else
        mark_first_primary(rows)
      end

    put_rows(params, rows)
  end

  def format_reason(:email_address_taken), do: "email address already belongs to another person"
  def format_reason(:duplicate_email_address), do: "email addresses must be unique"
  def format_reason(:invalid_email), do: "email address is invalid"
  def format_reason(:email_address_required), do: "enter at least one email address"

  def format_reason(:exactly_one_primary_email_required),
    do: "choose exactly one primary email address"

  def format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")

  defp validate_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      name -> {:ok, name}
    end
  end

  defp validate_name(_name), do: {:error, :invalid_name}

  defp raw_rows(params) do
    case Map.get(params, "email_addresses") do
      rows when is_map(rows) ->
        rows
        |> Enum.sort_by(fn {index, _row} -> parse_index(index) end)
        |> Enum.map(fn {index, row} -> row_from_params(index, row) end)

      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} -> row_from_params(Integer.to_string(index), row) end)

      _other ->
        []
    end
  end

  defp row_from_params(index, row) when is_map(row) do
    %{
      index: to_string(index),
      email: Map.get(row, "email", Map.get(row, :email, "")),
      primary?: primary?(Map.get(row, "is_primary", Map.get(row, :is_primary, false)))
    }
  end

  defp row_from_params(index, _row), do: %{index: to_string(index), email: "", primary?: false}

  defp apply_primary_index(rows, :missing), do: rows
  defp apply_primary_index(rows, ""), do: Enum.map(rows, &%{&1 | primary?: false})

  defp apply_primary_index(rows, primary_index) do
    primary_index = to_string(primary_index)
    Enum.map(rows, &%{&1 | primary?: &1.index == primary_index})
  end

  defp ensure_one_row([]), do: [%{index: "0", email: "", primary?: true}]
  defp ensure_one_row(rows), do: rows

  defp mark_first_primary([row | rest]),
    do: [%{row | primary?: true} | Enum.map(rest, &%{&1 | primary?: false})]

  defp put_rows(params, rows) do
    rows = reindex(rows)

    email_addresses =
      Map.new(rows, fn row ->
        {row.index, %{"email" => row.email, "is_primary" => to_string(row.primary?)}}
      end)

    primary_index =
      rows
      |> Enum.find(& &1.primary?)
      |> case do
        nil -> ""
        row -> row.index
      end

    params
    |> Map.put("email_addresses", email_addresses)
    |> Map.put("primary_email_index", primary_index)
  end

  defp reindex(rows) do
    rows
    |> Enum.with_index()
    |> Enum.map(fn {row, index} -> %{row | index: Integer.to_string(index)} end)
  end

  defp row_email_address(row), do: %{email: row.email, is_primary: row.primary?}

  defp errors(opts) do
    %{
      name: error_list(Keyword.get(opts, :name)),
      row_errors: Keyword.get(opts, :row_errors, %{}),
      global: Keyword.get(opts, :global)
    }
  end

  defp errors_for_email_reason(:invalid_email, rows) do
    invalid_row_errors =
      rows
      |> Enum.filter(fn row ->
        match?({:error, :invalid_email}, EmailAddresses.normalize_email(row.email))
      end)
      |> Map.new(fn row -> {row.index, error_list("Enter a valid email address.")} end)

    errors(row_errors: invalid_row_errors, global: "Fix invalid email addresses.")
  end

  defp errors_for_email_reason(:email_address_taken, rows) do
    rows
    |> Map.new(fn row -> {row.index, error_list("This email address is already used.")} end)
    |> then(
      &errors(row_errors: &1, global: "An email address is already used by another person.")
    )
  end

  defp errors_for_email_reason(:duplicate_email_address, rows) do
    duplicate_row_errors =
      rows
      |> duplicate_indexes()
      |> Map.new(&{&1, error_list("Email addresses must be unique.")})

    errors(row_errors: duplicate_row_errors, global: "Email addresses must be unique.")
  end

  defp errors_for_email_reason(:exactly_one_primary_email_required, _rows) do
    errors(global: "Choose exactly one primary email address.")
  end

  defp errors_for_email_reason(:email_address_required, _rows) do
    errors(global: "Enter at least one email address.")
  end

  defp errors_for_email_reason(reason, _rows), do: errors(global: format_reason(reason))

  defp duplicate_indexes(rows) do
    rows
    |> Enum.reduce(%{}, fn row, grouped ->
      case EmailAddresses.normalize_email(row.email) do
        {:ok, %{normalized_email: normalized_email}} ->
          Map.update(grouped, normalized_email, [row.index], &[row.index | &1])

        {:error, :invalid_email} ->
          grouped
      end
    end)
    |> Map.values()
    |> Enum.filter(&(length(&1) > 1))
    |> List.flatten()
  end

  defp error_list(nil), do: []
  defp error_list(message), do: [message]

  defp primary?(true), do: true
  defp primary?("true"), do: true
  defp primary?("on"), do: true
  defp primary?(_other), do: false

  defp next_index([]), do: "0"

  defp next_index(indexes) do
    indexes
    |> Enum.map(&parse_index/1)
    |> Enum.max()
    |> Kernel.+(1)
    |> Integer.to_string()
  end

  defp parse_index(index) when is_integer(index), do: index

  defp parse_index(index) do
    case Integer.parse(to_string(index)) do
      {index, ""} -> index
      _other -> 0
    end
  end
end
