defmodule JsonFinisher.StackBuilder do
  @moduledoc """
  Builds a stack representing the structure of a partial JSON string.
  """

  # Handling non-empty strings
  def build_stack(json_fragment) do
    json_fragment
    |> String.graphemes()
    |> Enum.reduce([], &process_char/2)
    |> finalize_stack()
  end

  # Pattern matching for specific characters
  defp process_char("{", stack), do: [:object | stack]
  defp process_char("[", stack), do: [:array | stack]
  defp process_char("}", stack), do: pop_if_matches(stack, :object)
  defp process_char("]", stack), do: pop_if_matches(stack, :array)
  defp process_char(_, []), do: [:structural_mismatch]
  defp process_char(_, stack), do: stack

  # Helper function to pop the expected item from the stack
  defp pop_if_matches([expected | rest], expected), do: rest
  defp pop_if_matches(stack, _), do: [:structural_mismatch | stack]

  # Finalize the stack by checking for any :structural_mismatch markers
  defp finalize_stack(stack) do
    if :structural_mismatch in stack do
      {:error, :structural_mismatch}
    else
      {:ok, stack}
    end
  end
end
