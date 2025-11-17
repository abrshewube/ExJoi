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

  ## Options

    * `:defaults` - A map of default values merged into input data before validation (top-level).

  ## Examples

      schema =
        ExJoi.schema(
          %{
            name: ExJoi.string(required: true),
            active: ExJoi.boolean()
          },
          defaults: %{active: true}
        )
  """
  def schema(fields, opts \\ []) when is_map(fields) do
    defaults = Keyword.get(opts, :defaults, %{})

    %Schema{
      fields: fields,
      defaults: defaults
    }
  end
  @doc """
  Creates a nested object validator. Accepts either a map of field rules
  or an existing `%ExJoi.Schema{}`.

  ## Examples

      ExJoi.object(%{
        profile: ExJoi.string(required: true)
      })

      nested_schema = ExJoi.schema(%{email: ExJoi.string(email: true)})
      ExJoi.object(nested_schema)
  """
  def object(fields_or_schema, opts \\ [])

  def object(%Schema{} = schema, opts) do
    do_object(schema, opts)
  end

  def object(fields, opts) when is_map(fields) do
    fields
    |> schema()
    |> do_object(opts)
  end

  defp do_object(schema, opts) do
    %Rule{
      type: :object,
      required: Keyword.get(opts, :required, false),
      schema: schema
    }
  end

  @doc """
  Creates an array validator rule.

  ## Options

    * `:required` - Ensures the array is present.
    * `:of` - A rule applied to each element (e.g. `ExJoi.string(min: 3)`).
    * `:min_items` / `:max_items` (`:min` / `:max` aliases) - Length constraints.
    * `:unique` - When true, all elements must be unique.
    * `:delimiter` - String delimiter used to coerce binaries into lists (default: `","`).

  ## Examples

      ExJoi.array(of: ExJoi.string(min: 3), min_items: 1)
      ExJoi.array(of: ExJoi.number(integer: true), unique: true)
      ExJoi.array(delimiter: "|")
  """
  def array(opts \\ []) do
    %Rule{
      type: :array,
      required: Keyword.get(opts, :required, false),
      of: Keyword.get(opts, :of),
      min_items: Keyword.get(opts, :min_items) || Keyword.get(opts, :min),
      max_items: Keyword.get(opts, :max_items) || Keyword.get(opts, :max),
      unique: Keyword.get(opts, :unique, false),
      delimiter: Keyword.get(opts, :delimiter, ",")
    }
  end

  @doc """
  Creates a date validator rule.

  ## Options

    * `:required` - Ensures the value is present.

  Values are returned as `DateTime` structs when parsing succeeds.
  """
  def date(opts \\ []) do
    %Rule{
      type: :date,
      required: Keyword.get(opts, :required, false)
    }
  end

  @doc """
  Creates a conditional rule that switches validation based on another field.

  ## Options

    * `:is` - Matches when the other field equals the given value.
    * `:in` - Matches when the other field is within the provided list.
    * `:matches` - Matches when the other field satisfies the provided `Regex`.
    * `:min` / `:max` - Matches when the numeric value falls within the inclusive range.
    * `:then` - **Required.** Rule applied when the condition matches.
    * `:otherwise` - Optional fallback rule when the condition does not match.
    * `:required` - Whether the field itself is required regardless of conditions.

  The third argument `default_rule` (optional) provides a base rule that is used
  when no `:otherwise` rule is provided.
  """
  def unquote(:when)(other_field, condition_opts, default_rule \\ nil) do
    then_rule = Keyword.fetch!(condition_opts, :then)

    checks = %{
      is: Keyword.get(condition_opts, :is),
      in: Keyword.get(condition_opts, :in),
      matches: Keyword.get(condition_opts, :matches),
      min: Keyword.get(condition_opts, :min),
      max: Keyword.get(condition_opts, :max)
    }

    unless Enum.any?(checks, fn {_k, v} -> not is_nil(v) end) do
      raise ArgumentError, "ExJoi.when/3 requires at least one condition (:is/:in/:matches/:min/:max)"
    end

    %Rule{
      type: :conditional,
      required: Keyword.get(condition_opts, :required, false),
      conditional: %{
        field: other_field,
        checks: checks,
        then: then_rule,
        otherwise: Keyword.get(condition_opts, :otherwise, default_rule),
        base: default_rule
      }
    }
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
      truthy: Keyword.get(opts, :truthy),
      falsy: Keyword.get(opts, :falsy)
    }
  end

  @doc """
  Validates data against a schema.

  Returns `{:ok, validated_data}` if validation passes, or `{:error, errors}` if it fails.
  Accepts optional `opts`, currently supporting `:convert` (default: `false`)
  to enable type coercion/casting behavior.

  ## Examples

      schema = ExJoi.schema(%{name: ExJoi.string(required: true)})
      ExJoi.validate(%{name: "John"}, schema)
      # => {:ok, %{name: "John"}}

      ExJoi.validate(%{}, schema)
      # => {:error, %{name: ["is required"]}}
  """
  def validate(data, %Schema{} = schema, opts \\ []) do
    Validator.validate(data, schema, opts)
  end
end
