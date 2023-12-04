defmodule JsonFinisher.CloserTest do
  use ExUnit.Case, async: true

  import JsonFinisher.Closer

  describe "brackets" do
    test "closes open top-level array" do
      assert close_json("[1, 2, 3", [:array]) == "[1, 2, 3]"
    end

    test "closes open top-level object" do
      assert close_json("{", [:object]) == "{}"
    end
  end

  describe "strings" do
    test "closes a string in an array" do
      assert close_json(~S(["foo), [:string, :array]) == ~S(["foo"])
    end
  end

  test "closes a key" do
    assert close_json(~S({"foo), [:key, :kv, :object]) == ~S({"foo":null})
  end
end
