defmodule Jibe do
  require Logger

  @moduledoc """
  Tools for checking if an arbitrarily nested map/list matches a particular pattern.
  The genesis of this was as a helper in unit tests to check if JSON was being generated as
  expected.

  This does not require any particular JSON library, so if you want to use it with
  JSON you'll need to decode it with something like `Poison.decode/1` first. Note that these
  decode functions will usually build maps with strings for keys, as opposed to atoms, so set
  up your pattern accordingly.
  """

  @doc """
  Given a `pattern` and an `actual` map/list, determine if the pattern is a subset of the
  actual.

  The pattern is "forgiving" in the sense that extra keys or list elements in the actual are OK.
  However, every key and/or element in the pattern must appear in the actual. Anything missing in the
  actual is a failure.

  List order is significant by default.

  ## Examples

      # Simple equality tests.
      iex> Jibe.match?(%{}, %{})
      true

      iex> Jibe.match?([], [])
      true

      # Hash without nested values. Order of keys is not important,
      # since hash keys aren't ordered in the first place.
      iex> Jibe.match?(%{"foo" => "bar", "a" => 123}, %{"a" => 123, "foo" => "bar"})
      true

      # The keys are good, but the values don't match.
      iex> Jibe.match?(%{foo: :bar}, %{foo: :not_bar})
      false

      # Fails because not all expected hash elements are found.
      iex> Jibe.match?(%{"foo" => "bar", "a" => 123}, %{"a" => 123})
      false

      # Also works in nested maps. (`y: 2` is missing from the `actual`)
      iex> Jibe.match?(%{foo: :bar, a: %{x: 1, y: 2}}, %{a: %{x: 1}, foo: :bar})
      false

      # Extra keys in the actual don't matter.
      iex> Jibe.match?(%{"foo" => "bar"}, %{"a" => 123, "foo" => "bar"})
      true

      iex> Jibe.match?(%{foo: :bar, a: %{x: 1}}, %{a: %{x: 1, y: 2}, foo: :bar})
      true

      # Simple list comparison.
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

      # Nested data, actual map inside of a list has an extra element.
      iex> pattern = [%{"a" => 1}, %{"a" => 2}]
      iex> actual  = [%{"a" => 1, "x" => 9}, %{"y" => 9, "a" => 2}]
      iex> Jibe.match?(pattern, actual)
      true

      # Finding the matching map within a list of maps
      iex> pattern = [%{foo: :bar}]
      iex> actual  = [%{foo: :x}, %{foo: :bar}, %{foo: :y}]
      iex> Jibe.match?(pattern, actual)
      true

  ## Tuples

      They're converted to lists insternally, so the same rules apply.

      iex> pattern = {1, 2}
      iex> actual = {1, 2}
      iex> Jibe.match?(pattern, actual)
      true

      iex> pattern = {1, 2}
      iex> actual = {1, 2, 3}
      iex> Jibe.match?(pattern, actual)
      true

      iex> pattern = {1, 2}
      iex> actual = {1}
      iex> Jibe.match?(pattern, actual)
      false

      iex> pattern = [{1, 2}, {3, 4}]
      iex> actual = [{1, 2, 3}, {3, 5, 4}]
      iex> Jibe.match?(pattern, actual)
      true

  ## Unsorted lists

    This is a performance hit on your tests. Avoid large lists if you're especially worried about speed.

      iex> Jibe.match?({:unsorted, [1, 2]}, [2, 1])
      true

      iex> Jibe.match?({:unsorted, [1, 2, 3]}, [2, 1])
      false

  ## Empty lists

    Sometimes you want to check for a literal empty list `[]`. Because extra elements are OK by default,
    if you put [] into a pattern it will match any list, not just an empty one.

    iex> Jibe.match?(:empty_list, [])
    true

    iex> Jibe.match?(:empty_list, [1])
    false

    iex> Jibe.match?(%{foo: :empty_list}, %{foo: []})
    true

  ## Wildcard matches

      # "Something" needs to be there, but we don't care what it is.
      iex> Jibe.match?([1, :wildcard, 3], [1, 999, 3])
      true

      # :wildcard still needs the key to be present in a map.
      iex> Jibe.match?(%{"foo" => :wildcard}, %{"x" => "bar"})
      false

      # :wildcard will match a nil value as long as the key is there.
      iex> Jibe.match?(%{"foo" => :wildcard}, %{"foo" => nil})
      true


  ## DateTime matching

      iex> {:ok, d1, _} = DateTime.from_iso8601("2018-01-01T12:00:00Z")
      iex> {:ok, d2, _} = DateTime.from_iso8601("2018-01-01T12:00:00.000000Z")
      iex> Jibe.match?([d1], [d2])
      true

      iex> {:ok, d1, _} = DateTime.from_iso8601("2018-01-01T12:00:00Z")
      iex> {:ok, d2, _} = DateTime.from_iso8601("2018-01-01T12:00:00.000000Z")
      iex> Jibe.match?(%{d: d1}, %{d: d2})
      true

      iex> {:ok, d1, _} = DateTime.from_iso8601("2018-01-01T12:00:00Z")
      iex> {:ok, d2, _} = DateTime.from_iso8601("2000-01-01T12:00:00Z")
      iex> Jibe.match?([d1], [d2])
      false


  ## Decimal matching

      # Decimal values require a special comparison
      iex> Jibe.match?([Decimal.new(2)], [Decimal.from_float(2.0)])
      true

      iex> Jibe.match?([Decimal.new(4)], [Decimal.from_float(4.5)])
      false

  """
  def match?(pattern, actual) do
    result = match(pattern, actual)

    if !result do
      Logger.error "\npattern: #{inspect pattern}\n actual: #{inspect actual}"
    end

    result
  end

  # What are we trying to match?
  defp match(a, b) when is_map(a) and is_map(b), do: match_map(a, b, keys(a))
  defp match(a, b) when is_list(a) and is_list(b), do: match_list(a, b)
  defp match(a, b) when is_tuple(a) and is_tuple(b) do
    match_list(Tuple.to_list(a), Tuple.to_list(b))
  end

  # This is probably O(n^2). Use a sorted list if you care at all about performance.
  defp match({:unsorted, a}, b) when is_list(a), do: match_unsorted_list(a, b)

  defp match(:empty_list, b) when is_list(b) and b == [], do: true

  defp match(_, _), do: false

  # For maps, we check each key-value in the pattern to see if there is a cooresponding
  # key-value in the actual. If a value doesn't match, then the test fails. If we run
  # out of keys to check, then the test passes.
  defp match_map(_a, _b, []), do: true

  defp match_map(a, b, [k | rest_keys]) when is_map(a) do
    if compare(Map.get(a, k), Map.get(b, k, :key_missing)) do
      match_map(a, b, rest_keys)
    else
      false
    end
  end

  # For lists with default options, order is significant, but it's OK for the actual to have
  # extra items intermixed wherever.
  # For example, a pattern of [2, 4] should match [1, 2, 3, 4, 5]
  #
  defp match_list([], []), do: true

  # Nothing left in the pattern to check for, so the test has passed.
  defp match_list([], [_|_]), do: true

  # Still pieces of the pattern left to find, but we've run out of actual list
  # elements. This is a failure.
  defp match_list([_|_], []) do
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

  defp match_unsorted_list([], []), do: true
  defp match_unsorted_list([], [_|_]), do: true
  defp match_unsorted_list([a | rest_a], b) do
    case Enum.find_index(b, &(compare(a, &1))) do
      nil ->
        false
      index ->
        match_unsorted_list(rest_a, List.delete_at(b, index))
    end
  end

  # patterns like this need to be first, because they are also considered maps
  # by the is_map guard.

  @doc false
  def compare(%DateTime{} = a, %DateTime{} = b), do: DateTime.compare(a, b) == :eq
  def compare(%Decimal{} = a, %Decimal{} = b), do: Decimal.cmp(a, b) == :eq

  def compare(a, b) when is_map(a)  and is_map(b),  do: match(a, b)
  def compare(a, b) when is_list(a) and is_list(b), do: match(a, b)
  def compare(a, b) when is_tuple(a) and is_tuple(b), do: match(a, b)
  def compare({:unsorted, a}, b) when is_list(a) and is_list(b), do: match({:unsorted, a}, b)
  def compare(:wildcard, :key_missing), do: false
  def compare(:wildcard, _b), do: true
  def compare(:empty_list, b) when is_list(b) and b == [], do: true
  def compare(a, b), do: a == b

  defp keys(nil), do: []
  defp keys(m) when is_map(m), do: Map.keys(m)
end
