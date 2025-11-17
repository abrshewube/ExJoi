defmodule ExJoiTest do
  use ExUnit.Case
  doctest ExJoi

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
  end
end
