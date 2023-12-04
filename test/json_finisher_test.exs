defmodule JsonFinisherTest do
  use ExUnit.Case
  doctest JsonFinisher

  import JsonFinisher
  import JsonFinisher.StackBuilder

  test "properly closes all readme examples" do
    assert finish_json(~S|{|) == {:ok, ~S|{}|}
    assert finish_json(~S|[|) == {:ok, ~S|[]|}
    assert finish_json(~S|{"|) == {:ok, ~S|{"":null}|}
    assert finish_json(~S|{"a|) == {:ok, ~S|{"a":null}|}
    assert finish_json(~S|{"a": tr|) == {:ok, ~S|{"a": true}|}
    assert finish_json(~S|{"a": {"b": "hi|) == {:ok, ~S|{"a": {"b": "hi"}}|}
  end

  test "checks all possible truncations of complex json object are valid after finishing" do
    json_file_path = "test/example.json"
    json_data = File.read!(json_file_path)
    truncations = 0..String.length(json_data)

    broken_truncation =
      Enum.find(truncations, fn truncation ->
        truncated_json = String.slice(json_data, 0..truncation)
        {:ok, finished_json} = finish_json(truncated_json)

        case Jason.decode(finished_json) do
          {:ok, _decoded_json} ->
            false

          {:error, _} ->
            IO.puts("\nFailed to decode truncated json:")
            IO.puts(truncated_json)
            {:ok, stack} = build_stack(truncated_json)
            IO.inspect(stack, label: "Stack")
            IO.puts("\nFinished json:")
            IO.puts(finished_json)
        end
      end)

    assert broken_truncation == nil
  end
end
