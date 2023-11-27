defmodule JsonFinisher.StackBuilder do
  @moduledoc """
  Builds a stack representing the structure of a partial JSON string.
  """
  @number_start_chars ~w(0 1 2 3 4 5 6 7 8 9 - .)
  @valid_number_chars ~w(0 1 2 3 4 5 6 7 8 9 - . e E + -)

  # Handling non-empty strings
  def build_stack(json_fragment) do
    json_fragment
    |> String.trim()
    |> String.graphemes()
    |> Enum.reduce([], &process_char/2)
    |> finalize_stack()
  end

  # Pattern matching for specific characters
  defp process_char(_, [:escape | rest]), do: rest
  defp process_char("{", stack), do: [:object | stack]
  defp process_char("[", stack), do: [:array | stack]
  defp process_char(_, []), do: [:structural_mismatch]

  defp process_char("}", stack),
    do: pop_if_matches(stack, :object) |> close_abstract_stack_layers()

  defp process_char("]", stack),
    do: pop_if_matches(stack, :array) |> close_abstract_stack_layers()

  defp process_char(~S{"}, [:object | _] = stack), do: [:key, :kv | stack]
  defp process_char(":", [:kv | _] = stack), do: [:value | stack]
  defp process_char("n", [top | _] = stack) when top in [:array, :value], do: [:null | stack]
  defp process_char("t", [top | _] = stack) when top in [:array, :value], do: [true | stack]

  defp process_char("e", [true | rest]) do
    rest
    |> pop_if_matches(:value)
    |> pop_if_matches(:kv)
  end

  defp process_char("f", [top | _] = stack) when top in [:array, :value], do: [false | stack]

  defp process_char("e", [false | rest]) do
    rest
    |> pop_if_matches(:value)
    |> pop_if_matches(:kv)
  end

  defp process_char(~S|"|, [top | _] = stack) when top in [:array, :value], do: [:string | stack]

  defp process_char(~S|"|, [:string | rest]) do
    rest |> close_abstract_stack_layers()
  end

  defp process_char(~S{"}, [:key | _] = stack), do: pop_if_matches(stack, :key)
  defp process_char("\\", [:key | _] = stack), do: [:escape | stack]
  defp process_char("\\", [:string | _] = stack), do: [:escape | stack]
  defp process_char("l", [:null | _] = stack), do: [:null_l1 | stack]

  defp process_char("l", [:null_l1 | rest]) do
    rest
    |> pop_if_matches(:null)
    |> close_abstract_stack_layers()
  end

  defp process_char(char, [top | _] = stack)
       when char in @number_start_chars and top in [:array, :value] do
    [:number | stack]
  end

  defp process_char(char, [:number | rest]) when char not in @valid_number_chars do
    rest
    |> close_abstract_stack_layers()
  end

  defp process_char(_, stack), do: stack

  # Helper function to pop the expected item from the stack
  defp pop_if_matches([expected | rest], expected), do: rest
  defp pop_if_matches(stack, _), do: [:structural_mismatch | stack]

  defp close_abstract_stack_layers([:value | rest]), do: close_abstract_stack_layers(rest)
  defp close_abstract_stack_layers([:kv | rest]), do: close_abstract_stack_layers(rest)
  defp close_abstract_stack_layers(stack), do: stack

  # Finalize the stack by checking for any :structural_mismatch markers
  defp finalize_stack(stack) do
    if :structural_mismatch in stack do
      {:error, :structural_mismatch}
    else
      {:ok, stack}
    end
  end
end
