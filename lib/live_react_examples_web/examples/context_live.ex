defmodule LiveReactExamplesWeb.Examples.ContextLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "context"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.ContextPreview, id: "context-preview")}
      </:preview>

      <:concepts>
        <p>
          <code>count</code>
          is a server prop, assigned on the LiveView exactly like
          the Counter example. React's own <code>createContext</code>/<code>useContext</code>
          then shares that value with a nested component with no prop passed
          between them — the two mechanisms compose, they don't conflict.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          <code>Context</code>
          wraps its children in a <code>CountContext.Provider</code>
          whose value is the server-owned <code>count</code>
          prop. Any component
          inside that tree — however deeply nested — can call <code>useContext(CountContext)</code>
          to read it, without every
          component in between having to accept and forward a <code>count</code>
          prop it doesn't otherwise need.
        </p>
        <p>
          Clicking a button still calls <code>pushEvent("set_count", …)</code>,
          which reaches <code>handle_event/3</code>
          and reassigns <code>count</code>
          on the server, same as Counter — context describes how a value moves
          around inside React, not where it comes from.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
