defmodule ExJoi.Validator do
  @moduledoc """
  Core validation engine that validates data against schemas.
  """

  alias ExJoi.{Config, Rule, Schema}
  @type error :: %{code: atom(), message: String.t(), meta: map()}

  alias DateTime
  alias NaiveDateTime
  alias Date

  @default_truthy [true, "true", "True", "TRUE", "1", 1, "yes", "Yes", "YES", "on", "On", "ON"]
  @default_falsy [false, "false", "False", "FALSE", "0", 0, "no", "No", "NO", "off", "Off", "OFF"]

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Validates data against a schema.

  Returns `{:ok, validated_data}` if validation passes, or `{:error, errors}` if it fails.

  ## Options

    * `:convert` (boolean, default: `false`) - Enable type coercion
    * `:timeout` (integer, default: `5000`) - Timeout in milliseconds for async validation
    * `:max_concurrency` (integer, default: `10`) - Maximum concurrent async validations
  """
  def validate(data, schema, opts \\ [])

  def validate(data, %Schema{fields: fields, defaults: defaults}, opts) when is_map(data) do
    convert = Keyword.get(opts, :convert, false)
    data_with_defaults = apply_defaults(data, defaults)

    # Check if any field has async validation
    has_async = Enum.any?(fields, fn {_field_name, rule} -> not is_nil(rule.async) end)

    if has_async do
      validate_async(data_with_defaults, fields, convert, opts)
    else
      validate_sync(data_with_defaults, fields, convert)
    end
  end

  def validate(data, _schema, _opts) when not is_map(data) do
    {:error, format_errors(%{_schema: [error(:invalid_data, "data must be a map")]})}
  end

  defp validate_sync(data, fields, convert) do
    {errors, coerced_data} =
      Enum.reduce(fields, {%{}, data}, fn {field_name, rule}, {error_acc, data_acc} ->
        case validate_field(data_acc, field_name, rule, convert) do
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

  defp validate_async(data, fields, convert, opts) do
    timeout = Keyword.get(opts, :timeout, 5000)

    # Validate all fields in parallel using Task.async_stream
    results =
      fields
      |> Task.async_stream(
        fn {field_name, rule} ->
          case validate_field_async(data, field_name, rule, convert, timeout) do
            {:ok, :missing} -> {:ok, field_name, :missing}
            {:ok, {key, value}} -> {:ok, field_name, {key, value}}
            {:error, field_errors} -> {:error, field_name, field_errors}
          end
        end,
        max_concurrency: Keyword.get(opts, :max_concurrency, 10),
        timeout: timeout,
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    {errors, coerced_data} =
      Enum.reduce(results, {%{}, data}, fn
        {:ok, {:ok, _field_name, :missing}}, {error_acc, data_acc} ->
          {error_acc, data_acc}

        {:ok, {:ok, _field_name, {key, value}}}, {error_acc, data_acc} ->
          {error_acc, Map.put(data_acc, key, value)}

        {:ok, {:error, field_name, field_errors}}, {error_acc, data_acc} ->
          {Map.put(error_acc, field_name, field_errors), data_acc}

        {:exit, {:timeout, _}}, {error_acc, data_acc} ->
          {Map.put(error_acc, :_async_timeout, [error(:async_timeout, "async validation timed out")]), data_acc}

        {:exit, reason}, {error_acc, data_acc} ->
          {Map.put(error_acc, :_async_error, [error(:async_error, "async validation failed: #{inspect(reason)}")]), data_acc}
      end)

    if map_size(errors) == 0 do
      {:ok, coerced_data}
    else
      {:error, format_errors(errors)}
    end
  end


  defp validate_field(data, field_name, %Rule{type: :conditional} = rule, convert) do
    active_rule = resolve_conditional_rule(rule.conditional, data)
    effective_rule = active_rule || rule.conditional[:base]
    required? =
      cond do
        match?(%Rule{}, effective_rule) and effective_rule.required -> true
        true -> rule.required
      end

    case fetch_field_value(data, field_name) do
      :missing when required? ->
        {:error, [error(:required, "is required")]}

      :missing ->
        {:ok, :missing}

      {:ok, key, value} ->
        if match?(%Rule{}, effective_rule) do
          with {:ok, coerced} <- validate_value(value, effective_rule, convert, data) do
            {:ok, {key, coerced}}
          end
        else
          {:ok, {key, value}}
        end
    end
  end

  defp validate_field(data, field_name, %Rule{} = rule, convert) do
    case fetch_field_value(data, field_name) do
      :missing when rule.required ->
        {:error, [error(:required, "is required")]}

      :missing ->
        {:ok, :missing}

      {:ok, key, value} ->
        case validate_value(value, rule, convert, data) do
          {:ok, coerced} ->
            {:ok, {key, coerced}}

          {:error, errors} ->
            {:error, errors}
        end
    end
  end

  defp validate_field_async(data, field_name, %Rule{async: nil} = rule, convert, _timeout) do
    validate_field(data, field_name, rule, convert)
  end

  defp validate_field_async(data, field_name, %Rule{async: async_fn, timeout: rule_timeout} = rule, convert, default_timeout) do
    # Use rule timeout if specified, otherwise use default timeout
    timeout = if rule_timeout, do: rule_timeout, else: default_timeout

    case fetch_field_value(data, field_name) do
      :missing when rule.required ->
        {:error, [error(:required, "is required")]}

      :missing ->
        {:ok, :missing}

      {:ok, key, value} ->
        # First do synchronous validation
        case validate_value_sync(value, rule, convert, data) do
          {:error, errors} ->
            {:error, errors}

          {:ok, validated_value} ->
            # Then run async validation
            context = %{convert: convert, data: data, custom_opts: rule.custom_opts}

            case async_fn.(validated_value, context) do
              {:ok, final_value} ->
                {:ok, {key, final_value}}

              {:error, errors} when is_list(errors) ->
                {:error, errors}

              %Task{} = task ->
                # Task returned, await it with timeout
                try do
                  case Task.await(task, timeout) do
                    {:ok, final_value} ->
                      {:ok, {key, final_value}}

                    {:error, errors} when is_list(errors) ->
                      {:error, errors}

                    other ->
                      {:error, [error(:async_validation, "async validation returned unexpected result: #{inspect(other)}")]}
                  end
                catch
                  :exit, {:timeout, _} ->
                    {:error, [error(:async_timeout, "async validation timed out after #{timeout}ms")]}

                  :exit, reason ->
                    {:error, [error(:async_error, "async validation failed: #{inspect(reason)}")]}
                end

              other ->
                {:error, [error(:async_validation, "async function returned unexpected result: #{inspect(other)}")]}
            end
        end
    end
  end

  # Synchronous validation without async
  defp validate_value_sync(value, %Rule{type: :string} = rule, convert, _data) do
    with {:ok, normalized} <- ensure_string(value, convert),
         [] <- string_constraint_errors(normalized, rule) do
      {:ok, normalized}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value_sync(value, %Rule{type: :number} = rule, convert, _data) do
    with {:ok, number} <- ensure_number(value, convert),
         [] <- number_constraint_errors(number, rule) do
      {:ok, number}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value_sync(value, %Rule{type: :boolean} = rule, convert, _data) do
    with {:ok, bool} <- coerce_boolean(value, rule, convert) do
      {:ok, bool}
    else
      :error -> {:error, [error(:boolean, "must be a boolean")]}
    end
  end

  defp validate_value_sync(value, %Rule{type: :object, schema: schema}, convert, _data) do
    if not is_map(value) do
      {:error, [error(:object, "must be an object/map")]}
    else
      case schema do
        %Schema{} = nested_schema ->
          case validate(value, nested_schema, convert: convert) do
            {:ok, validated} -> {:ok, validated}
            {:error, nested_errors} -> {:error, nested_errors}
          end

        _ ->
          {:ok, value}
      end
    end
  end

  defp validate_value_sync(value, %Rule{type: :array, of: of_rule} = rule, convert, data) do
    with {:ok, list} <- coerce_array(value, rule.delimiter),
         [] <- array_constraint_errors(list, rule) do
      # For async arrays, validate elements in parallel
      if of_rule && not is_nil(of_rule.async) do
        validate_array_elements_async(list, of_rule, convert, data, of_rule.timeout || 5000)
      else
        validate_array_elements(list, of_rule, convert, data)
      end
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value_sync(value, %Rule{type: :date}, convert, _data) do
    case ensure_date(value, convert) do
      {:ok, datetime} -> {:ok, datetime}
      :error -> {:error, [error(:date, "must be a valid date")]}
    end
  end

  defp validate_value_sync(value, %Rule{type: {:custom, type_name}, custom_opts: opts} = rule, convert, data) do
    case Config.fetch_type(type_name) do
      nil ->
        {:error, [error(:custom_type, "unknown custom type #{type_name}")]}

      validator ->
        context = %{convert: convert, data: data, custom_opts: opts}
        run_custom_validator(validator, value, rule, context)
    end
  end

  defp validate_value_sync(value, %Rule{}, _convert, _data), do: {:ok, value}

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

  defp validate_value(value, %Rule{type: :string} = rule, convert, _data) do
    with {:ok, normalized} <- ensure_string(value, convert),
         [] <- string_constraint_errors(normalized, rule) do
      {:ok, normalized}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value(value, %Rule{type: :number} = rule, convert, _data) do
    with {:ok, number} <- ensure_number(value, convert),
         [] <- number_constraint_errors(number, rule) do
      {:ok, number}
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value(value, %Rule{type: :boolean} = rule, convert, _data) do
    case coerce_boolean(value, rule, convert) do
      {:ok, bool} -> {:ok, bool}
      :error -> {:error, [error(:boolean, "must be a boolean")]}
    end
  end

  defp validate_value(value, %Rule{type: :array, of: of_rule} = rule, convert, data) do
    with {:ok, list} <- coerce_array(value, rule.delimiter),
         [] <- array_constraint_errors(list, rule) do
      # For async arrays, validate elements in parallel
      if of_rule && not is_nil(of_rule.async) do
        validate_array_elements_async(list, of_rule, convert, data, of_rule.timeout || 5000)
      else
        validate_array_elements(list, of_rule, convert, data)
      end
    else
      {:error, errors} -> {:error, errors}
      errors when is_list(errors) -> {:error, errors}
    end
  end

  defp validate_value(value, %Rule{type: :object, schema: %Schema{} = schema}, convert, _data) do
    if is_map(value) do
      case validate(value, schema, convert: convert) do
        {:ok, coerced} ->
          {:ok, coerced}

        {:error, %{errors: nested_errors}} ->
          {:error, nested_errors}
      end
    else
      {:error, [error(:object, "must be an object/map")]}
    end
  end

  defp validate_value(value, %Rule{type: :date} = _rule, convert, _data) do
    case ensure_date(value, convert) do
      {:ok, datetime} -> {:ok, datetime}
      :error -> {:error, [error(:date, "must be an ISO8601 date/time")]}
    end
  end

  defp validate_value(value, %Rule{type: :conditional} = rule, convert, data) do
    case resolve_conditional_rule(rule.conditional, data) || rule.conditional[:base] do
      %Rule{} = effective_rule ->
        validate_value(value, effective_rule, convert, data)

      _ ->
        {:ok, value}
    end
  end

  defp validate_value(value, %Rule{type: {:custom, type_name}, custom_opts: opts} = rule, convert, data) do
    case Config.fetch_type(type_name) do
      nil ->
        {:error, [error(:custom_type, "unknown custom type #{type_name}")]}

      validator ->
        context = %{convert: convert, data: data, opts: opts}
        run_custom_validator(validator, value, rule, context)
    end
  end

  defp validate_value(value, nil, _convert, _data), do: {:ok, value}
  defp validate_value(value, %Rule{}, _convert, _data), do: {:ok, value}

  defp ensure_string(value, convert) when is_binary(value) do
    normalized =
      if convert do
        value
        |> String.trim()
        |> String.replace(~r/\s+/, " ")
      else
        value
      end

    {:ok, normalized}
  end

  defp ensure_string(_value, _convert), do: {:error, [error(:string, "must be a string")]}

  defp ensure_number(value, _convert) when is_number(value), do: {:ok, value}

  defp ensure_number(value, true) when is_binary(value) do
    case parse_number_from_string(value) do
      {:ok, number} -> {:ok, number}
      :error -> {:error, [error(:number, "must be a number")]}
    end
  end

  defp ensure_number(_value, _convert), do: {:error, [error(:number, "must be a number")]}

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

  defp apply_defaults(data, defaults) when map_size(defaults) == 0, do: data

  defp apply_defaults(data, defaults) do
    defaults
    |> Enum.reduce(data, fn {key, default_value}, acc ->
      case fetch_field_value(acc, key) do
        :missing -> Map.put(acc, key, default_value)
        _ -> acc
      end
    end)
  end

  defp coerce_array(value, _delimiter) when is_list(value), do: {:ok, value}

  defp coerce_array(value, delimiter) when is_binary(value) and is_binary(delimiter) do
    list =
      value
      |> String.split(delimiter)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    {:ok, list}
  end

  defp coerce_array(_value, _delimiter), do: {:error, [error(:array, "must be an array/list")]}

  defp array_constraint_errors(list, %Rule{} = rule) do
    count = length(list)

    []
    |> maybe_add(not is_nil(rule.min_items) and count < rule.min_items, fn ->
      error(:array_min_items, "must contain at least #{rule.min_items} items", %{min_items: rule.min_items})
    end)
    |> maybe_add(not is_nil(rule.max_items) and count > rule.max_items, fn ->
      error(:array_max_items, "must contain at most #{rule.max_items} items", %{max_items: rule.max_items})
    end)
    |> maybe_add(rule.unique && count != length(Enum.uniq(list)), fn ->
      error(:array_unique, "must contain unique items")
    end)
  end

  defp validate_array_elements(list, nil, _convert, _data), do: {:ok, list}

  defp validate_array_elements(list, %Rule{} = rule, convert, data) do
    {errors, values} =
      list
      |> Enum.with_index()
      |> Enum.reduce({%{}, []}, fn {item, idx}, {err_acc, val_acc} ->
        case validate_value(item, rule, convert, data) do
          {:ok, coerced} ->
            {err_acc, [coerced | val_acc]}

          {:error, element_errors} ->
            {Map.put(err_acc, idx, element_errors), val_acc}
        end
      end)

    if map_size(errors) == 0 do
      {:ok, Enum.reverse(values)}
    else
      {:error, errors}
    end
  end

  defp validate_array_elements_async(list, %Rule{async: async_fn, timeout: timeout} = rule, convert, data, default_timeout) do
    timeout_ms = timeout || default_timeout

    # Create a rule without async for synchronous validation
    sync_rule = %Rule{rule | async: nil}

    results =
      list
      |> Enum.with_index()
      |> Task.async_stream(
        fn {item, idx} ->
          # First do synchronous validation (type and constraints)
          case validate_value_sync(item, sync_rule, convert, data) do
            {:error, errors} ->
              {:error, idx, errors}

            {:ok, validated_item} ->
              # Then run async validation
              context = %{convert: convert, data: data, custom_opts: rule.custom_opts}

              case async_fn.(validated_item, context) do
                {:ok, final_value} ->
                  {:ok, idx, final_value}

                {:error, errors} when is_list(errors) ->
                  {:error, idx, errors}

                %Task{} = task ->
                  try do
                    case Task.await(task, timeout_ms) do
                      {:ok, final_value} ->
                        {:ok, idx, final_value}

                      {:error, errors} when is_list(errors) ->
                        {:error, idx, errors}

                      other ->
                        {:error, idx, [error(:async_validation, "async validation returned unexpected result: #{inspect(other)}")]}
                    end
                  catch
                    :exit, {:timeout, _} ->
                      {:error, idx, [error(:async_timeout, "async validation timed out after #{timeout_ms}ms")]}

                    :exit, reason ->
                      {:error, idx, [error(:async_error, "async validation failed: #{inspect(reason)}")]}
                  end

                other ->
                  {:error, idx, [error(:async_validation, "async function returned unexpected result: #{inspect(other)}")]}
              end
          end
        end,
        max_concurrency: 10,
        timeout: timeout_ms,
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    {errors, indexed_values} =
      Enum.reduce(results, {%{}, %{}}, fn
        {:ok, {:ok, idx, value}}, {err_acc, val_acc} ->
          {err_acc, Map.put(val_acc, idx, value)}

        {:ok, {:error, idx, element_errors}}, {err_acc, val_acc} ->
          {Map.put(err_acc, idx, element_errors), val_acc}

        {:exit, {:timeout, _}}, {err_acc, val_acc} ->
          {Map.put(err_acc, :_timeout, [error(:async_timeout, "async array validation timed out")]), val_acc}

        {:exit, reason}, {err_acc, val_acc} ->
          {Map.put(err_acc, :_error, [error(:async_error, "async array validation failed: #{inspect(reason)}")]), val_acc}
      end)

    if map_size(errors) == 0 do
      # Reconstruct list in original order
      values = Enum.map(0..(length(list) - 1), &Map.get(indexed_values, &1))
      {:ok, values}
    else
      {:error, errors}
    end
  end

  defp resolve_conditional_rule(nil, _data), do: nil

  defp resolve_conditional_rule(%{field: field, checks: checks, then: then_rule, otherwise: otherwise}, data) do
    compare_value = get_condition_value(data, field)

    if condition_met?(compare_value, checks) do
      then_rule
    else
      otherwise
    end
  end

  defp parse_number_from_string(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" ->
        :error

      true ->
        with {int_value, ""} <- Integer.parse(trimmed) do
          {:ok, int_value}
        else
          _ ->
            case Float.parse(trimmed) do
              {float_value, ""} -> {:ok, float_value}
              _ -> :error
            end
        end
    end
  end

  defp coerce_boolean(value, _rule, _convert) when is_boolean(value), do: {:ok, value}

  defp coerce_boolean(value, rule, convert) do
    truthy_values = rule.truthy || default_truthy(convert)
    falsy_values = rule.falsy || default_falsy(convert)

    cond do
      should_coerce_boolean?(truthy_values) && matches_truthy?(value, truthy_values) ->
        {:ok, true}

      should_coerce_boolean?(falsy_values) && matches_falsy?(value, falsy_values) ->
        {:ok, false}

      true ->
        :error
    end
  end

  defp should_coerce_boolean?(nil), do: false
  defp should_coerce_boolean?(_values), do: true

  defp ensure_date(%DateTime{} = value, _convert), do: {:ok, value}
  defp ensure_date(%NaiveDateTime{} = value, _convert) do
    case DateTime.from_naive(value, "Etc/UTC") do
      {:ok, datetime} -> {:ok, datetime}
      {:error, _} -> :error
    end
  end

  defp ensure_date(%Date{} = value, _convert) do
    case DateTime.new(value, ~T[00:00:00], "Etc/UTC") do
      {:ok, datetime} -> {:ok, datetime}
      {:error, _} -> :error
    end
  end

  defp ensure_date(value, true) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        {:ok, datetime}

      {:error, _} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
          {:error, _} -> :error
        end
    end
  end

  defp ensure_date(_value, _convert), do: :error

  defp default_truthy(true), do: @default_truthy
  defp default_truthy(_), do: nil

  defp default_falsy(true), do: @default_falsy
  defp default_falsy(_), do: nil

  defp get_condition_value(data, field) when is_atom(field) do
    Map.get(data, field) || Map.get(data, Atom.to_string(field))
  end

  defp get_condition_value(data, field) when is_binary(field) do
    Map.get(data, field) ||
      case safe_existing_atom(field) do
        nil -> nil
        atom_key -> Map.get(data, atom_key)
      end
  end

  defp safe_existing_atom(value) do
    try do
      String.to_existing_atom(value)
  rescue
      ArgumentError -> nil
    end
  end

  defp condition_met?(_value, nil), do: false

  defp condition_met?(value, checks) do
    check_is(value, checks.is) &&
      check_in(value, checks.in) &&
      check_matches(value, checks.matches) &&
      check_min(value, checks.min) &&
      check_max(value, checks.max)
  end

  defp check_is(_value, nil), do: true
  defp check_is(value, expected), do: value == expected

  defp check_in(_value, nil), do: true
  defp check_in(value, list) when is_list(list), do: Enum.member?(list, value)
  defp check_in(value, %Range{} = range), do: value in range
  defp check_in(_value, _other), do: false

  defp check_matches(_value, nil), do: true
  defp check_matches(value, %Regex{} = regex) when is_binary(value), do: Regex.match?(regex, value)
  defp check_matches(_value, %Regex{}), do: false
  defp check_matches(_value, _), do: true

  defp check_min(_value, nil), do: true
  defp check_min(value, min) when is_number(value), do: value >= min
  defp check_min(_value, _min), do: false

  defp check_max(_value, nil), do: true
  defp check_max(value, max) when is_number(value), do: value <= max
  defp check_max(_value, _max), do: false

  defp error(code, default_message, meta \\ %{}) do
    translator = Config.message_translator()
    message = translator.(code, default_message, meta)
    %{code: code, message: message, meta: meta}
  end

  defp format_errors(errors) do
    flat = flatten_errors(errors)
    result = Config.error_builder().(errors)

    if is_map(result) do
      Map.put_new(result, :errors_flat, flat)
    else
      result
    end
  end

  def default_error_builder(errors) do
    %{
      message: "Validation failed",
      errors: errors,
      errors_flat: flatten_errors(errors)
    }
  end

  defp run_custom_validator({:module, module}, value, rule, context) when is_atom(module) do
    ensure_module_validator!(module)
    module.validate(value, rule, context)
    |> normalize_custom_result(value)
  end

  defp run_custom_validator({:function, fun}, value, rule, context) do
    result =
      case :erlang.fun_info(fun, :arity) do
        {:arity, 1} -> fun.(value)
        {:arity, 2} -> fun.(value, context)
        {:arity, 3} -> fun.(value, rule, context)
        _ -> raise ArgumentError, "Custom validator functions must have arity 1..3"
      end

    normalize_custom_result(result, value)
  end

  defp run_custom_validator(_, _value, _rule, _context) do
    {:error, [error(:custom_type, "invalid custom validator configuration")]}
  end

  defp ensure_module_validator!(module) do
    unless function_exported?(module, :validate, 3) do
      raise ArgumentError,
            "#{inspect(module)} must implement ExJoi.CustomValidator.validate/3"
    end
  end

  defp normalize_custom_result(:ok, value), do: {:ok, value}
  defp normalize_custom_result({:ok, new_value}, _value), do: {:ok, new_value}

  defp normalize_custom_result({:error, errors}, _value) when is_list(errors) do
    {:error, errors}
  end

  defp normalize_custom_result({:error, error}, _value) do
    {:error, List.wrap(error)}
  end

  defp normalize_custom_result(other, value) do
    case other do
      {:ok, new_value} -> {:ok, new_value}
      :ok -> {:ok, value}
      _ -> {:error, [error(:custom_type, "invalid custom validator response")]}
    end
  end

  @doc false
  def flatten_errors(errors) when is_map(errors) do
    Enum.reduce(errors, %{}, fn {key, value}, acc ->
      merge_flat(acc, [key], value)
    end)
  end

  defp merge_flat(acc, path, value) when is_list(value) do
    path_key = path_to_string(path)
    Map.update(acc, path_key, Enum.map(value, & &1.message), fn existing ->
      existing ++ Enum.map(value, & &1.message)
    end)
  end

  defp merge_flat(acc, path, value) when is_map(value) do
    Enum.reduce(value, acc, fn {k, v}, inner_acc ->
      merge_flat(inner_acc, path ++ [k], v)
    end)
  end

  defp merge_flat(acc, _path, _value), do: acc

  defp path_to_string(path_segments) do
    path_segments
    |> Enum.map(&segment_to_string/1)
    |> Enum.join(".")
  end

  defp segment_to_string(segment) when is_atom(segment), do: Atom.to_string(segment)
  defp segment_to_string(segment) when is_integer(segment), do: Integer.to_string(segment)
  defp segment_to_string(segment) when is_binary(segment), do: segment
  defp segment_to_string(other), do: inspect(other)
end
