defmodule ExJoi.Config do
  @moduledoc false

  @config_key {:exjoi, :config}

  @default %{
    custom_types: %{},
    error_builder: &__MODULE__.default_error_builder/1
  }

  def get do
    :persistent_term.get(@config_key, @default)
  end

  def register_type(name, validator) when is_atom(name) do
    update(fn config ->
      normalized =
        cond do
          is_function(validator) ->
            {:function, validator}

          is_atom(validator) ->
            {:module, validator}

          match?({module, _} when is_atom(module), validator) ->
            {:module, elem(validator, 0)}

          true ->
            raise ArgumentError, "Unsupported validator type for #{inspect(name)}"
        end

      put_in(config, [:custom_types, name], normalized)
    end)
  end

  def fetch_type(name) do
    Map.get(get().custom_types, name)
  end

  def set_error_builder(fun) when is_function(fun, 1) do
    update(&Map.put(&1, :error_builder, fun))
  end

  def error_builder do
    get().error_builder
  end

  def reset! do
    :persistent_term.put(@config_key, @default)
    :ok
  end

  def default_error_builder(errors) do
    %{
      message: "Validation failed",
      errors: errors
    }
  end

  defp update(fun) do
    :persistent_term.put(@config_key, fun.(get()))
    :ok
  end
end
