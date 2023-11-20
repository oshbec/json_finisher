defmodule JsonFinisher.StackBuilderTest do
  use ExUnit.Case, async: true
  alias JsonFinisher.StackBuilder

  test "stack for empty string should be empty" do
    assert StackBuilder.build_stack("") == {:ok, []}
  end

  test "stack for '{' should be [:object]" do
    assert StackBuilder.build_stack("{") == {:ok, [:object]}
  end

  test "stack for '[' should be [:array]" do
    assert StackBuilder.build_stack("[") == {:ok, [:array]}
  end

  test "stack for '[{' should be [:object, :array]" do
    assert StackBuilder.build_stack("[{") == {:ok, [:object, :array]}
  end

  test "stack for '[{}' should be [:array]" do
    assert StackBuilder.build_stack("[{}") == {:ok, [:array]}
  end

  test "stack for '[]' should be empty" do
    assert StackBuilder.build_stack("[]") == {:ok, []}
  end

  test "returns an error for structural mismatch with input '{]'" do
    assert StackBuilder.build_stack("{]") == {:error, :structural_mismatch}
  end

  test "returns an error for structural mismatch with input ']'" do
    assert StackBuilder.build_stack("]") == {:error, :structural_mismatch}
  end

  test "returns an error for structural mismatch with non-JSON starting input 'a'" do
    assert StackBuilder.build_stack("a") == {:error, :structural_mismatch}
  end

  test "handles whitespace around top-level object or array" do
    assert StackBuilder.build_stack("  \r \n {} \n ") == {:ok, []}
    assert StackBuilder.build_stack("\t\n   [] \t ") == {:ok, []}
  end

  describe "object keys and values" do
    test "stack for '{\"key' should be [:key, :kv, :object]" do
      assert StackBuilder.build_stack(~S|{"key|) == {:ok, [:key, :kv, :object]}
    end

    test "stack for '{\"key\"' should be [:kv, :object]" do
      assert StackBuilder.build_stack(~S|{"key"|) == {:ok, [:kv, :object]}
    end
  end

  describe "escapes" do
    test "escape added to the stack for an object key" do
      assert StackBuilder.build_stack("{\"\\") == {:ok, [:escape, :key, :kv, :object]}
    end

    test "escaped second quote in a key does not close the key" do
      assert StackBuilder.build_stack(~S|{"\"|) == {:ok, [:key, :kv, :object]}
    end
  end
end
