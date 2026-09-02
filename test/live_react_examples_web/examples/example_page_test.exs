defmodule LiveReactExamplesWeb.Examples.ExamplePageTest do
  @moduledoc """
  The tab-fallback logic lives in the macro, so it is tested once here rather
  than 14 times. A previous version of this logic was untested and silently
  rendered nothing for an unknown tab.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  test "defaults to the preview tab", %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)
    assert html =~ "Key concepts"
    refute html =~ "MyAppWeb.CounterLive"
  end

  test "an unknown tab falls back to preview and still renders it", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=nonsense") |> html_response(200)

    # The fallback must render the preview, not merely fail to render source.
    refute html =~ "MyAppWeb.CounterLive"
    assert html =~ "counter-preview"
  end

  test "each valid tab selects its own content", %{conn: conn} do
    liveview = conn |> get(~p"/examples/counter?tab=liveview") |> html_response(200)
    react = conn |> get(~p"/examples/counter?tab=react") |> html_response(200)

    assert liveview =~ "MyAppWeb.CounterLive"
    refute liveview =~ "export function Counter"

    assert react =~ "export function Counter"
    refute react =~ "MyAppWeb.CounterLive"
  end

  test "the macro sets a page title from the registry", %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)
    assert html =~ "Counter"
  end

  test "using the macro with an unknown slug fails at compile time" do
    assert_raise MatchError, fn ->
      Code.eval_string("""
      defmodule CompileTimeSlugCheck do
        use LiveReactExamplesWeb.Examples.ExamplePage, id: "no-such-example"
      end
      """)
    end
  end
end
