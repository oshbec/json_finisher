defmodule JsonFinisher.Closer do
  @moduledoc """
  Applies finishing touches to a partially complete JSON string based on a provided stack.
  """

  def close_json(_stack, json_fragment) do
    json_fragment
  end
end
