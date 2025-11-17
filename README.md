# ExJoi

**Beautiful, declarative validation for Elixir**

ExJoi brings a Joi-inspired DSL to Elixir, letting you describe data rules once and trust the engine to enforce them everywhere—APIs, configs, forms, and beyond.

---

## Quick Links

- GitHub · https://github.com/abrshewube/ExJoi
- HexDocs (v0.2.0) · https://hexdocs.pm/exjoi/0.2.0
- Hex Package · https://hex.pm/packages/exjoi

---

## Highlights

- **Schema-first DSL** – Compose readable validation rules with `ExJoi.string/1`, `number/1`, and `boolean/1`.
- **Advanced constraints** – Min/max lengths, regex patterns, email format checks, integer guards, and truthy/falsy coercion.
- **Actionable errors** – Structured responses include machine-friendly codes, friendly messages, and metadata.
- **Key-flexible** – Accepts atom or string keys seamlessly.
- **Roadmap-driven** – Clear multi-version plan culminating in macro DSL optimizations.

---

## Install

Add the dependency and you’re ready to validate:

```elixir
defp deps do
  [
    {:exjoi, "~> 0.2.0"}
  ]
end
```

---

## 60‑Second Tour

```elixir
schema =
  ExJoi.schema(%{
    name: ExJoi.string(required: true, min: 2, max: 50),
    email: ExJoi.string(email: true),
    age: ExJoi.number(required: true, min: 18, max: 120, integer: true),
    active: ExJoi.boolean(truthy: ["Y", "yes"], falsy: ["N", "no"])
  })

case ExJoi.validate(%{"name" => "Maya", "age" => 28, "active" => "Y"}, schema) do
  {:ok, normalized} ->
    IO.inspect(normalized)

  {:error, %{message: msg, errors: errors}} ->
    IO.inspect({msg, errors})
end

# {:ok, %{"name" => "Maya", "age" => 28, "active" => true}}
```

---

## Constraint Cheat Sheet

| Helper        | Options                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------- |
| `ExJoi.string`  | `:required`, `:min`, `:max`, `:pattern` (`Regex`), `:email`                                 |
| `ExJoi.number`  | `:required`, `:min`, `:max`, `:integer`                                                     |
| `ExJoi.boolean` | `:required`, `:truthy`, `:falsy` (lists coerced to `true` / `false`)                        |

```elixir
ExJoi.string(required: true, min: 3, max: 32, pattern: ~r/^[a-z0-9_]+$/)
ExJoi.number(integer: true, min: 1)
ExJoi.boolean(truthy: ["1", "on"], falsy: ["0", "off"])
```

---

## Rich Error Format

Validation failures always follow the same envelope:

```elixir
{:error,
 %{
   message: "Validation failed",
   errors: %{
     name: [
       %{code: :required, message: "is required"}
     ],
     age: [
       %{code: :number_min, message: "must be greater than or equal to 18", meta: %{min: 18}}
     ]
   }
 }}
```

Each error entry includes:

- `code` – Atom identifier (`:required`, `:string_pattern`, `:boolean`, ...).
- `message` – Friendly sentence ready for users.
- `meta` – Optional context (`%{min: 18}`, `%{pattern: ...}`) for UI or logging.

---

## Recipes

### Validate credentials

```elixir
ExJoi.schema(%{
  username: ExJoi.string(required: true, min: 4, max: 32, pattern: ~r/^[a-z0-9_]+$/i),
  password: ExJoi.string(required: true, min: 8)
})
```

### Enforce price & quantity

```elixir
ExJoi.schema(%{
  price: ExJoi.number(required: true, min: 0),
  quantity: ExJoi.number(required: true, min: 1, max: 100, integer: true)
})
```

### Custom truthy/falsy

```elixir
ExJoi.schema(%{
  subscribed: ExJoi.boolean(truthy: ["Y", "yes"], falsy: ["N", "no"])
})
```

---

## Roadmap Snapshot

| Version | Status  | Highlights |
| ------- | ------- | ---------- |
| 2       | Current | Advanced constraints, truthy/falsy coercion, structured errors |
| 3       | Next    | Nested object schemas |
| 4       | Planned | Array validation |
| 5       | Planned | Type coercion / casting |
| 6       | Planned | Conditional rules |
| 7       | Planned | Custom validators & plugin system |
| 8       | Planned | Full error tree & custom error builder |
| 9       | Planned | Async / parallel validation |
| 10      | Planned | Macro DSL, compiler, performance optimizations |

Version 1 delivered the foundational engine with basic types and required flags.

---

## Contributing

1. Fork and create a topical branch (e.g. `version-3-nested-schemas`).
2. Run `mix test` before opening a PR.
3. Document new DSL additions in the README / HexDocs.

---

## License

MIT © 2025 abrshewube — build wonderful validations!

