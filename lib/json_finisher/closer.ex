defmodule JsonFinisher.Closer do
  @moduledoc """
  Applies finishing touches to a partially complete JSON string based on a provided stack.
  """

  def close_json(fragment, [:array | stack]) do
    fragment = fragment |> String.trim() |> String.trim(",")
    fragment = fragment <> "]"
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:object | stack]) do
    fragment = fragment |> String.trim() |> String.trim(",")
    fragment = fragment <> "}"
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:string | stack]) do
    fragment = fragment <> ~S(")
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:key, :kv | stack]) do
    fragment = fragment <> ~S(":null)
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:kv | stack]) do
    fragment = fragment <> ~S(:null)
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:value, :kv | stack]) do
    fragment = fragment <> ~S(null)
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:null_l1, :null | stack]) do
    fragment = fragment <> ~S(l)
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [false | stack]) do
    rest =
      case String.last(fragment) do
        "f" -> "alse"
        "a" -> "lse"
        "l" -> "se"
        "s" -> "e"
        _ -> ""
      end

    fragment = fragment <> rest
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [true | stack]) do
    rest =
      case String.last(fragment) do
        "t" -> "rue"
        "r" -> "ue"
        "u" -> "e"
        _ -> ""
      end

    fragment = fragment <> rest
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:null | stack]) do
    rest =
      case String.last(fragment) do
        "n" -> "ull"
        "u" -> "ll"
        "l" -> "l"
        _ -> ""
      end

    fragment = fragment <> rest
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:escape | stack]) do
    fragment = fragment <> ~S(")
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:number | stack]) do
    stack = close_abstract_stack_layers(stack)
    close_json(fragment, stack)
  end

  def close_json(fragment, []), do: fragment

  defp close_abstract_stack_layers([:value | stack]), do: close_abstract_stack_layers(stack)
  defp close_abstract_stack_layers([:kv | stack]), do: close_abstract_stack_layers(stack)
  defp close_abstract_stack_layers(stack), do: stack
end
