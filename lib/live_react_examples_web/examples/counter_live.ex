defmodule LiveReactExamplesWeb.Examples.CounterLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "counter"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.CounterPreview, id: "counter-preview")}
      </:preview>

      <:concepts>
        <p>
          Every assign that is not a reserved name is passed to React as a prop. <code>count</code>
          lives on the server; the step slider lives in React's <code>useState</code>, and the server never sees it.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Clicking a button calls <code>pushEvent("set_count", …)</code>, which reaches
          <code>handle_event/3</code>
          exactly as <code>phx-click</code>
          would. The server
          reassigns <code>count</code>, LiveReact diffs the props and sends only what
          changed, and React re-renders.
        </p>
        <p>
          Dragging the slider changes nothing on the server — that is the point. Local
          UI state stays local, and only what the server owns round-trips.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
