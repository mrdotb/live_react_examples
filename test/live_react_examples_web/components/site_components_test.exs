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
    html = conn |> get(~p"/simple") |> html_response(200)

    # The inline script must run in <head>, before <body> renders, or the page
    # paints light and then snaps to dark.
    head = html |> String.split("</head>") |> hd()
    assert head =~ "localStorage"
    assert head =~ "prefers-color-scheme"
    # toggle, not add: the script must also clear the class when the stored
    # preference is light but the system prefers dark.
    assert head =~ "classList.toggle"
  end

  test "site_header carries the primary nav and the toggle" do
    html = render_component(&site_header/1, %{})

    assert html =~ "/examples" or html =~ "/simple"
    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ ~s(id="theme-toggle")
  end

  test "site_footer links to the library and its docs" do
    html = render_component(&site_footer/1, %{})

    assert html =~ "github.com/mrdotb/live_react"
    assert html =~ "hexdocs.pm/live_react"
  end

  test "every page renders the header and the footer", %{conn: conn} do
    html = conn |> get(~p"/simple") |> html_response(200)

    assert html =~ ~s(id="theme-toggle")
    assert html =~ "hexdocs.pm/live_react"
  end
end
