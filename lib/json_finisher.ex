defmodule JsonFinisher do
  @moduledoc """
  Provides functionality to 'finish' partially complete JSON strings.
  """

  def finish_json(json_fragment) do
    with {:ok, stack} <- JsonFinisher.StackBuilder.build_stack(json_fragment) do
      closed_json = JsonFinisher.Closer.close_json(stack, json_fragment)
      {:ok, closed_json}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
