defmodule LiveReactExamplesWeb.Examples.LinkLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "link"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.LinkPreview, id: "link-preview")}
      </:preview>

      <:concepts>
        <p>
          <code>Link</code>
          is a drop-in replacement for a plain <code>&lt;a&gt;</code>
          that
          understands the same three navigation modes as HEEx's own <code>&lt;.link&gt;</code>: <code>href</code>,
          <code>patch</code>
          and <code>navigate</code>. It renders an ordinary anchor and lets
          Phoenix's own client-side JavaScript take over the click.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The first link uses <code>href</code>
          — a traditional anchor, a full
          browser navigation, no different from clicking a link on a page
          with no LiveView on it at all. The second uses <code>navigate</code>
          — the browser's URL changes, but the click is intercepted and
          handled entirely over the existing socket, mounting a new root
          LiveView with no full page reload.
        </p>
        <p>
          <code>patch</code>
          (not shown here, since it only makes sense for the
          LiveView that owns the current route — see the Patch vs Navigate
          example) works the same way but calls <code>handle_params/3</code>
          on the current LiveView instead of mounting a new one.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
