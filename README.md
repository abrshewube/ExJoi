# ExJoi

A Joi-inspired validation library for Elixir.

ExJoi brings declarative, schema-based data validation to Elixir with an expressive DSL.

## Installation

Add `exjoi` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exjoi, "~> 0.1.0"}
  ]
end
```

## Basic Usage

```elixir
# Define a schema
schema = ExJoi.schema(%{
  name: ExJoi.string(required: true),
  age: ExJoi.number()
})

# Validate data
ExJoi.validate(%{name: "John", age: 30}, schema)
# => {:ok, %{name: "John", age: 30}}

# Missing required field
ExJoi.validate(%{age: 30}, schema)
# => {:error, %{name: ["is required"]}}

# Type validation
ExJoi.validate(%{name: "John", age: "thirty"}, schema)
# => {:error, %{age: ["must be a number"]}}
```

## Built-in Validators

### String

```elixir
ExJoi.string()
ExJoi.string(required: true)
```

### Number

```elixir
ExJoi.number()
ExJoi.number(required: true)
```

### Boolean

```elixir
ExJoi.boolean()
ExJoi.boolean(required: true)
```

## Error Format

When validation fails, ExJoi returns an error map where keys are field names and values are lists of error messages:

```elixir
{:error, %{
  name: ["is required"],
  age: ["must be a number"]
}}
```

## Roadmap

ExJoi is being developed in 10 versions:

- **Version 1** (Current): Basic types, required fields, validation engine
- **Version 2**: Advanced constraints (min, max, pattern, email)
- **Version 3**: Nested object schemas
- **Version 4**: Array validation
- **Version 5**: Type coercion/casting
- **Version 6**: Conditional rules
- **Version 7**: Custom validators & plugin system
- **Version 8**: Full error tree & custom error builder
- **Version 9**: Async/parallel validation
- **Version 10**: Macro DSL, compiler, performance optimizations

## License

MIT

