defmodule LiveReactExamplesWeb.Examples.ExamplePageTest do
  @moduledoc """
  The tab-fallback logic lives in the macro, so it is tested once here rather
  than 14 times. A previous version of this logic was untested and silently
  rendered nothing for an unknown tab.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  test "defaults to the preview tab", %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)

    # Not just `"Key concepts"`: that section renders unconditionally
    # regardless of which tab is active, so it says nothing about the
    # default. The preview container only renders when the active tab is
    # "preview" — that's the thing actually under test here.
    assert html =~ "counter-preview"
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

    # Not `assert html =~ "Counter"`: `@example.title` is "Counter" and
    # `example_page/1` renders it independently in the page's `<h1>`, so that
    # assertion passes whether or not `page_title` is wired at all. Assert on
    # the actual `<title>` element, which only carries this content because
    # `mount/3` assigns `page_title`.
    [title] = Regex.run(~r{<title[^>]*>(.*?)</title>}s, html, capture: :all_but_first)

    # Code review (finding 7): the macro's `page_title` already carried
    # " · LiveReact examples", and the root layout's `<.live_title
    # suffix=" · Phoenix Framework">` appended a second, unrelated suffix on
    # top — every tab read "Counter · LiveReact examples · Phoenix
    # Framework". Assert the exact text, not just a substring match, so a
    # regression that tacks anything else on fails here.
    assert String.trim(title) == "Counter · LiveReact examples"
    refute title =~ "Phoenix Framework"
  end

  test "the last example's footer renders nothing for a missing next, not (coming soon)",
       %{conn: conn} do
    # Code review (finding 1): `:if={!@next || @next.status != :ready}` treated
    # "there is no next example" the same as "the next example is planned",
    # so /examples/lazy — the last example in the registry — rendered a bare
    # "(coming soon)" pointing at nothing. The parenthesised form is unique to
    # this footer (the sidebar's own "coming soon" is a tooltip attribute with
    # no parens), so this assertion targets the footer specifically.
    html = conn |> get(~p"/examples/lazy") |> html_response(200)

    refute html =~ "(coming soon)"
    # And the fix isn't just "print nothing everywhere" — the real prev link
    # must still render.
    {prev, next} = LiveReactExamples.Examples.neighbours("lazy")
    assert next == nil
    assert html =~ prev.title
  end

  test "the first example's footer renders nothing for a missing prev, not (coming soon)",
       %{conn: conn} do
    html = conn |> get(~p"/examples/counter") |> html_response(200)

    refute html =~ "(coming soon)"
    {prev, next} = LiveReactExamples.Examples.neighbours("counter")
    assert prev == nil
    assert html =~ next.title
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
