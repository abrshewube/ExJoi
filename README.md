# ExJoi

**Beautiful, declarative validation for Elixir**

ExJoi brings a Joi-inspired DSL to Elixir, letting you describe data rules once and trust the engine to enforce them everywhere—APIs, configs, forms, and beyond.

---

## Quick Links

<p align="left">
  <a href="https://github.com/abrshewube/ExJoi">🔗 GitHub</a> •
  <a href="https://hexdocs.pm/exjoi/0.9.0">📚 HexDocs (v0.9.0)</a> •
  <a href="https://ex-joi.vercel.app/">🌐 Live Documentation</a> •
  <a href="https://hex.pm/packages/exjoi">📦 Hex Package</a>
</p>

---

## Highlights

- **Schema-first DSL** – Compose readable validation rules with `ExJoi.string/1`, `number/1`, `boolean/1`, `object/1`, `array/1`, `date/1`, `when/3`, `custom/2`, and `async/2`.
- **Advanced constraints** – Min/max lengths, regex patterns, email format checks, integer guards, truthy/falsy coercion, and per-item array validation.
- **Convert mode** – Toggle `convert: true` to coerce numbers, booleans, dates, strings, and arrays like Joi's "convert" flow.
- **Async validation** – Use `ExJoi.async/2` for external service checks, database lookups, and parallel validation with timeout control.
- **Conditional rules** – Use `ExJoi.when/3` to change requirements based on other fields, value ranges, or regex matches.
- **Nested objects & arrays** – Recursively validate deep maps and lists with rich, nested error payloads.
- **Smart defaults** – Provide top-level defaults that merge into incoming params before validation.
- **Actionable errors** – Structured responses include machine-friendly codes, friendly messages, a flattened error tree, and metadata.
- **Key-flexible** – Accepts atom or string keys seamlessly, with string-to-array coercion via delimiters.

---

## Install

Add the dependency and you’re ready to validate:

```elixir
defp deps do
  [
    {:exjoi, "~> 0.9.0"}
  ]
end
```

---

## 60‑Second Tour

```elixir
schema =
  ExJoi.schema(
    %{
      role: ExJoi.string(required: true),
      user:
        ExJoi.object(%{
          name: ExJoi.string(required: true, min: 2, max: 50),
          email: ExJoi.string(required: true, email: true)
        }),
      stats: ExJoi.number(integer: true, min: 0),
      friends: ExJoi.array(of: ExJoi.string(min: 3), min_items: 1, unique: true),
      active: ExJoi.boolean(),
      onboarded_at: ExJoi.date(required: true),
      permissions:
        ExJoi.when(
          :role,
          is: "admin",
          then: ExJoi.array(of: ExJoi.string(), min_items: 1, required: true),
          otherwise: ExJoi.array(of: ExJoi.string())
        )
    },
    defaults: %{active: true, stats: 0}
  )

params = %{
  "role" => "admin",
  "user" => %{"name" => "Maya", "email" => "maya@example.com"},
  "friends" => "Ana,Bea,Clara",
  "active" => "false",
  "stats" => "42",
  "onboarded_at" => "2025-01-01T12:30:00Z"
}

case ExJoi.validate(params, schema, convert: true) do
  {:ok, normalized} ->
    IO.inspect(normalized)

  {:error, %{message: msg, errors: errors}} ->
    IO.inspect({msg, errors})
end

# {:ok,
#  %{
#    "active" => false,
#    "friends" => ["Ana", "Bea", "Clara"],
#    "onboarded_at" => ~U[2025-01-01 12:30:00Z],
#    "stats" => 42,
#    "user" => %{"email" => "maya@example.com", "name" => "Maya"}
#  }}
```

## Custom Validators & Extensions

```elixir
# Register a custom type
ExJoi.extend(:uuid, fn value, _ctx ->
  case Regex.match?(~r/^[0-9a-f-]{32}$/i, value) do
    true -> {:ok, String.downcase(value)}
    false -> {:error, [%{code: :uuid, message: "must be a UUID"}]}
  end
end)

# Use it inside schemas
schema =
  ExJoi.schema(%{
    id: ExJoi.custom(:uuid, required: true)
  })
```

- Provide a module instead of a function by implementing `ExJoi.CustomValidator`.
- Override the error payload globally: `ExJoi.configure(error_builder: &MyErrors.format/1)`.
- Reset extensions (e.g., in tests) with `ExJoi.Config.reset!()`.

---

## Constraint Cheat Sheet

| Helper        | Options                                                                                     |
| ------------- | ------------------------------------------------------------------------------------------- |
| `ExJoi.string`  | `:required`, `:min`, `:max`, `:pattern` (`Regex`), `:email`                                 |
| `ExJoi.number`  | `:required`, `:min`, `:max`, `:integer`                                                     |
| `ExJoi.boolean` | `:required`, `:truthy`, `:falsy` (lists coerced to `true` / `false`)                        |
| `ExJoi.object`  | `:required` (accepts nested map or `%ExJoi.Schema{}`)                                       |
| `ExJoi.array`   | `:required`, `:of`, `:min_items`/`:max_items` (aliases `:min`/`:max`), `:unique`, `:delimiter` |
| `ExJoi.date`    | `:required`                                                                                 |
| `ExJoi.when`    | `:is`, `:in`, `:matches`, `:min`, `:max`, `:then` (required), `:otherwise`, `:required`     |
| `ExJoi.async`   | Wraps any rule with async validation function, `:timeout` (milliseconds, default: 5000). Async function receives `(value, context)` and returns `{:ok, value}`, `{:error, [errors]}`, or `%Task{}` |

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

### Nested user profile

```elixir
ExJoi.schema(%{
  user:
    ExJoi.object(%{
      email: ExJoi.string(required: true, email: true),
      profile: ExJoi.object(%{bio: ExJoi.string(max: 140)})
    })
})
```

### Friends array with coercion

```elixir
ExJoi.schema(%{
  friends: ExJoi.array(of: ExJoi.string(min: 3), min_items: 1, unique: true, delimiter: ";")
})
```

### Convert mode for params

```elixir
schema =
  ExJoi.schema(%{
    age: ExJoi.number(min: 18),
    active: ExJoi.boolean(),
    onboarded_at: ExJoi.date()
  })

params = %{"age" => "42", "active" => "true", "onboarded_at" => "2025-01-01T00:00:00Z"}

ExJoi.validate(params, schema, convert: true)
```

When `convert: false` (default), `"42"` and `"true"` would raise type errors.

### Error tree & translations

Every failure now includes a flattened, path-based structure (`errors_flat`) alongside the nested error map. Plug a translator for localized copy.

```elixir
{:error,
 %{
   errors_flat: %{
     "user.email" => ["must be a valid email"],
     "permissions.0" => ["must be at least 3 characters"]
   }
}}
```

```elixir
ExJoi.configure(
  message_translator: fn
    :required, _default, _meta -> "es requerido"
    _code, default, _meta -> default
  end
)
```

### Conditional permissions

```elixir
schema =
  ExJoi.schema(%{
    role: ExJoi.string(required: true),
    permissions:
      ExJoi.when(
        :role,
        is: "admin",
        then: ExJoi.array(of: ExJoi.string(), min_items: 1, required: true),
        otherwise: ExJoi.array(of: ExJoi.string())
      )
  })
```

### Custom UUID type

```elixir
ExJoi.extend(:uuid, MyApp.UUIDValidator)

ExJoi.schema(%{
  session_id: ExJoi.custom(:uuid, required: true)
})
```

### Async validation with external service

```elixir
schema = ExJoi.schema(%{
  username: ExJoi.async(
    ExJoi.string(required: true, min: 3),
    fn value, _ctx ->
      Task.async(fn ->
        # Check username availability
        if UsernameService.available?(value) do
          {:ok, String.downcase(value)}
        else
          {:error, [%{code: :username_taken, message: "username is already taken"}]}
        end
      end)
    end,
    timeout: 3000
  )
})

ExJoi.validate(%{username: "john"}, schema)
```

### Parallel array validation

```elixir
schema = ExJoi.schema(%{
  emails: ExJoi.array(
    of: ExJoi.async(
      ExJoi.string(email: true),
      fn value, _ctx ->
        Task.async(fn ->
          # Verify email with external service
          EmailService.verify_async(value)
        end)
      end
    ),
    min_items: 1
  )
})

# All emails validated in parallel
ExJoi.validate(%{emails: ["test@example.com", "user@domain.com"]}, schema)
```

---

## Roadmap Snapshot

| Version | Status  | Highlights |
| ------- | ------- | ---------- |
| 9       | Current | Async validation with `Task.async_stream`, external service checks, timeout control, parallel array validation |
| 8       | Shipped | Path-based error tree, message translator, enhanced error builder |
| 7       | Shipped | Custom validators/plugins, `ExJoi.extend/2`, error builder overrides |
| 6       | Shipped | Conditional rules (`ExJoi.when/3`) with field/value/range/regex checks |
| 5       | Shipped | Convert mode (numbers, booleans, dates, strings), ISO date type |
| 4       | Shipped | Array validation (min/max, unique, delimiter coercion, per-item rules) |
| 3       | Shipped | Object schemas, nested validation, defaulting |
| 2       | Shipped | Advanced constraints, truthy/falsy coercion, structured errors |
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

