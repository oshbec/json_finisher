defmodule JsonFinisher.Closer do
  @moduledoc """
  Applies finishing touches to a partially complete JSON string based on a provided stack.
  """

  def close_json(json_fragment, [:array | stack]) do
    json_fragment = json_fragment <> "]"
    close_json(json_fragment, stack)
  end

  def close_json(json_fragment, [:object | stack]) do
    json_fragment = json_fragment <> "}"
    close_json(json_fragment, stack)
  end

  def close_json(string_fragment, [:string | stack]) do
    string_fragment = string_fragment <> ~S(")
    close_json(string_fragment, stack)
  end

  def close_json(string_fragment, [:key, :kv | stack]) do
    string_fragment = string_fragment <> ~S(":null)
    close_json(string_fragment, stack)
  end

  def close_json(json_fragment, []), do: json_fragment
end
