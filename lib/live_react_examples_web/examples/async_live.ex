defmodule LiveReactExamplesWeb.Examples.AsyncLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "async"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.AsyncPreview, id: "async-preview")}
      </:preview>

      <:concepts>
        <p>
          <code>assign_async/3</code>
          in <code>mount/3</code>
          starts work in a linked process and immediately returns a
          <code>Phoenix.LiveView.AsyncResult</code>
          in its loading state. When the work finishes, LiveView updates the assign for
          you — either to a successful result or to a failure — with no <code>handle_info/2</code>
          to write.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The <code>AsyncResult</code>
          struct is passed straight to React as a prop, unchanged, because LiveReact
          ships an encoder for it. React reads <code>loading</code>, <code>ok</code>
          and <code>failed</code>
          directly off the prop rather than the server flattening them into three
          separate assigns and deciding which one to send.
        </p>
        <p>
          "Reload" re-runs the same async work; "Simulate failure" reruns it in a
          mode that returns <code>{"{:error, reason}"}</code>
          instead, so all three states — loading, ok and failed — are reachable from
          the page itself.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
