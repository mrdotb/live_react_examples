defmodule LiveReactExamplesWeb.Examples.StreamsLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "streams"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.StreamsPreview, id: "streams-preview")}
      </:preview>

      <:concepts>
        <p>
          <code>stream/4</code> manages a large or growing collection without keeping
          every item in LiveView memory or re-sending the whole list on every
          change. Assigning a stream to a prop hands React the current list
          as a plain array — inserts, updates, deletes and resets all arrive
          as ordinary prop diffs.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Every item in a stream carries a <code>__dom_id</code>
          key that
          LiveReact adds — a stable id derived from Phoenix's own stream ref,
          not from any field of the message itself. Use it, not <code>message.id</code>, as the React <code>key</code>: it stays
          correct across <code>stream_insert/3</code>, <code>stream_delete/3</code>
          and a full <code>reset: true</code>
          replacement, which is exactly what
          a stream's own DOM-patching semantics guarantee on the server side.
        </p>
        <p>
          <code>stream_insert(socket, :messages, message, update_only: true)</code>
          patches an item that's already on the page without moving or
          re-inserting it — that's what backs the "Edit" button, in contrast
          to a plain insert for "Send" and a full <code>reset: true</code>
          for "Replace all".
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
