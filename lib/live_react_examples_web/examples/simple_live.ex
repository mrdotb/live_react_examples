defmodule LiveReactExamplesWeb.Examples.SimpleLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "simple"

  alias LiveReactExamplesWeb.Examples.SimplePreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <SimplePreview.preview />
      </:preview>

      <:concepts>
        <p>
          <code>react/1</code> works in any Phoenix template, not only inside a LiveView.
          This page has no socket: the component is server-rendered on the first request
          and hydrated in the browser, and there is no websocket behind it.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The component is rendered by a plain function component from a controller
          action. Use this when you want React for its own sake — a widget, a chart, a
          third-party library — without any server-driven state.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
