defmodule JsonFinisher.StackBuilderTest do
  use ExUnit.Case, async: true
  import JsonFinisher.StackBuilder

  describe "outer json structure" do
    test "Empty string results in empty stack" do
      assert build_stack("") == {:ok, []}
    end

    test "Single opening brace '{' creates an object stack" do
      assert build_stack("{") == {:ok, [:object]}
    end

    test "Single opening bracket '[' creates an array stack" do
      assert build_stack("[") == {:ok, [:array]}
    end

    test "Combining '{' and '[' results in object within array stack" do
      assert build_stack("[{") == {:ok, [:object, :array]}
    end

    test "Opening and closing brace within brackets results in array stack" do
      assert build_stack("[{}") == {:ok, [:array]}
    end

    test "Empty brackets '[]' result in empty stack" do
      assert build_stack("[]") == {:ok, []}
    end

    test "Structural mismatch error with '{]' input" do
      assert build_stack("{]") == {:error, :structural_mismatch}
    end

    test "Structural mismatch error with lone ']' input" do
      assert build_stack("]") == {:error, :structural_mismatch}
    end

    test "Error on non-JSON starting character 'a'" do
      assert build_stack("a") == {:error, :structural_mismatch}
    end

    test "Handling whitespace around empty JSON structures" do
      assert build_stack("  \r \n {} \n ") == {:ok, []}
      assert build_stack("\t\n   [] \t ") == {:ok, []}
    end
  end

  describe "word values: true, false, null" do
    test "null progression as an object value" do
      assert build_stack(~S|{"key":n|) == {:ok, [:null, :value, :kv, :object]}
      assert build_stack(~S|{"key":nu|) == {:ok, [:null, :value, :kv, :object]}

      assert build_stack(~S|{"key":nul|) ==
               {:ok, [:null_l1, :null, :value, :kv, :object]}

      assert build_stack(~S|{"key":null|) == {:ok, [:object]}
    end

    test "null progression as an array value" do
      assert build_stack(~S|[n|) == {:ok, [:null, :array]}
      assert build_stack(~S|[nu|) == {:ok, [:null, :array]}

      assert build_stack(~S|[nul|) == {:ok, [:null_l1, :null, :array]}

      assert build_stack(~S|[null|) == {:ok, [:array]}
    end

    test "true progression as an object value" do
      assert build_stack(~S|{"key":t|) == {:ok, [true, :value, :kv, :object]}
      assert build_stack(~S|{"key":tr|) == {:ok, [true, :value, :kv, :object]}
      assert build_stack(~S|{"key":tru|) == {:ok, [true, :value, :kv, :object]}

      assert build_stack(~S|{"key":true|) == {:ok, [:object]}
    end

    test "true progression as an array value" do
      assert build_stack(~S|[t|) == {:ok, [true, :array]}
      assert build_stack(~S|[tr|) == {:ok, [true, :array]}
      assert build_stack(~S|[tru|) == {:ok, [true, :array]}

      assert build_stack(~S|[true|) == {:ok, [:array]}
    end

    test "false progression as an object value" do
      assert build_stack(~S|{"key":f|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fa|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fal|) == {:ok, [false, :value, :kv, :object]}
      assert build_stack(~S|{"key":fals|) == {:ok, [false, :value, :kv, :object]}

      assert build_stack(~S|{"key":false|) == {:ok, [:object]}
    end

    test "false progression as an array value" do
      assert build_stack(~S|[f|) == {:ok, [false, :array]}
      assert build_stack(~S|[fa|) == {:ok, [false, :array]}
      assert build_stack(~S|[fal|) == {:ok, [false, :array]}
      assert build_stack(~S|[fals|) == {:ok, [false, :array]}

      assert build_stack(~S|[false|) == {:ok, [:array]}
    end
  end

  describe "number values" do
    test "Digit in object value starts number" do
      assert build_stack(~S|{"key":1|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "Closing brace ends number and object" do
      assert build_stack(~S|{"key":1.5}|) == {:ok, []}
    end

    test "Non-digit character ends number in object value" do
      assert build_stack(~S|{"key":1.5 ,|) == {:ok, [:object]}
    end

    test "Numeric string in object is not a number" do
      assert build_stack(~S|{"key":"1.5|) == {:ok, [:string, :value, :kv, :object]}
    end

    test "Handling negative numbers in object" do
      assert build_stack(~S|{"key":-123|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "Handling floating-point numbers in object" do
      assert build_stack(~S|{"key":123.456|) ==
               {:ok, [:number, :value, :kv, :object]}
    end

    test "Handling exponential numbers in object" do
      assert build_stack(~S|{"key":1e10|) == {:ok, [:number, :value, :kv, :object]}
      assert build_stack(~S|{"key":2.5E-4|) == {:ok, [:number, :value, :kv, :object]}
    end

    test "Handling numbers with positive exponent in object" do
      assert build_stack(~S|{"key":1.23e+4|) ==
               {:ok, [:number, :value, :kv, :object]}
    end

    test "Handling zero and small numbers in object" do
      assert build_stack(~S|{"key":0|) == {:ok, [:number, :value, :kv, :object]}
      assert build_stack(~S|{"key":0.0001|) == {:ok, [:number, :value, :kv, :object]}
    end
  end

  describe "object keys and values" do
    test "Unfinished object key adds key, kv, and object to stack" do
      assert build_stack(~S|{"key|) == {:ok, [:key, :kv, :object]}
    end

    test "Closed object key adds kv and object to stack" do
      assert build_stack(~S|{"key"|) == {:ok, [:kv, :object]}
    end

    test "Colon in object indicates start of value" do
      assert build_stack(~S|{"key":|) == {:ok, [:value, :kv, :object]}
    end

    test "Double quote starts a string value in object" do
      assert build_stack(~S|{"key":"|) == {:ok, [:string, :value, :kv, :object]}
    end

    test "Closing double quote finishes string value in object" do
      assert build_stack(~S|{"key":"hello"|) == {:ok, [:object]}
    end
  end

  describe "escaped characters" do
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
    test "nested objects as values" do
      assert build_stack(~S|{"hello": {|) == {:ok, [:object, :value, :kv, :object]}
    end

    test "closing nested objects closes up the :kv pair" do
      assert build_stack(~S|{"hello": {}|) == {:ok, [:object]}
    end

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
