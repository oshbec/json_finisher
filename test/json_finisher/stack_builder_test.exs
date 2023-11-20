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

    test "colon (:) signals that we are now in a value" do
      assert StackBuilder.build_stack(~S|{"key":|) == {:ok, [:value, :kv, :object]}
    end

    test "first `n` in a value indicates we're working on a null" do
      assert StackBuilder.build_stack(~S|{"key":n|) == {:ok, [:null, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":nu|) == {:ok, [:null, :value, :kv, :object]}
    end

    test "first `l` within :null indicates we are almost done with :null value" do
      assert StackBuilder.build_stack(~S|{"key":nul|) ==
               {:ok, [:null_l1, :null, :value, :kv, :object]}
    end

    test "second `l` in a :null value closes the :null, value, and :kv" do
      assert StackBuilder.build_stack(~S|{"key":null|) == {:ok, [:object]}
    end

    test "first `t` in a value indicates we're working on a true" do
      assert StackBuilder.build_stack(~S|{"key":t|) == {:ok, [true, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":tr|) == {:ok, [true, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":tru|) == {:ok, [true, :value, :kv, :object]}
    end

    test "`e` in a :true closes :true, :value, and :kv" do
      assert StackBuilder.build_stack(~S|{"key":true|) == {:ok, [:object]}
    end

    test "first `f` in a value indicates we're working on a :false" do
      assert StackBuilder.build_stack(~S|{"key":f|) == {:ok, [false, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":fa|) == {:ok, [false, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":fal|) == {:ok, [false, :value, :kv, :object]}
      assert StackBuilder.build_stack(~S|{"key":fals|) == {:ok, [false, :value, :kv, :object]}
    end

    test "`e` in a :false closes :false, :value, and :kv" do
      assert StackBuilder.build_stack(~S|{"key":false|) == {:ok, [:object]}
    end

    test "double-quote in a value begins a string" do
      assert StackBuilder.build_stack(~S|{"key":"|) == {:ok, [:string, :value, :kv, :object]}
    end

    test "double-quote in a :string closes :string, :value, :kv" do
      assert StackBuilder.build_stack(~S|{"key":"hello"|) == {:ok, [:object]}
    end

    test "a digit signals the start of a :number within a :value" do
      assert StackBuilder.build_stack(~S|{"key":1|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "a non-digit signals the end of a :number within a :value" do
      assert StackBuilder.build_stack(~S|{"key":1.5 ,|) == {:ok, [:object]}
    end

    test "a number based :string is not a :number" do
      assert StackBuilder.build_stack(~S|{"key":"1.5|) == {:ok, [:string, :value, :kv, :object]}
    end
  end

  describe "nested objects" do
    test "nested objects as values" do
      assert StackBuilder.build_stack(~S|{"hello": {|) == {:ok, [:object, :value, :kv, :object]}
    end

    test "closing nested objects closes up the :kv pair" do
      assert StackBuilder.build_stack(~S|{"hello": {}|) == {:ok, [:object]}
    end
  end

  describe "escapes" do
    test "escape added to the stack for an object key" do
      assert StackBuilder.build_stack("{\"\\") == {:ok, [:escape, :key, :kv, :object]}
    end

    test "escaped second quote in a key does not close the key" do
      assert StackBuilder.build_stack(~S|{"\"|) == {:ok, [:key, :kv, :object]}
    end

    test "escaped double-quote in a :string doesn't close it" do
      assert StackBuilder.build_stack(~S|{"key":"hello\"|) ==
               {:ok, [:string, :value, :kv, :object]}
    end

    test "escaped bracket :string doesn't try to close it" do
      assert StackBuilder.build_stack(~S|{"key":"hello\}|) ==
               {:ok, [:string, :value, :kv, :object]}
    end
  end
end
