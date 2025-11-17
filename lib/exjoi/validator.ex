defmodule ExJoi.Validator do
  @moduledoc """
  Core validation engine that validates data against schemas.
  """

  alias ExJoi.{Rule, Schema}

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Validates data against a schema.

  Returns `{:ok, validated_data}` if validation passes, or `{:error, errors}` if it fails.
  """
  def validate(data, %Schema{fields: fields}) when is_map(data) do
    {errors, coerced_data} =
      Enum.reduce(fields, {%{}, data}, fn {field_name, rule}, {error_acc, data_acc} ->
        case validate_field(data_acc, field_name, rule) do
          {:ok, :missing} ->
            {error_acc, data_acc}

          {:ok, {key, value}} ->
            {error_acc, Map.put(data_acc, key, value)}

          {:error, field_errors} ->
            {Map.put(error_acc, field_name, field_errors), data_acc}
        end
      end)

    if map_size(errors) == 0 do
      {:ok, coerced_data}
    else
      {:error, format_errors(errors)}
    end
  end

  def validate(_data, _schema) do
    {:error, format_errors(%{_schema: [error(:invalid_data, "data must be a map")]})}
  end

  defp validate_field(data, field_name, %Rule{} = rule) do
    case fetch_field_value(data, field_name) do
      :missing when rule.required ->
        {:error, [error(:required, "is required")]}

      :missing ->
        {:ok, :missing}

      {:ok, key, value} ->
        case validate_value(value, rule) do
          {:ok, coerced} -> {:ok, {key, coerced}}
          {:error, errors} -> {:error, errors}
        end
    end
  end

  defp fetch_field_value(data, field_name) when is_atom(field_name) do
    case Map.fetch(data, field_name) do
      {:ok, value} when not is_nil(value) ->
        {:ok, field_name, value}

      _ ->
        string_name = Atom.to_string(field_name)

        case Map.fetch(data, string_name) do
          {:ok, value} when not is_nil(value) -> {:ok, string_name, value}
          _ -> :missing
        end
    end
  end

  defp fetch_field_value(data, field_name) when is_binary(field_name) do
    case Map.fetch(data, field_name) do
      {:ok, value} when not is_nil(value) ->
        {:ok, field_name, value}

      _ ->
        atom_name =
          try do
            String.to_existing_atom(field_name)
          rescue
            ArgumentError -> nil
          end

        if atom_name && Map.has_key?(data, atom_name) do
          case Map.fetch(data, atom_name) do
            {:ok, value} when not is_nil(value) -> {:ok, atom_name, value}
            _ -> :missing
          end
        else
          :missing
        end
    end
  end

  defp validate_value(value, %Rule{type: :string} = rule) do
    with :ok <- ensure_string(value),
         [] <- string_constraint_errors(value, rule) do
      {:ok, value}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value(value, %Rule{type: :number} = rule) do
    with :ok <- ensure_number(value),
         [] <- number_constraint_errors(value, rule) do
      {:ok, value}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value(value, %Rule{type: :boolean} = rule) do
    cond do
      is_boolean(value) ->
        {:ok, value}

      matches_truthy?(value, rule.truthy) ->
        {:ok, true}

      matches_falsy?(value, rule.falsy) ->
        {:ok, false}

      true ->
        {:error, [error(:boolean, "must be a boolean")]}
    end
  end

  defp ensure_string(value) when is_binary(value), do: :ok
  defp ensure_string(_value), do: {:error, [error(:string, "must be a string")]}

  defp ensure_number(value) when is_number(value), do: :ok
  defp ensure_number(_value), do: {:error, [error(:number, "must be a number")]}

  defp string_constraint_errors(value, %Rule{} = rule) do
    []
    |> maybe_add(not is_nil(rule.min) and String.length(value) < rule.min, fn ->
      error(:string_min, "must be at least #{rule.min} characters", %{min: rule.min})
    end)
    |> maybe_add(not is_nil(rule.max) and String.length(value) > rule.max, fn ->
      error(:string_max, "must be at most #{rule.max} characters", %{max: rule.max})
    end)
    |> maybe_add(rule.pattern && !Regex.match?(rule.pattern, value), fn ->
      error(:string_pattern, "must match required pattern")
    end)
    |> maybe_add(rule.email && !Regex.match?(@email_regex, value), fn ->
      error(:string_email, "must be a valid email")
    end)
  end

  defp number_constraint_errors(value, %Rule{} = rule) do
    []
    |> maybe_add(not is_nil(rule.min) and value < rule.min, fn ->
      error(:number_min, "must be greater than or equal to #{rule.min}", %{min: rule.min})
    end)
    |> maybe_add(not is_nil(rule.max) and value > rule.max, fn ->
      error(:number_max, "must be less than or equal to #{rule.max}", %{max: rule.max})
    end)
    |> maybe_add(rule.integer && not is_integer(value), fn ->
      error(:number_integer, "must be an integer")
    end)
  end

  defp matches_truthy?(value, values),
    do: values |> normalize_boolean_collection() |> MapSet.member?(normalize_boolean_value(value))

  defp matches_falsy?(value, values),
    do: values |> normalize_boolean_collection() |> MapSet.member?(normalize_boolean_value(value))

  defp normalize_boolean_collection(nil), do: MapSet.new()

  defp normalize_boolean_collection(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&normalize_boolean_value/1)
    |> MapSet.new()
  end

  defp normalize_boolean_value(value) when is_binary(value) do
    value |> String.trim() |> String.downcase()
  end

  defp normalize_boolean_value(value), do: value

  defp maybe_add(errors, false, _fun), do: errors
  defp maybe_add(errors, nil, _fun), do: errors
  defp maybe_add(errors, true, fun), do: errors ++ [fun.()]

  defp error(code, message, meta \\ %{}) do
    %{code: code, message: message, meta: meta}
  end

  defp format_errors(errors) do
    %{
      message: "Validation failed",
      errors: errors
    }
  end
end
