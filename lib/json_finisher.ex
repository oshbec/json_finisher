defmodule JsonFinisher do
  @moduledoc """
  Provides functionality to 'finish' partially complete JSON strings.
  """

  import JsonFinisher.Closer
  import JsonFinisher.StackBuilder

  def finish_json(fragment) do
    with {:ok, stack} <- build_stack(fragment) do
      closed_json = close_json(fragment, stack)
      {:ok, closed_json}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
