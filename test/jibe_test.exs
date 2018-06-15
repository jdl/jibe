defmodule JibeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest Jibe

  # Most of the tests are doc tests in jibe.ex. 
  
  describe "lists with indifferent order" do
    test "match - flat lists" do
      assert Jibe.match?({:unsorted, [1, 2]}, [3, 2, 1])
    end

    test "match - flat lists with duplicate values" do
      assert Jibe.match?({:unsorted, [2, 2, 4]}, [4, 2, 2])
      assert Jibe.match?({:unsorted, [2, 2, 4]}, [4, 2, 1, 2, 0])
    end

    test "no match - flat lists, missing element" do
      assert capture_log(fn ->
        refute Jibe.match?({:unsorted, [1, 2]}, [3, 1])
      end) =~ "Missing the following expected element: 2"

      assert capture_log(fn ->
        refute Jibe.match?({:unsorted, [1, 2]}, [1])
      end) =~ "Missing the following expected element: 2"

      assert capture_log(fn ->
        refute Jibe.match?({:unsorted, [1, 2]}, [])
      end) =~ "Missing the following expected element: 1"
    end

    test "match - nested lists" do
      pattern = {:unsorted, [1, [2, 3]]}
      actual  =             [[2, 3], 1, 4]
      assert Jibe.match?(pattern, actual)
    end

    test "no match - nested lists with inner sorted list" do
      pattern = {:unsorted, [1, [2, 3]]}
      actual  =             [[3, 2], 1, 4]
      assert capture_log(fn ->
        refute Jibe.match?(pattern, actual)
      end) =~ "Missing the following expected element: [2, 3]"
    end

    test "match - nested lists with inner unsorted list" do
      pattern = {:unsorted, [1, {:unsorted, [2, 3]} ]}
      actual  =             [[3, 2], 1, 4]
      assert Jibe.match?(pattern, actual)
    end

    test "match - nested lists and maps with unsorted mixed in" do
      pattern = %{data: {:unsorted, [:a, :b]}, meta: [:x, :y]}
      actual  = %{data:             [:b, :a],  meta: [:x, :y], extra_key: :v}
      assert Jibe.match?(pattern, actual)
    end

    test "no match - nested lists and maps with unsorted mixed in" do
      pattern = %{data: {:unsorted, [:a, :b]}, meta: [:x, :y]}
      actual  = %{data:             [:b, :a],  meta: [:y, :x], extra_key: :v}
      assert capture_log(fn ->
        refute Jibe.match?(pattern, actual)
      end) =~ "Missing the following expected elements: [:y]"
    end
  end
end
