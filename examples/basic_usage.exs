# Basic ExJoi Usage Examples

alias ExJoi

# Example 1: Simple schema with required field
schema1 = ExJoi.schema(%{
  name: ExJoi.string(required: true),
  age: ExJoi.number()
})

# Valid data
IO.inspect(ExJoi.validate(%{name: "John", age: 30}, schema1))
# => {:ok, %{name: "John", age: 30}}

# Missing required field
IO.inspect(ExJoi.validate(%{age: 30}, schema1))
# => {:error, %{name: ["is required"]}}

# Type mismatch
IO.inspect(ExJoi.validate(%{name: "John", age: "thirty"}, schema1))
# => {:error, %{age: ["must be a number"]}}

# Example 2: Multiple field types
schema2 = ExJoi.schema(%{
  name: ExJoi.string(required: true),
  age: ExJoi.number(required: true),
  active: ExJoi.boolean()
})

# All valid
IO.inspect(ExJoi.validate(%{name: "Jane", age: 25, active: true}, schema2))
# => {:ok, %{name: "Jane", age: 25, active: true}}

# Multiple errors
IO.inspect(ExJoi.validate(%{name: 123, age: "old"}, schema2))
# => {:error, %{name: ["must be a string"], age: ["must be a number"]}}
