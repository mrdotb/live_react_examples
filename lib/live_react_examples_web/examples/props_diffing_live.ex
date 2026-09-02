defmodule LiveReactExamplesWeb.Examples.PropsDiffingLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "props-diffing"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.PropsDiffingPreview,
          id: "props-diffing-preview"
        )}
      </:preview>

      <:concepts>
        <p>
          By default LiveReact sends only the part of a prop that changed, not the
          whole value. Both components below share one large <code>payload</code>
          assign; clicking the button changes a single field inside it. Only the
          changed path travels to the diffed instance — the other resends the entire
          payload on every update, because it opted out.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          LiveReact writes <code>data-use-diff</code>
          on the component's root element to say which mode it is in. When diffing is
          on, prop changes are computed as a JSON Patch and written to <code>data-props-diff</code>; the client applies that patch to the props it
          already has instead of receiving a new snapshot.
        </p>
        <p>
          Diffing is on by default, controlled globally by <code>config :live_react, :enable_props_diff</code>. Pass
          <code>{"diff={false}"}</code>
          on a single <code>{~s(<.react>)}</code>
          call to opt that instance out and always
          send the full prop value — useful when a prop is small enough that diffing is
          pure overhead, or when a component needs the complete value on every render.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
