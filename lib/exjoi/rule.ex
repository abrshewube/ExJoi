defmodule ExJoi.Rule do
  @moduledoc """
  Represents a validation rule for a single field.

  ## Fields

    * `:type` - The expected type (`:string`, `:number`, `:boolean`)
    * `:required` - Whether the field is required (default: false)
  """

  defstruct [
    :type,
    required: false,
    min: nil,
    max: nil,
    pattern: nil,
    email: false,
    integer: false,
    truthy: nil,
    falsy: nil,
    schema: nil,
    of: nil,
    min_items: nil,
    max_items: nil,
    unique: false,
    delimiter: ",",
    conditional: nil,
    custom_opts: [],
    async: nil,
    timeout: nil
  ]

  @type t :: %__MODULE__{
          type: :string | :number | :boolean | :object | :array | :date | :conditional | {:custom, atom()},
          required: boolean(),
          min: integer() | float() | nil,
          max: integer() | float() | nil,
          pattern: Regex.t() | nil,
          email: boolean(),
          integer: boolean(),
          truthy: list() | nil,
          falsy: list() | nil,
          schema: ExJoi.Schema.t() | nil,
          of: __MODULE__.t() | nil,
          min_items: non_neg_integer() | nil,
          max_items: non_neg_integer() | nil,
          unique: boolean(),
          delimiter: String.t() | nil,
          conditional: map() | nil,
          custom_opts: keyword(),
          async: (any(), map() -> {:ok, any()} | {:error, [map()]} | Task.t()) | nil,
          timeout: non_neg_integer() | nil
        }
end
