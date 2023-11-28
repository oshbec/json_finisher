defmodule JsonFinisher.StackBuilderTest do
  use ExUnit.Case, async: true
  import JsonFinisher.StackBuilder

  test "stack for empty string should be empty" do
    assert build_stack("") == {:ok, []}
  end

  test "stack for '{' should be [:object]" do
    assert build_stack("{") == {:ok, [:object]}
  end

  test "stack for '[' should be [:array]" do
    assert build_stack("[") == {:ok, [:array]}
  end

  test "stack for '[{' should be [:object, :array]" do
    assert build_stack("[{") == {:ok, [:object, :array]}
  end

  test "stack for '[{}' should be [:array]" do
    assert build_stack("[{}") == {:ok, [:array]}
  end

  test "stack for '[]' should be empty" do
    assert build_stack("[]") == {:ok, []}
  end

  test "returns an error for structural mismatch with input '{]'" do
    assert build_stack("{]") == {:error, :structural_mismatch}
  end

  test "returns an error for structural mismatch with input ']'" do
    assert build_stack("]") == {:error, :structural_mismatch}
  end

  test "returns an error for structural mismatch with non-JSON starting input 'a'" do
    assert build_stack("a") == {:error, :structural_mismatch}
  end

  test "handles whitespace around top-level object or array" do
    assert build_stack("  \r \n {} \n ") == {:ok, []}
    assert build_stack("\t\n   [] \t ") == {:ok, []}
  end

  describe "object keys and values" do
    test "stack for '{\"key' should be [:key, :kv, :object]" do
      assert build_stack(~S|{"key|) == {:ok, [:key, :kv, :object]}
    end

    test "stack for '{\"key\"' should be [:kv, :object]" do
      assert build_stack(~S|{"key"|) == {:ok, [:kv, :object]}
    end

    test "colon (:) signals that we are now in a value" do
      assert build_stack(~S|{"key":|) == {:ok, [:value, :kv, :object]}
    end

    test "first `n` in a value indicates we're working on a null" do
      assert build_stack(~S|{"key":n|) == {:ok, [:null, :value, :kv, :object]}
      assert build_stack(~S|{"key":nu|) == {:ok, [:null, :value, :kv, :object]}
    end

    test "first `l` within :null indicates we are almost done with :null value" do
      assert build_stack(~S|{"key":nul|) ==
               {:ok, [:null_l1, :null, :value, :kv, :object]}
    end

    test "second `l` in a :null value closes the :null, value, and :kv" do
      assert build_stack(~S|{"key":null|) == {:ok, [:object]}
    end

    test "first `t` in a value indicates we're working on a true" do
      assert build_stack(~S|{"key":t|) == {:ok, [true, :value, :kv, :object]}
      assert build_stack(~S|{"key":tr|) == {:ok, [true, :value, :kv, :object]}
      assert build_stack(~S|{"key":tru|) == {:ok, [true, :value, :kv, :object]}
    end

    test "`e` in a :true closes :true, :value, and :kv" do
      assert build_stack(~S|{"key":true|) == {:ok, [:object]}
    end

    test "first `f` in a value indicates we're working on a :false" do
      assert build_stack(~S|{"key":f|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fa|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fal|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fals|) == {:ok, [false, :value, :kv, :object]}
    end

    test "`e` in a :false closes :false, :value, and :kv" do
      assert build_stack(~S|{"key":false|) == {:ok, [:object]}
    end

    test "double-quote in a value begins a string" do
      assert build_stack(~S|{"key":"|) == {:ok, [:string, :value, :kv, :object]}
    end

    test "double-quote in a :string closes :string, :value, :kv" do
      assert build_stack(~S|{"key":"hello"|) == {:ok, [:object]}
    end

    test "a digit signals the start of a :number within a :value" do
      assert build_stack(~S|{"key":1|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "a } ends both the number and object" do
      assert build_stack(~S|{"key":1.5}|) == {:ok, []}
    end

    test "a non-digit signals the end of a :number within a :value" do
      assert build_stack(~S|{"key":1.5 ,|) == {:ok, [:object]}
    end

    test "a number based :string is not a :number" do
      assert build_stack(~S|{"key":"1.5|) == {:ok, [:string, :value, :kv, :object]}
    end

    test "handles negative numbers correctly" do
      assert build_stack(~S|{"key":-123|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "handles floating-point numbers correctly" do
      assert build_stack(~S|{"key":123.456|) ==
               {:ok, [:number, :value, :kv, :object]}
    end

    test "handles numbers with exponents correctly" do
      assert build_stack(~S|{"key":1e10|) == {:ok, [:number, :value, :kv, :object]}
      assert build_stack(~S|{"key":2.5E-4|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "handles numbers with plus sign in exponent correctly" do
      assert build_stack(~S|{"key":1.23e+4|) ==
               {:ok, [:number, :value, :kv, :object]}
    end

    test "handles zero and special number cases correctly" do
      assert build_stack(~S|{"key":0|) == {:ok, [:number, :value, :kv, :object]}
      assert build_stack(~S|{"key":0.0001|) == {:ok, [:number, :value, :kv, :object]}
    end
  end

  describe "nested objects" do
    test "nested objects as values" do
      assert build_stack(~S|{"hello": {|) == {:ok, [:object, :value, :kv, :object]}
    end

    test "closing nested objects closes up the :kv pair" do
      assert build_stack(~S|{"hello": {}|) == {:ok, [:object]}
    end
  end

  describe "escapes" do
    test "escape added to the stack for an object key" do
      assert build_stack("{\"\\") == {:ok, [:escape, :key, :kv, :object]}
    end

    test "escaped second quote in a key does not close the key" do
      assert build_stack(~S|{"\"|) == {:ok, [:key, :kv, :object]}
    end

    test "escaped double-quote in a :string doesn't close it" do
      assert build_stack(~S|{"key":"hello\"|) ==
               {:ok, [:string, :value, :kv, :object]}
    end

    test "escaped bracket :string doesn't try to close it" do
      assert build_stack(~S|{"key":"hello\}|) ==
               {:ok, [:string, :value, :kv, :object]}
    end
  end

  describe "arrays" do
    test "handles top-level arrays" do
      assert build_stack(~S|[|) == {:ok, [:array]}
    end

    test "handles array values" do
      assert build_stack(~S|{"hello":[|) == {:ok, [:array, :value, :kv, :object]}
    end

    test "recognizes unfinished string in array" do
      assert build_stack(~S|["hi|) == {:ok, [:string, :array]}
    end

    test "accounts for finished string in array" do
      assert build_stack(~S|["hi"|) == {:ok, [:array]}
    end

    test "recognizes unfinished number in array" do
      assert build_stack(~S|[1|) == {:ok, [:number, :array]}
    end

    test "accounts for finished number in array" do
      assert build_stack(~S|[1,|) == {:ok, [:array]}
    end

    test "recognizes unfinished object in an array" do
      assert build_stack(~S|[{|) == {:ok, [:object, :array]}
    end

    test "recognizes unfinished true in an array" do
      assert build_stack(~S|[tr|) == {:ok, [true, :array]}
    end

    test "recognizes unfinished false in an array" do
      assert build_stack(~S|[fa|) == {:ok, [false, :array]}
    end

    test "recognizes unfinished null in an array" do
      assert build_stack(~S|[nu|) == {:ok, [:null, :array]}
    end

    test "handles multiple values in array" do
      assert build_stack(~S|["hi", "hello"]|) == {:ok, []}
    end

    test "handles single values in complete array" do
      assert build_stack(~S|["hi"]|) == {:ok, []}
    end

    test "handles single value with commas in complete array" do
      assert build_stack(~S|["hi"]|) == {:ok, []}
    end

    test "handles multiple array-ish values in array" do
      assert build_stack(~S|["1,2,3|) == {:ok, [:string, :array]}
    end

    test "handles number value at end of complete array" do
      assert build_stack(~S|[1,2,3]|) == {:ok, []}
    end

    test "handles trailing array comma" do
      assert build_stack(~S|[1,2,|) == {:ok, [:array]}
    end
  end

  describe "nesting" do
    test "handles nested objects" do
      assert build_stack(~S|{"hello":{"world":true}}|) == {:ok, []}
    end

    test "handles nested objects with incommplete number value" do
      assert build_stack(~S|{"hello":{"world":1|) ==
               {:ok, [:number, :value, :kv, :object, :value, :kv, :object]}
    end

    test "handles nested objects ending in numerical value with incomplete outer object" do
      assert build_stack(~S|{"hello":{"world":1}|) == {:ok, [:object]}
    end

    test "handles nested objects with incomplete outer object" do
      assert build_stack(~S|{"hello":{"world":true}|) == {:ok, [:object]}
    end

    test "handles objects nested in incomplete array" do
      assert build_stack(~S|[{"world":1}|) == {:ok, [:array]}
    end
  end
end
