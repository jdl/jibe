defmodule Jibe do
  require Logger

  @moduledoc """
  Tools for checking if an arbitrarily nested map/list matches a particular pattern. 
  The genesis of this was as a helper in unit tests to check if JSON was being generated as
  expected. 

  This intentionally does require any particular JSON library, so if you want to use it with
  JSON you'll have to use something like `Poison.decode/1` first. Note that these decode functions 
  will usually build maps with strings for keys, as opposed to atoms, so set up your pattern 
  accordingly. 
  """

  @doc """
  Given a `pattern` and an `actual` map/list, determine if the actual matches 
  the pattern.

  The pattern is "forgiving" in the sense that extra keys or list elements in the actual are OK.
  However, every key and/or element in the pattern must appear in the actual. Anything missing in the 
  actual is a failure.

  List order is significant.


  Simple equality test.
  iex> Jibe.match?(%{}, %{})
  true

  iex> Jibe.match?([], [])
  true

  Hash without nested values. Order of keys should not be important, 
  since hash keys aren't ordered in the first place.
  iex> Jibe.match?(%{"foo" => "bar", "a" => 123}, %{"a" => 123, "foo" => "bar"})
  true

  iex> Jibe.match?(%{foo: :bar}, %{foo: :not_bar})
  false

  
  # Keys in the pattern that are not in the actual are a failure.
  iex> Jibe.match?(%{"foo" => "bar", "a" => 123}, %{"a" => 123})
  false
  
  # Also works in nested maps. 
  iex> Jibe.match?(%{foo: :bar, a: %{x: 1, y: 2}}, %{a: %{x: 1}, foo: :bar})
  false
  
  # Extra keys in the actual don't matter.
  iex> Jibe.match?(%{"foo" => "bar"}, %{"a" => 123, "foo" => "bar"})
  true

  iex> Jibe.match?(%{foo: :bar, a: %{x: 1}}, %{a: %{x: 1, y: 2}, foo: :bar})
  true
  
  # Works with lists.
  iex> Jibe.match?([1,2,3], [1,2,3])
  true
  
  # Extra list elements in the actual are OK.
  iex> Jibe.match?([1,2,3], [1,2,3,4])
  true
  
  iex> Jibe.match?([1,2, [3,4]], [1,2, [3,4,5]])
  true

  # The position of extra list elements does not matter.
  iex> Jibe.match?([2,4], [1,2,3,4,5])
  true

  # Missing list elements in the actual are a failure.
  iex> Jibe.match?([1,2,3], [1,2])
  false
  
  iex> Jibe.match?([1,2, [3,4]], [1,2, [3]])
  false
  
  # Mix and matching maps and lists.
  iex> Jibe.match?([1, %{foo: :bar}], [0, 1, 2, %{foo: :bar}, 3])
  true

  # Nested data where both sides are the same.
  iex> pattern = [%{"a" => 1, "b" => [2, 3, %{"x" => [4,5]}]}, 9, 10]
  iex> actual  = [%{"a" => 1, "b" => [2, 3, %{"x" => [4,5]}]}, 9, 10]
  iex> Jibe.match?(pattern, actual)
  true

  # Nested data, actual is missing a list element.
  iex> pattern = [%{"a" => 1, "b" => [2, 3, %{"x" => [4,5]}]}, 9, 10]
  iex> actual  = [%{"a" => 1, "b" => [2, 3, %{"x" => [4]}]}, 9, 10]
  iex> Jibe.match?(pattern, actual)
  false
  
  # Nested data, actual has an extra list element, which is fine. 
  iex> pattern = [%{"a" => 1, "b" => [2, 3, %{"x" => [4]}]}, 9, 10]
  iex> actual  = [%{"a" => 1, "b" => [2, 3, %{"x" => [4,5]}]}, 9, 10]
  iex> Jibe.match?(pattern, actual)
  true
  
  # Wildcard values. "Something" needs to be there, but we don't care what it is.
  iex> Jibe.match?([1, :wildcard, 3], [1, 999, 3])
  true
  
  iex> Jibe.match?(%{"foo" => :wildcard}, %{"foo": "bar"})
  true

  """
  def match?(pattern, actual) do
    match(pattern, actual)
  end

  # What are we trying to match?
  defp match(a, b) when is_map(a), do: match_map(a, b, keys(a))
  defp match(a, b) when is_list(a), do: match_list(a, b)


  # For maps, we check each key-value in the pattern to see if there is a cooresponding
  # key-value in the actual. If a value doesn't match, then the test fails. If we run 
  # out of keys to check, then the test passes. 
  defp match_map(_a, _b, []), do: true

  defp match_map(a, b, [k | rest_keys]) when is_map(a) do
    case compare(Map.get(a, k), Map.get(b, k)) do
      true -> match_map(a, b, rest_keys)
      false -> 
        Logger.info "\nKey #{k} failed to match"
        Logger.info "expected: #{inspect(Map.get(a, k))}"
        Logger.info "  actual: #{inspect(Map.get(b, k))}"
        false
    end
  end

  # For lists, order is significant, but it's OK for the actual to have extra items intermixed
  # wherever. For example, a pattern of [2, 4] should match [1, 2, 3, 4, 5]
  #
  defp match_list([], []), do: true

  # Nothing left in the pattern to check for, so the test has passed.
  defp match_list([], [_|_]), do: true

  # Still pieces of the pattern left to find, but we've run out of actual list
  # elements. This is a failure.
  defp match_list([_|_] = a, []) do
    Logger.info "\nJSON is missing the following expected elements: #{inspect a}"
    false
  end

  # Check the next element in the patten, trying to find a matching element
  # in the actual. This continues until one of the lists is empty.
  defp match_list([a | rest_a] = pattern, [b | rest_b]) do
    if compare(a, b) do
      match_list(rest_a, rest_b)
    else
      match_list(pattern, rest_b)
    end
  end

  def compare(a, b) when is_map(a)  and is_map(b),  do: match(a, b)
  def compare(a, b) when is_list(a) and is_list(b), do: match(a, b)
  def compare(:wildcard, _b), do: true
  def compare(a, b), do: a == b
  
  defp keys(nil), do: []
  defp keys(m) when is_map(m), do: Map.keys(m)
end