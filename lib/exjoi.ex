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

  @default_truthy [true, "true", "True", "TRUE", "1", 1, "yes", "Yes", "YES", "on", "On", "ON"]
  @default_falsy [false, "false", "False", "FALSE", "0", 0, "no", "No", "NO", "off", "Off", "OFF"]

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

    * `:required` - Ensures the value is present.
    * `:min` - Minimum string length.
    * `:max` - Maximum string length.
    * `:pattern` - A `Regex` the string must match.
    * `:email` - When true, applies a basic email format check.

  ## Examples

      ExJoi.string()
      ExJoi.string(required: true, min: 3, max: 50)
      ExJoi.string(pattern: ~r/^[A-Z]+$/)
      ExJoi.string(email: true)
  """
  def string(opts \\ []) do
    %Rule{
      type: :string,
      required: Keyword.get(opts, :required, false),
      min: Keyword.get(opts, :min),
      max: Keyword.get(opts, :max),
      pattern: Keyword.get(opts, :pattern),
      email: Keyword.get(opts, :email, false)
    }
  end

  @doc """
  Creates a number validator rule.

  ## Options

    * `:required` - Ensures the value is present.
    * `:min` / `:max` - Numeric bounds (inclusive).
    * `:integer` - When true, only integers are accepted.

  ## Examples

      ExJoi.number()
      ExJoi.number(required: true, min: 18, max: 65)
      ExJoi.number(integer: true)
  """
  def number(opts \\ []) do
    %Rule{
      type: :number,
      required: Keyword.get(opts, :required, false),
      min: Keyword.get(opts, :min),
      max: Keyword.get(opts, :max),
      integer: Keyword.get(opts, :integer, false)
    }
  end

  @doc """
  Creates a boolean validator rule.

  ## Options

    * `:required` - Ensures the value is present.
    * `:truthy` / `:falsy` - Lists of values that should coerce to `true`/`false`.

  The default truthy values are `#{inspect(@default_truthy)}` and falsy values are
  `#{inspect(@default_falsy)}`.

  ## Examples

      ExJoi.boolean()
      ExJoi.boolean(required: true)
      ExJoi.boolean(truthy: ["Y"], falsy: ["N"])
  """
  def boolean(opts \\ []) do
    %Rule{
      type: :boolean,
      required: Keyword.get(opts, :required, false),
      truthy: Keyword.get(opts, :truthy, @default_truthy),
      falsy: Keyword.get(opts, :falsy, @default_falsy)
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
