defmodule JibeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  @moduletag capture_log: true

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
      refute Jibe.match?({:unsorted, [1, 2]}, [3, 1])
      refute Jibe.match?({:unsorted, [1, 2]}, [1])
      refute Jibe.match?({:unsorted, [1, 2]}, [])
    end

    test "match - nested lists" do
      pattern = {:unsorted, [1, [2, 3]]}
      actual  =             [[2, 3], 1, 4]
      assert Jibe.match?(pattern, actual)
    end

    test "no match - nested lists with inner sorted list" do
      pattern = {:unsorted, [1, [2, 3]]}
      actual  =             [[3, 2], 1, 4]
      refute Jibe.match?(pattern, actual)
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

    test "match - unsorted list of maps" do
      pattern = {:unsorted, [ %{id: 1}, %{id: 2} ]}
      actual  = [ %{id: 2}, %{id: 1} ]
      assert Jibe.match?(pattern, actual)
    end

    test "no match - nested lists and maps with unsorted mixed in" do
      pattern = %{data: {:unsorted, [:a, :b]}, meta: [:x, :y]}
      actual  = %{data:             [:b, :a],  meta: [:y, :x], extra_key: :v}
      refute Jibe.match?(pattern, actual)
    end

    test "no match - looking for nested unsorted list, but actual is wront type" do
      pattern = %{data: {:unsorted, [:a, :b]} }
      actual  = %{data:             :not_a_list}
      assert capture_log(fn ->
        refute Jibe.match?(pattern, actual)
       end) =~ "actual: %{data: :not_a_list}"
    end
  end

  describe "degenerate cases" do
    test "map compared to list" do
      refute Jibe.match?(%{}, [])
    end

    test "list compared to map" do
      refute Jibe.match?([], %{})
    end

    test "map compared to nil" do
      refute Jibe.match?(%{}, nil)
    end

    test "list compared to nil" do
      refute Jibe.match?([], nil)
    end
  end
end
