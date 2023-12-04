defmodule JsonFinisher.StackBuilder do
  @moduledoc """
  The `JsonFinisher.StackBuilder` module processes truncated JSON strings to infer their structural state at the point of truncation. It is particularly useful for applications handling incomplete JSON data, enabling them to understand, complete, or correct the data.

  ## Implementation Approach
  Using Elixir's pattern matching, the module parses JSON strings character-by-character. It builds a stack that represents the JSON structure, tracking the context (objects, arrays, values) and special cases (e.g., escaped characters, partial literals).

  ### Process Overview
  1. **Character Processing:** Breaks down the JSON fragment into graphemes for individual analysis.
  2. **Stack Building:** Dynamically constructs a stack to track the JSON structure context.
  3. **Special Case Handling:** Manages unique JSON structures like escaped characters and various number formats.
  4. **Finalization:** Finalizes the stack, flagging structural mismatches or representing the truncation point.

  ### Stack Elements
  - **Structural Atoms**: `:object`, `:array`
  - **Value Type Atoms**: `:number`, `:string`, `:true`, `:false`, `:null`
  - **Intermediate State Atoms**: `:kv` (key-value context), `:key`, `:value`
  - **Special Atoms**: `:escape` (escape character), `:null_l1` (partial `null`)
  - **Error Atom**: `:structural_mismatch` (structure errors)

  These atoms reveal the JSON fragment's context and state at each processing step.
  """

  @number_start_chars ~w(0 1 2 3 4 5 6 7 8 9 - .)
  @valid_number_chars ~w(0 1 2 3 4 5 6 7 8 9 - . e E + -)

  @doc """
  Builds a stack representing the structural state of a partially truncated JSON string.

  This function takes a JSON fragment as input, processes it character-by-character, and builds a stack that reflects the structure of the JSON at the point of truncation. It can handle various JSON elements like objects, arrays, strings, numbers, booleans, and null values.

  ## Parameters
    - `json_fragment`: A string representing the truncated JSON data.

  ## Returns
    - On successful processing, it returns `{:ok, stack}` where `stack` is a list of atoms representing the JSON structure.
    - If a structural mismatch is detected, it returns `{:error, :structural_mismatch}`.

  ## Examples

      iex> JsonFinisher.StackBuilder.build_stack("{\"key\": [1, 2, nu")
      {:ok, [:null, :array, :value, :kv, :object]}

      iex> JsonFinisher.StackBuilder.build_stack("{]")
      {:error, :structural_mismatch}

  """
  def build_stack(json_fragment) do
    json_fragment
    |> String.trim()
    |> String.graphemes()
    |> Enum.reduce([], &process_char/2)
    |> finalize_stack()
  end

  # Pattern matching for specific characters
  defp process_char(_, [:escape | rest]), do: rest

  defp process_char("{", [top | _] = stack) when top in [:key, :string], do: stack
  defp process_char("{", stack), do: [:object | stack]

  defp process_char("[", [top | _] = stack) when top in [:key, :string], do: stack
  defp process_char("[", stack), do: [:array | stack]

  defp process_char(_, []), do: [:structural_mismatch]

  defp process_char("}", [:number, :value, :kv, :object, :value, :kv | rest]), do: rest
  defp process_char("}", [:number, :value, :kv, :object | rest]), do: rest

  defp process_char("}", [top | _] = stack) when top in [:key, :string], do: stack

  defp process_char("}", stack),
    do: pop_if_matches(stack, :object) |> close_abstract_stack_layers()

  defp process_char("]", [:number, :array | rest]), do: rest

  defp process_char("]", [top | _] = stack) when top in [:key, :string], do: stack

  defp process_char("]", stack),
    do: pop_if_matches(stack, :array) |> close_abstract_stack_layers()

  defp process_char(":", [:kv | _] = stack), do: [:value | stack]

  defp process_char("t", [top | _] = stack) when top in [:array, :value], do: [true | stack]
  defp process_char("f", [top | _] = stack) when top in [:array, :value], do: [false | stack]
  defp process_char("e", [bool, :value, :kv | rest]) when bool in [true, false], do: rest
  defp process_char("e", [bool | rest]) when bool in [true, false], do: rest

  defp process_char(~S|"|, [:object | _] = stack), do: [:key, :kv | stack]
  defp process_char(~S|"|, [top | _] = stack) when top in [:array, :value], do: [:string | stack]
  defp process_char(~S|"|, [:key | _] = stack), do: pop_if_matches(stack, :key)

  defp process_char(~S|"|, [:string | rest]) do
    rest |> close_abstract_stack_layers()
  end

  defp process_char("\\", [:key | _] = stack), do: [:escape | stack]
  defp process_char("\\", [:string | _] = stack), do: [:escape | stack]

  defp process_char("n", [top | _] = stack) when top in [:array, :value], do: [:null | stack]
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
