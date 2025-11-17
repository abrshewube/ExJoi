defmodule ExJoi.Rule do
  @moduledoc """
  Represents a validation rule for a single field.

  ## Fields

    * `:type` - The expected type (`:string`, `:number`, `:boolean`)
    * `:required` - Whether the field is required (default: false)
  """

  defstruct [
    :type,
    required: false
  ]

  @type t :: %__MODULE__{
          type: :string | :number | :boolean,
          required: boolean()
        }
end
