defmodule LiveReactExamples.ExamplesTest do
  use ExUnit.Case, async: true

  alias LiveReactExamples.Examples

  test "every example has the keys the page and nav depend on" do
    for example <- Examples.all() do
      for key <- [
            :id,
            :title,
            :description,
            :icon,
            :kind,
            :module,
            :react_ext,
            :features,
            :status
          ] do
        assert Map.has_key?(example, key), "#{example[:id] || "?"} is missing #{key}"
      end

      assert example.kind in [:live, :dead], "#{example.id} has bad kind #{inspect(example.kind)}"
      assert example.status in [:ready, :planned]
      assert example.react_ext in ["jsx", "tsx"]
      assert is_list(example.features) and example.features != []
    end
  end

  test "slugs are unique and url-safe" do
    ids = Enum.map(Examples.all(), & &1.id)
    assert ids == Enum.uniq(ids)

    for id <- ids do
      assert id =~ ~r/^[a-z0-9-]+$/, "#{id} is not a url-safe slug"
    end
  end

  test "fetch finds by slug and reports misses" do
    assert {:ok, counter} = Examples.fetch("counter")
    assert counter.title == "Counter"
    assert :error = Examples.fetch("does-not-exist")
  end

  test "by_category preserves display order and loses nothing" do
    flattened = Examples.by_category() |> Enum.flat_map(& &1.items)
    assert flattened == Examples.all()
  end

  test "neighbours walks the flat order, nil at the ends" do
    [first | _] = all = Examples.all()
    last = List.last(all)

    assert {nil, second} = Examples.neighbours(first.id)
    assert second == Enum.at(all, 1)

    assert {before_last, nil} = Examples.neighbours(last.id)
    assert before_last == Enum.at(all, -2)
  end

  test "ready/0 is the subset that has routes" do
    assert Enum.all?(Examples.ready(), &(&1.status == :ready))
    assert "counter" in Enum.map(Examples.ready(), & &1.id)
  end
end
