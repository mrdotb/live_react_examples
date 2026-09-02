defmodule LiveReactExamplesWeb.Examples.ServerEventsLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "server-events"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.ServerEventsPreview,
          id: "server-events-preview"
        )}
      </:preview>

      <:concepts>
        <p>
          <code>push_event/3</code> sends a one-off message from the server straight to the
          client — it is not a prop and does not go through a diff. React
          picks it up with <code>handleEvent</code>, registered once via <code>useEffect</code>.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Clicking a button is an ordinary <code>phx-click</code>, handled by
          <code>handle_event/3</code>
          on the server exactly as it would be outside
          LiveReact. Instead of reassigning a prop, the handler calls <code>push_event/3</code>
          with an event name and a payload map.
        </p>
        <p>
          On the client, <code>handleEvent("info", callback)</code> fires that
          callback the moment the event arrives, independently of any render
          — this is how a server-driven toast, a sound, or a one-shot
          animation reaches React without being modeled as state.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
