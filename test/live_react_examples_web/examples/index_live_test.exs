defmodule LiveReactExamplesWeb.Examples.IndexLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  alias LiveReactExamples.Examples

  test "lists every example, grouped by category", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    for %{category: category, items: items} <- Examples.by_category() do
      # HEEx escapes text content, so "Props & data" renders as
      # "Props &amp; data" — compare against the escaped form rather than
      # the raw category string.
      assert html =~ Phoenix.HTML.safe_to_string(Phoenix.HTML.html_escape(category))

      for item <- items do
        assert html =~ item.title, "#{item.title} missing from the index"
      end
    end
  end

  test "ready examples link to their page; planned ones do not", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    assert html =~ ~s(href="/examples/counter")
    refute html =~ ~s(href="/examples/streams")
  end

  test "explains the live/dead distinction rather than leaving it unexplained", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    assert html =~ "LiveView"
    assert html =~ "without"
  end
end
