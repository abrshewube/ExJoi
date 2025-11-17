defmodule ExJoi.Validator do
  @moduledoc """
  Core validation engine that validates data against schemas.
  """

  alias ExJoi.{Rule, Schema}

  @doc """
  Validates data against a schema.

  Returns `{:ok, validated_data}` if validation passes, or `{:error, errors}` if it fails.
  """
  def validate(data, %Schema{fields: fields}) when is_map(data) do
    errors =
      fields
      |> Enum.reduce(%{}, fn {field_name, rule}, acc ->
        case validate_field(data, field_name, rule) do
          :ok -> acc
          {:error, field_errors} -> Map.put(acc, field_name, field_errors)
        end
      end)

    if map_size(errors) == 0 do
      {:ok, data}
    else
      {:error, errors}
    end
  end

  def validate(_data, _schema) do
    {:error, %{_schema: ["data must be a map"]}}
  end

  # Validates a single field against its rule
  defp validate_field(data, field_name, %Rule{} = rule) do
    value = get_field_value(data, field_name)

    cond do
      value == nil and rule.required ->
        {:error, ["is required"]}

      value == nil ->
        :ok

      true ->
        validate_type(value, rule.type)
    end
  end

  # Gets field value from data, handling both atom and string keys
  defp get_field_value(data, field_name) when is_atom(field_name) do
    Map.get(data, field_name) || Map.get(data, Atom.to_string(field_name))
  end

  defp get_field_value(data, field_name) when is_binary(field_name) do
    Map.get(data, field_name) || Map.get(data, String.to_existing_atom(field_name))
  rescue
    ArgumentError -> Map.get(data, field_name)
  end

  # Validates that the value matches the expected type
  defp validate_type(value, :string) when is_binary(value), do: :ok
  defp validate_type(_value, :string), do: {:error, ["must be a string"]}

  defp validate_type(value, :number) when is_number(value), do: :ok
  defp validate_type(_value, :number), do: {:error, ["must be a number"]}

  defp validate_type(value, :boolean) when is_boolean(value), do: :ok
  defp validate_type(_value, :boolean), do: {:error, ["must be a boolean"]}
end
