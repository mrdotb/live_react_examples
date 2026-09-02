defmodule LiveReactExamplesWeb.SiteComponentsTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import LiveReactExamplesWeb.SiteComponents

  test "theme_toggle renders a button that flips the theme" do
    html = render_component(&theme_toggle/1, %{})

    assert html =~ ~s(id="theme-toggle")
    assert html =~ "aria-label"
  end

  test "root layout sets the theme before first paint", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)

    # The inline script must run in <head>, before <body> renders, or the page
    # paints light and then snaps to dark.
    head = html |> String.split("</head>") |> hd()
    assert head =~ "localStorage"
    assert head =~ "prefers-color-scheme"
    # toggle, not add: the script must also clear the class when the stored
    # preference is light but the system prefers dark.
    assert head =~ "classList.toggle"

    # The no-flash guarantee depends on this script running synchronously
    # during head parsing. `type="module"` scripts are deferred, so if this
    # ever became a module the theme would flash on first paint.
    theme_script_tag =
      head
      |> String.split("<script")
      |> Enum.find(&(&1 =~ "toggleTheme"))
      |> String.split(">", parts: 2)
      |> hd()

    refute theme_script_tag =~ ~s(type="module")
  end

  test "site_header carries the primary nav and the toggle" do
    html = render_component(&site_header/1, %{})

    assert html =~ ~s(href="/examples")
    assert html =~ "Examples"
    assert html =~ "hexdocs.pm/live_react"
    assert html =~ "Docs"
    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ "GitHub"
    assert html =~ ~s(id="theme-toggle")
  end

  test "site_footer links to the library and its docs" do
    html = render_component(&site_footer/1, %{})

    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ "hexdocs.pm/live_react"
  end

  test "every page renders the header and the footer", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)

    assert html =~ ~s(id="theme-toggle")
    assert html =~ "hexdocs.pm/live_react"
  end

  test "example_nav renders every category and marks the active example" do
    html = render_component(&example_nav/1, %{current: "counter"})

    for %{category: category, items: items} <- LiveReactExamples.Examples.by_category() do
      # `category` is asserted HTML-escaped, not raw: "Props & data" renders
      # as "Props &amp; data", so a raw `html =~ category` would never match
      # and this would silently fail to check that category at all.
      assert html =~ Phoenix.HTML.safe_to_string(Phoenix.HTML.html_escape(category))
      for item <- items, do: assert(html =~ item.title)
    end

    assert html =~ ~s(aria-current="page")
  end

  test "example_nav links only ready examples" do
    # Every real example is `:ready` once stage 1b finishes migrating them,
    # so the real registry no longer has a `:planned` entry to assert
    # against here. `example_nav/1` accepts a `:categories` override for
    # exactly this: inject a fixture with one of each status.
    fixture = [
      %{
        category: "Fixture",
        items: [
          %{id: "fixture-ready", title: "Fixture Ready", status: :ready},
          %{id: "fixture-planned", title: "Fixture Planned", status: :planned}
        ]
      }
    ]

    html = render_component(&example_nav/1, %{current: nil, categories: fixture})

    assert html =~ ~s(href="/examples/fixture-ready")
    refute html =~ ~s(href="/examples/fixture-planned")
    assert html =~ "coming soon"
  end

  test "example_nav keeps registry order with a planned item mid-category" do
    # Two separate `:for` loops (one for ready, one for planned) render every
    # ready link first and every planned span after, regardless of actual
    # registry order — a planned item mid-category would jump to the bottom.
    # Stage 1c adds planned entries, so this matters beyond a fixture.
    fixture = [
      %{
        category: "Fixture",
        items: [
          %{id: "fixture-first", title: "Fixture First", status: :ready},
          %{id: "fixture-middle", title: "Fixture Middle", status: :planned},
          %{id: "fixture-last", title: "Fixture Last", status: :ready}
        ]
      }
    ]

    html = render_component(&example_nav/1, %{current: nil, categories: fixture})

    {first, _} = :binary.match(html, "Fixture First")
    {middle, _} = :binary.match(html, "Fixture Middle")
    {last, _} = :binary.match(html, "Fixture Last")

    assert first < middle
    assert middle < last
  end
end
