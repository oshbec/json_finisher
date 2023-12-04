defmodule JsonFinisherTest do
  use ExUnit.Case
  doctest JsonFinisher

  import JsonFinisher

  test "properly closes all readme examples" do
    assert finish_json(~S|{|) == {:ok, ~S|{}|}
    assert finish_json(~S|[|) == {:ok, ~S|[]|}
    assert finish_json(~S|{"|) == {:ok, ~S|{"":null}|}
    assert finish_json(~S|{"a|) == {:ok, ~S|{"a":null}|}
    assert finish_json(~S|{"a": tr|) == {:ok, ~S|{"a": true}|}
    assert finish_json(~S|{"a": {"b": "hi|) == {:ok, ~S|{"a": {"b": "hi"}}|}
  end
end
