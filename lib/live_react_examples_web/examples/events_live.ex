defmodule LiveReactExamplesWeb.Examples.EventsLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "events"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.EventsPreview, id: "events-preview")}
      </:preview>

      <:concepts>
        <p>
          <code>useLiveReact()</code>
          gives a component access to <code>pushEvent</code>
          without it being passed
          down as a prop. Calling it sends a message over the socket exactly
          as a <code>phx-click</code>
          or a form submit would.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Submitting the form calls <code>pushEvent</code>
          with the event name <code>"add_item"</code>
          and the typed text as its payload, which reaches <code>handle_event("add_item", …)</code>
          on the server. The
          server appends the item to its own <code>items</code>
          assign and reassigns
          it — LiveReact diffs the new list against the old one and only sends
          what changed.
        </p>
        <p>
          The event name and payload are entirely up to the component; nothing
          about this is specific to lists or to this example. Any <code>handle_event/3</code>
          clause the LiveView already has can be reached the same way.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
