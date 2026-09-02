defmodule LiveReactExamplesWeb.Examples.ExampleComponentsTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  # `~H` needs `Phoenix.Component` imported explicitly — `ConnCase` does not
  # pull it in (see the same fix, with the reasoning, in `CodeBlockTest`).
  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LiveReactExamplesWeb.Examples.ExampleComponents

  alias LiveReactExamples.Examples

  # Slots are passed by rendering the component in a real ~H template rather
  # than by hand-building %{__slot__: ...} maps — those are an internal
  # representation, and a test that constructs them wrongly fails for reasons
  # that have nothing to do with the component.
  defp render_page(tab) do
    {:ok, example} = Examples.fetch("counter")
    assigns = %{example: example, tab: tab}

    rendered_to_string(~H"""
    <.example_page
      example={@example}
      tab={@tab}
      elixir_source="def mount(_, _, socket), do: {:ok, socket}"
      react_source="export function Counter() {}"
    >
      <:preview>PREVIEW HERE</:preview>
      <:concepts>CONCEPTS HERE</:concepts>
      <:how_it_works>HOW IT WORKS</:how_it_works>
    </.example_page>
    """)
  end

  test "the preview tab shows the preview and not the source" do
    html = render_page("preview")

    assert html =~ "PREVIEW HERE"
    refute html =~ "export function Counter"
  end

  test "the liveview tab shows the elixir source and not the preview" do
    html = render_page("liveview")

    assert html =~ "counter_live.ex"
    refute html =~ "PREVIEW HERE"
  end

  test "the react tab shows the react source" do
    html = render_page("react")

    assert html =~ "Counter.jsx"
    refute html =~ "PREVIEW HERE"
  end

  test "tabs are patch links so the tab is shareable and survives back" do
    html = render_page("preview")

    assert html =~ "?tab=liveview"
    assert html =~ "?tab=react"
  end

  test "the page carries its title, description and feature chips" do
    html = render_page("preview")

    assert html =~ "Counter"
    assert html =~ "Assigns become props"
    assert html =~ "phx-click"
  end

  test "the explanation slots render" do
    html = render_page("preview")

    assert html =~ "CONCEPTS HERE"
    assert html =~ "HOW IT WORKS"
  end

  test "the footer links to the next example" do
    html = render_page("preview")
    {_prev, next} = Examples.neighbours("counter")

    assert html =~ next.title
  end
end
