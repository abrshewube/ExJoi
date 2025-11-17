defmodule ExJoi.CustomValidator do
  @moduledoc """
  Behaviour for implementing custom ExJoi validators.

  Implementations receive the value being validated, the rule struct, and a
  context map that includes the current data payload and whether conversion is enabled.
  """

  @type context :: %{
          convert: boolean(),
          data: map()
        }

  @callback validate(value :: any(), rule :: ExJoi.Rule.t(), context :: context()) ::
              :ok
              | {:ok, any()}
              | {:error, [ExJoi.Validator.error()]}
end
