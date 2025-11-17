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
      assert {:error, errors} = ExJoi.validate(%{}, schema)
      assert Map.has_key?(errors, :name)
      assert errors.name == ["is required"]
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
      assert {:error, errors} = ExJoi.validate(%{}, schema)
      assert errors.age == ["is required"]
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
      assert {:error, errors} = ExJoi.validate(%{}, schema)
      assert errors.active == ["is required"]
    end

    test "validates type mismatches" do
      schema = ExJoi.schema(%{
        name: ExJoi.string(),
        age: ExJoi.number(),
        active: ExJoi.boolean()
      })

      assert {:error, errors} = ExJoi.validate(%{name: 123}, schema)
      assert errors.name == ["must be a string"]

      assert {:error, errors} = ExJoi.validate(%{age: "thirty"}, schema)
      assert errors.age == ["must be a number"]

      assert {:error, errors} = ExJoi.validate(%{active: "yes"}, schema)
      assert errors.active == ["must be a boolean"]
    end

    test "validates multiple fields" do
      schema = ExJoi.schema(%{
        name: ExJoi.string(required: true),
        age: ExJoi.number(required: true),
        active: ExJoi.boolean()
      })

      assert ExJoi.validate(%{name: "John", age: 30, active: true}, schema) ==
               {:ok, %{name: "John", age: 30, active: true}}

      assert {:error, errors} = ExJoi.validate(%{name: "John"}, schema)
      assert Map.has_key?(errors, :age)
      assert errors.age == ["is required"]
    end

    test "handles string keys in schema" do
      schema = ExJoi.schema(%{
        "name" => ExJoi.string(required: true)
      })

      assert ExJoi.validate(%{"name" => "John"}, schema) == {:ok, %{"name" => "John"}}
      assert {:error, errors} = ExJoi.validate(%{}, schema)
      assert Map.has_key?(errors, "name")
    end
  end
end
