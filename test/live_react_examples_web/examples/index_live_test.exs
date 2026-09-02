defmodule LiveReactExamplesWeb.Examples.IndexLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

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

  test "ready examples link to their page; planned ones do not" do
    # Every real example is `:ready` once stage 1b finishes migrating them,
    # so there is no longer a `:planned` entry in the actual registry to
    # assert against here. Render the real `render/1` template directly
    # (not through `mount/3`, which always reads the real registry) against
    # a synthetic category containing one of each status.
    assigns = %{
      categories: [
        %{
          category: "Fixture",
          items: [
            %{
              id: "fixture-ready",
              title: "Fixture Ready",
              description: "d",
              icon: "hero-sparkles",
              kind: :live,
              status: :ready
            },
            %{
              id: "fixture-planned",
              title: "Fixture Planned",
              description: "d",
              icon: "hero-sparkles",
              kind: :live,
              status: :planned
            }
          ]
        }
      ]
    }

    html = render_component(&LiveReactExamplesWeb.Examples.IndexLive.render/1, assigns)

    assert html =~ ~s(href="/examples/fixture-ready")
    refute html =~ ~s(href="/examples/fixture-planned")
    assert html =~ "coming soon"
  end

  test "explains the live/dead distinction rather than leaving it unexplained", %{conn: conn} do
    html = conn |> get(~p"/examples") |> html_response(200)

    # Not "LiveView" / "without" alone: "LiveView" also matches the per-card
    # kind label and "without" also matches the Context card's description,
    # so both pass even with the foreword paragraph deleted entirely. Assert
    # on phrases distinctive to the foreword prose itself.
    assert html =~ "Some examples run inside a LiveView with a socket"
    assert html =~ "Each example says which it is."
  end
end
