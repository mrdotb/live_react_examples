defmodule LiveReactExamplesWeb.Examples.CounterLive do
  use LiveReactExamplesWeb, :live_view

  require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

  import LiveReactExamplesWeb.Examples.ExampleComponents

  alias LiveReactExamples.Examples

  @elixir_source ExampleSource.elixir_source("Counter")
  @react_source ExampleSource.react_source("Counter")

  def mount(_params, _session, socket) do
    {:ok, example} = Examples.fetch("counter")

    {:ok,
     assign(socket,
       page_title: "#{example.title} · LiveReact examples",
       example: example,
       elixir_source: @elixir_source,
       react_source: @react_source
     )}
  end

  def handle_params(params, _uri, socket) do
    tab = if params["tab"] in tabs(), do: params["tab"], else: "preview"
    {:noreply, assign(socket, :tab, tab)}
  end

  def render(assigns) do
    ~H"""
    <.example_page
      example={@example}
      tab={@tab}
      elixir_source={@elixir_source}
      react_source={@react_source}
    >
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.CounterPreview, id: "counter-preview")}
      </:preview>

      <:concepts>
        <p>
          Every assign that is not a reserved name is passed to React as a prop. <code>count</code>
          lives on the server; the step slider lives in React's <code>useState</code>
          and the server never sees it.
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
