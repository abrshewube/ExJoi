
defmodule ExJoi.Schema do
  @moduledoc """
  Represents a validation schema containing multiple field rules.

  ## Fields

    * `:fields` - A map where keys are field names (atoms or strings) and values are `ExJoi.Rule` structs
  """

  defstruct [
    :fields
  ]

  @type t :: %__MODULE__{
          fields: %{(atom() | String.t()) => ExJoi.Rule.t()}
        }
end
