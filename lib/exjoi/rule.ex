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
    schema: nil
  ]

  @type t :: %__MODULE__{
          type: :string | :number | :boolean | :object,
          required: boolean(),
          min: integer() | float() | nil,
          max: integer() | float() | nil,
          pattern: Regex.t() | nil,
          email: boolean(),
          integer: boolean(),
          truthy: list() | nil,
          falsy: list() | nil,
          schema: ExJoi.Schema.t() | nil
        }
end
