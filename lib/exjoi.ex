defmodule ExJoi do
  @moduledoc """
  ExJoi - A Joi-inspired validation library for Elixir.

  Provides declarative, schema-based data validation with a clean DSL.

  ## Basic Usage

      schema = ExJoi.schema(%{
        name: ExJoi.string(required: true),
        age: ExJoi.number()
      })

      ExJoi.validate(%{name: "John", age: 30}, schema)
      # => {:ok, %{name: "John", age: 30}}

      ExJoi.validate(%{age: 30}, schema)
      # => {:error, %{name: ["is required"]}}
  """

  alias ExJoi.{Rule, Schema, Validator}

  @doc """
  Creates a validation schema from a map of field rules.

  ## Examples

      schema = ExJoi.schema(%{
        name: ExJoi.string(required: true),
        age: ExJoi.number()
      })
  """
  def schema(fields) when is_map(fields) do
    %Schema{fields: fields}
  end

  @doc """
  Creates a string validator rule.

  ## Options

    * `:required` - If true, the field must be present (default: false)

  ## Examples

      ExJoi.string()
      ExJoi.string(required: true)
  """
  def string(opts \\ []) do
    %Rule{
      type: :string,
      required: Keyword.get(opts, :required, false)
    }
  end

  @doc """
  Creates a number validator rule.

  ## Options

    * `:required` - If true, the field must be present (default: false)

  ## Examples

      ExJoi.number()
      ExJoi.number(required: true)
  """
  def number(opts \\ []) do
    %Rule{
      type: :number,
      required: Keyword.get(opts, :required, false)
    }
  end

  @doc """
  Creates a boolean validator rule.

  ## Options

    * `:required` - If true, the field must be present (default: false)

  ## Examples

      ExJoi.boolean()
      ExJoi.boolean(required: true)
  """
  def boolean(opts \\ []) do
    %Rule{
      type: :boolean,
      required: Keyword.get(opts, :required, false)
    }
  end

  @doc """
  Validates data against a schema.

  Returns `{:ok, validated_data}` if validation passes, or `{:error, errors}` if it fails.

  ## Examples

      schema = ExJoi.schema(%{name: ExJoi.string(required: true)})
      ExJoi.validate(%{name: "John"}, schema)
      # => {:ok, %{name: "John"}}

      ExJoi.validate(%{}, schema)
      # => {:error, %{name: ["is required"]}}
  """
  def validate(data, %Schema{} = schema) do
    Validator.validate(data, schema)
  end
end
