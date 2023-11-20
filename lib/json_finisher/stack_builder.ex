defmodule JsonFinisher.StackBuilder do
  @moduledoc """
  Builds a stack representing the structure of a partial JSON string.
  """

  # Handles the case for an empty string
  def build_stack(json_fragment) when json_fragment == "" do
    {:ok, []}
  end

  # Handles non-empty strings
  def build_stack(json_fragment) do
    json_fragment
    |> String.graphemes()
    |> Enum.reduce([], &process_char/2)
    |> case do
      {:error, _} = error -> error
      stack -> {:ok, stack}
    end
  end

  # Pattern matching for specific characters
  defp process_char("{", stack), do: [:object | stack]
  defp process_char("[", stack), do: [:array | stack]
  defp process_char("}", stack), do: pop_if_matches(stack, :object)
  defp process_char("]", stack), do: pop_if_matches(stack, :array)
  defp process_char(_, stack), do: stack

  defp pop_if_matches([expected | rest], expected), do: rest
  # If not matching, return stack as is
  defp pop_if_matches(stack, _), do: stack
end
