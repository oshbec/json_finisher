defmodule JsonFinisher.CloserTest do
  use ExUnit.Case, async: true

  import JsonFinisher.Closer

  test "closes open top-level array" do
    assert close_json("[1, 2, 3", [:array]) == "[1, 2, 3]"
  end

  test "closes open top-level object" do
    assert close_json("{", [:object]) == "{}"
  end

  test "closes a string in an array" do
    assert close_json(~S(["foo), [:string, :array]) == ~S(["foo"])
  end

  test "closes a key" do
    assert close_json(~S({"foo), [:key, :kv, :object]) == ~S({"foo":null})
  end

  test "closes false values" do
    assert close_json(~S({"foo":f), [false, :value, :kv, :object]) == ~S({"foo":false})
    assert close_json(~S({"foo":fa), [false, :value, :kv, :object]) == ~S({"foo":false})
    assert close_json(~S({"foo":fal), [false, :value, :kv, :object]) == ~S({"foo":false})
    assert close_json(~S({"foo":fals), [false, :value, :kv, :object]) == ~S({"foo":false})
    assert close_json(~S({"foo":false), [false, :value, :kv, :object]) == ~S({"foo":false})
  end

  test "closes true values" do
    assert close_json(~S({"foo":t), [true, :value, :kv, :object]) == ~S({"foo":true})
    assert close_json(~S({"foo":tr), [true, :value, :kv, :object]) == ~S({"foo":true})
    assert close_json(~S({"foo":tru), [true, :value, :kv, :object]) == ~S({"foo":true})
    assert close_json(~S({"foo":true), [true, :value, :kv, :object]) == ~S({"foo":true})
  end

  test "closes null values" do
    assert close_json(~S({"foo":n), [:null, :value, :kv, :object]) == ~S({"foo":null})
    assert close_json(~S({"foo":nu), [:null, :value, :kv, :object]) == ~S({"foo":null})
    assert close_json(~S({"foo":nul), [:null, :value, :kv, :object]) == ~S({"foo":null})

    assert close_json(~S|{"foo":nul|, [:null_l1, :null, :value, :value, :kv, :object]) ==
             ~S({"foo":null})
  end

  test "close number value" do
    assert close_json(~S([1), [:number, :array]) == ~S([1])
  end
end
