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
end
