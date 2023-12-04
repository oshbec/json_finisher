defmodule JsonFinisher.Closer do
  @moduledoc """
  Applies finishing touches to a partially complete JSON string based on a provided stack.
  """

  def close_json(fragment, [:array | stack]) do
    fragment = fragment <> "]"
    close_json(fragment, stack)
  end

  def close_json(fragment, [:object | stack]) do
    fragment = fragment <> "}"
    close_json(fragment, stack)
  end

  def close_json(fragment, [:string | stack]) do
    fragment = fragment <> ~S(")
    close_json(fragment, stack)
  end

  def close_json(fragment, [:key, :kv | stack]) do
    fragment = fragment <> ~S(":null)
    close_json(fragment, stack)
  end

  def close_json(fragment, [:null_l1, :null | stack]) do
    fragment = fragment <> ~S(l)
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
    close_json(fragment, stack)
  end

  def close_json(fragment, [:number | stack]), do: close_json(fragment, stack)
  def close_json(fragment, [:value | stack]), do: close_json(fragment, stack)
  def close_json(fragment, [:kv | stack]), do: close_json(fragment, stack)
  def close_json(fragment, []), do: fragment
end
