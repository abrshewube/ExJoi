defmodule ExJoiTest do
  use ExUnit.Case
  doctest ExJoi

  setup do
    ExJoi.Config.reset!()
    :ok
  end

  describe "basic validation" do
    test "validates string field" do
      schema = ExJoi.schema(%{
        name: ExJoi.string()
      })

      assert ExJoi.validate(%{name: "John"}, schema) == {:ok, %{name: "John"}}
      assert ExJoi.validate(%{}, schema) == {:ok, %{}}
    end

    test "validates required string field" do
      schema = ExJoi.schema(%{
        name: ExJoi.string(required: true)
      })

      assert ExJoi.validate(%{name: "John"}, schema) == {:ok, %{name: "John"}}
      assert {:error, %{errors: errors, message: "Validation failed"}} = ExJoi.validate(%{}, schema)
      assert [%{code: :required, message: "is required"}] = errors.name
    end

    test "validates number field" do
      schema = ExJoi.schema(%{
        age: ExJoi.number()
      })

      assert ExJoi.validate(%{age: 30}, schema) == {:ok, %{age: 30}}
      assert ExJoi.validate(%{age: 30.5}, schema) == {:ok, %{age: 30.5}}
    end

    test "validates required number field" do
      schema = ExJoi.schema(%{
        age: ExJoi.number(required: true)
      })

      assert ExJoi.validate(%{age: 30}, schema) == {:ok, %{age: 30}}
      assert {:error, %{errors: errors}} = ExJoi.validate(%{}, schema)
      assert [%{code: :required, message: "is required"}] = errors.age
    end

    test "validates boolean field" do
      schema = ExJoi.schema(%{
        active: ExJoi.boolean()
      })

      assert ExJoi.validate(%{active: true}, schema) == {:ok, %{active: true}}
      assert ExJoi.validate(%{active: false}, schema) == {:ok, %{active: false}}
    end

    test "validates required boolean field" do
      schema = ExJoi.schema(%{
        active: ExJoi.boolean(required: true)
      })

      assert ExJoi.validate(%{active: true}, schema) == {:ok, %{active: true}}
      assert {:error, %{errors: errors}} = ExJoi.validate(%{}, schema)
      assert [%{code: :required, message: "is required"}] = errors.active
    end

    test "validates type mismatches" do
      schema = ExJoi.schema(%{
        name: ExJoi.string(),
        age: ExJoi.number(),
        active: ExJoi.boolean()
      })

      assert {:error, %{errors: errors}} = ExJoi.validate(%{name: 123}, schema)
      assert [%{code: :string, message: "must be a string"}] = errors.name

      assert {:error, %{errors: errors}} = ExJoi.validate(%{age: "thirty"}, schema)
      assert [%{code: :number, message: "must be a number"}] = errors.age

      assert {:error, %{errors: errors}} = ExJoi.validate(%{active: "maybe"}, schema)
      assert [%{code: :boolean, message: "must be a boolean"}] = errors.active
    end

    test "validates multiple fields" do
      schema = ExJoi.schema(%{
        name: ExJoi.string(required: true),
        age: ExJoi.number(required: true),
        active: ExJoi.boolean()
      })

      assert ExJoi.validate(%{name: "John", age: 30, active: true}, schema) ==
               {:ok, %{name: "John", age: 30, active: true}}

      assert {:error, %{errors: errors}} = ExJoi.validate(%{name: "John"}, schema)
      assert [%{code: :required, message: "is required"}] = errors.age
    end

    test "handles string keys in schema" do
      schema = ExJoi.schema(%{
        "name" => ExJoi.string(required: true)
      })

      assert ExJoi.validate(%{"name" => "John"}, schema) == {:ok, %{"name" => "John"}}
      assert {:error, %{errors: errors}} = ExJoi.validate(%{}, schema)
      assert Map.has_key?(errors, "name")
    end

    test "applies string constraints" do
      schema =
        ExJoi.schema(%{
          username: ExJoi.string(min: 3, max: 5, pattern: ~r/^[a-z]+$/, required: true),
          email: ExJoi.string(email: true)
        })

      assert {:error, %{errors: errors}} = ExJoi.validate(%{username: "A", email: "invalid"}, schema)
      assert Enum.any?(errors.username, &(&1.code == :string_min))
      assert Enum.any?(errors.username, &(&1.code == :string_pattern))
      assert [%{code: :string_email}] = errors.email

      assert {:ok, %{username: "alex", email: "alex@example.com"}} =
               ExJoi.validate(%{username: "alex", email: "alex@example.com"}, schema)
    end

    test "applies number constraints" do
      schema =
        ExJoi.schema(%{
          age: ExJoi.number(min: 18, max: 65, integer: true)
        })

      assert {:error, %{errors: errors}} = ExJoi.validate(%{age: 10}, schema)
      assert Enum.any?(errors.age, &(&1.code == :number_min))

      assert {:error, %{errors: errors}} = ExJoi.validate(%{age: 70}, schema)
      assert Enum.any?(errors.age, &(&1.code == :number_max))

      assert {:error, %{errors: errors}} = ExJoi.validate(%{age: 20.5}, schema)
      assert [%{code: :number_integer}] = errors.age

      assert {:ok, %{age: 30}} = ExJoi.validate(%{age: 30}, schema)
    end

    test "coerces boolean values using truthy/falsy lists" do
      schema =
        ExJoi.schema(%{
          active: ExJoi.boolean(truthy: ["Y"], falsy: ["N"])
        })

      assert {:ok, %{"active" => true}} = ExJoi.validate(%{"active" => "Y"}, schema)
      assert {:ok, %{"active" => false}} = ExJoi.validate(%{"active" => "N"}, schema)
      assert {:error, %{errors: errors}} = ExJoi.validate(%{active: "maybe"}, schema)
      assert [%{code: :boolean}] = errors.active
    end

    test "validates nested object schemas" do
      schema =
        ExJoi.schema(%{
          user:
            ExJoi.object(%{
              email: ExJoi.string(required: true, email: true),
              profile: ExJoi.object(%{bio: ExJoi.string(max: 5)})
            })
        })

      assert {:ok, %{user: %{email: "alex@example.com", profile: %{bio: "short"}}}} =
               ExJoi.validate(
                 %{user: %{email: "alex@example.com", profile: %{bio: "short"}}},
                 schema
               )

      assert {:error, %{errors: errors}} =
               ExJoi.validate(%{user: %{email: "bad", profile: %{bio: "too long"}}}, schema)

      assert [%{code: :string_email}] = errors.user.email
      assert [%{code: :string_max}] = errors.user.profile.bio
    end

    test "allows object schemas defined separately" do
      profile_schema =
        ExJoi.schema(%{
          bio: ExJoi.string(max: 160)
        })

      schema =
        ExJoi.schema(%{
          profile: ExJoi.object(profile_schema)
        })

      assert {:ok, %{profile: %{bio: "hello"}}} =
               ExJoi.validate(%{profile: %{bio: "hello"}}, schema)
    end

    test "applies top-level defaults" do
      schema =
        ExJoi.schema(
          %{
            active: ExJoi.boolean(),
            settings: ExJoi.object(%{timezone: ExJoi.string(required: true)})
          },
          defaults: %{
            active: true,
            settings: %{timezone: "UTC"}
          }
        )

      assert {:ok, %{active: true, settings: %{timezone: "UTC"}}} = ExJoi.validate(%{}, schema)
      assert {:ok, %{active: false, settings: %{timezone: "UTC"}}} =
               ExJoi.validate(%{active: false}, schema)
    end

    test "validates array fields with constraints" do
      schema =
        ExJoi.schema(%{
          tags: ExJoi.array(of: ExJoi.string(min: 3), min_items: 1, max_items: 3, unique: true)
        })

      assert {:ok, %{tags: ["one", "two"]}} = ExJoi.validate(%{tags: ["one", "two"]}, schema)

      assert {:error, %{errors: errors}} = ExJoi.validate(%{tags: []}, schema)
      assert Enum.any?(errors.tags, &(&1.code == :array_min_items))

      assert {:error, %{errors: errors}} = ExJoi.validate(%{tags: ["one", "two", "three", "four"]}, schema)
      assert Enum.any?(errors.tags, &(&1.code == :array_max_items))

      assert {:error, %{errors: errors}} = ExJoi.validate(%{tags: ["dup", "dup"]}, schema)
      assert Enum.any?(errors.tags, &(&1.code == :array_unique))

      assert {:error, %{errors: errors}} = ExJoi.validate(%{tags: ["ok", "no"]}, schema)
      assert [%{code: :string_min}] = errors.tags[0]
    end

    test "coerces delimited strings into arrays before validation" do
      schema =
        ExJoi.schema(%{
          friends: ExJoi.array(of: ExJoi.string(min: 3), delimiter: ";")
        })

      assert {:ok, %{friends: ["Ana", "Bea", "Clara"]}} =
               ExJoi.validate(%{friends: "Ana; Bea ; Clara"}, schema)

      assert {:error, %{errors: errors}} = ExJoi.validate(%{friends: "Ana;Li"}, schema)
      assert [%{code: :string_min}] = errors.friends[1]
    end

    test "number conversion requires convert option" do
      schema = ExJoi.schema(%{age: ExJoi.number()})

      assert {:error, %{errors: errors}} = ExJoi.validate(%{age: "42"}, schema)
      assert [%{code: :number}] = errors.age

      assert {:ok, %{age: 42}} = ExJoi.validate(%{age: "42"}, schema, convert: true)
      assert {:ok, %{age: 3.14}} = ExJoi.validate(%{age: "3.14"}, schema, convert: true)
    end

    test "boolean convert mode handles default truthy/falsy lists" do
      schema = ExJoi.schema(%{active: ExJoi.boolean()})

      assert {:error, %{errors: errors}} = ExJoi.validate(%{active: "true"}, schema)
      assert [%{code: :boolean}] = errors.active

      assert {:ok, %{active: true}} = ExJoi.validate(%{active: "true"}, schema, convert: true)
      assert {:ok, %{active: false}} = ExJoi.validate(%{active: "false"}, schema, convert: true)
    end

    test "string normalization trims and squishes whitespace in convert mode" do
      schema = ExJoi.schema(%{name: ExJoi.string()})

      assert {:ok, %{name: "  padded  "}} = ExJoi.validate(%{name: "  padded  "}, schema)

      assert {:ok, %{name: "padded text"}} =
               ExJoi.validate(%{name: "  padded   text  "}, schema, convert: true)
    end

    test "date validation parses ISO8601 strings when convert enabled" do
      schema = ExJoi.schema(%{start_at: ExJoi.date(required: true)})

      assert {:error, %{errors: errors}} = ExJoi.validate(%{start_at: "2025-01-01T00:00:00Z"}, schema)
      assert [%{code: :date}] = errors.start_at

      assert {:ok, %{start_at: %DateTime{}}} =
               ExJoi.validate(%{start_at: "2025-01-01T00:00:00Z"}, schema, convert: true)
    end

    test "conditional rule enforces admin permissions" do
      schema =
        ExJoi.schema(%{
          role: ExJoi.string(required: true),
          permissions:
            ExJoi.when(
              :role,
              [
                is: "admin",
                then: ExJoi.array(of: ExJoi.string(), min_items: 1, required: true),
                otherwise: ExJoi.array(of: ExJoi.string())
              ]
            )
        })

      assert {:error, %{errors: errors}} = ExJoi.validate(%{role: "admin"}, schema)
      assert [%{code: :required}] = errors.permissions

      assert {:error, %{errors: errors}} =
               ExJoi.validate(%{role: "admin", permissions: []}, schema)

      assert Enum.any?(errors.permissions, &(&1.code == :array_min_items))

      assert {:ok, %{permissions: ["read"]}} =
               ExJoi.validate(%{role: "admin", permissions: ["read"]}, schema)

      assert {:ok, %{permissions: []}} =
               ExJoi.validate(%{role: "viewer", permissions: []}, schema)
    end

    test "conditional rule based on numeric ranges" do
      schema =
        ExJoi.schema(%{
          age: ExJoi.number(required: true),
          guardian_contact:
            ExJoi.when(:age, [max: 17, then: ExJoi.string(required: true, min: 5)])
        })

      assert {:error, %{errors: errors}} =
               ExJoi.validate(%{age: 16}, schema)

      assert [%{code: :required}] = errors.guardian_contact

      assert {:ok, %{guardian_contact: "mommy"}} =
               ExJoi.validate(%{age: 16, guardian_contact: "mommy"}, schema)

      assert {:ok, %{}} = ExJoi.validate(%{age: 20}, schema)
    end

    test "conditional rule supports regex matching" do
      schema =
        ExJoi.schema(%{
          plan: ExJoi.string(required: true),
          pro_feature_flag:
            ExJoi.when(
              :plan,
              [
                matches: ~r/^pro/i,
                then: ExJoi.boolean(required: true),
                otherwise: ExJoi.boolean()
              ]
            )
        })

      assert {:error, %{errors: errors}} = ExJoi.validate(%{plan: "pro-plus"}, schema)
      assert [%{code: :required}] = errors.pro_feature_flag

      assert {:ok, %{pro_feature_flag: true}} =
               ExJoi.validate(%{plan: "pro-plus", pro_feature_flag: true}, schema)

      assert {:ok, %{}} = ExJoi.validate(%{plan: "starter"}, schema)
    end
  end

  describe "extensions" do
    defmodule UUIDValidator do
      @behaviour ExJoi.CustomValidator

      @impl true
      def validate(value, _rule, _context) when is_binary(value) do
        if String.match?(value, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i) do
          {:ok, String.downcase(value)}
        else
          {:error, [%{code: :uuid, message: "must be a UUID"}]}
        end
      end

      def validate(value, _rule, _context) do
        {:error, [%{code: :uuid, message: "must be a UUID", meta: %{value: value}}]}
      end
    end

    test "custom validator function" do
      ExJoi.extend(:uuid, fn value, _context ->
        if String.length(value) == 3 do
          {:ok, String.upcase(value)}
        else
          {:error, [%{code: :uuid, message: "must be exactly 3 characters"}]}
        end
      end)

      schema =
        ExJoi.schema(%{
          id: ExJoi.custom(:uuid, required: true)
        })

      assert {:ok, %{id: "ABC"}} = ExJoi.validate(%{id: "abc"}, schema)
      assert {:error, %{errors: errors}} = ExJoi.validate(%{id: "nope"}, schema)
      assert [%{code: :uuid}] = errors.id
    end

    test "custom validator module receives context" do
      ExJoi.extend(:uuid_mod, UUIDValidator)

      schema =
        ExJoi.schema(%{
          id: ExJoi.custom(:uuid_mod, required: true)
        })

      assert {:ok, %{id: "abc12345-abcd-abcd-abcd-abcdef123456"}} =
               ExJoi.validate(%{id: "ABC12345-ABCD-ABCD-ABCD-ABCDEF123456"}, schema)
    end

    test "error builder override" do
      ExJoi.configure(
        error_builder: fn errors ->
          %{status: :failed, issues: errors}
        end
      )

      schema = ExJoi.schema(%{name: ExJoi.string(required: true)})

      assert {:error, %{status: :failed, issues: issues}} = ExJoi.validate(%{}, schema)
      assert Map.has_key?(issues, :name)
    end

    test "errors_flat contains path-based entries" do
      schema =
        ExJoi.schema(%{
          user:
            ExJoi.object(%{
              email: ExJoi.string(required: true, email: true)
            })
        })

      assert {:error, %{errors_flat: flat}} =
               ExJoi.validate(%{user: %{email: "nope"}}, schema)

      assert Map.has_key?(flat, "user.email")
      assert Enum.any?(flat["user.email"], &String.contains?(&1, "email"))
    end

    test "message translator customizes error copy" do
      on_exit(fn -> ExJoi.Config.reset!() end)

      ExJoi.configure(
        message_translator: fn
          :required, _default, _meta -> "es requerido"
          _code, default, _meta -> default
        end
      )

      schema = ExJoi.schema(%{name: ExJoi.string(required: true)})

      assert {:error, %{errors: errors}} = ExJoi.validate(%{}, schema)
      assert [%{message: "es requerido"}] = errors.name
    end
  end
end
