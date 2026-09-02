defmodule LiveReactExamplesWeb.Examples.PropsDiffingPreview do
  @moduledoc """
  The same component twice, bound to the same large payload: once with prop
  diffing on (the default) and once with `diff={false}`. Changing one field
  sends a single-field JSON patch to the diffed instance and the whole
  payload again to the other — a contrast that is invisible on the wire
  without opening a network inspector. LiveReact writes the real payload
  onto each instance's wrapper element as `data-props` and
  `data-props-diff`, so the React component reads those attributes itself
  and reports their byte length — this preview does not compute or guess
  the numbers.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, payload: build_payload(0)), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <.button phx-click="touch_one_field">Change one field</.button>

      <p class="text-sm text-muted-foreground">
        Each instance below reads its own <code>data-props</code>
        and <code>data-props-diff</code>
        attributes and reports their byte length — the diffed instance should show a
        small patch, the undiffed one a much larger payload and an empty diff.
      </p>

      <.react name="examples/PropsDiffing" label="diff={true}" payload={@payload} socket={@socket} />

      <.react
        name="examples/PropsDiffing"
        label="diff={false}"
        payload={@payload}
        diff={false}
        socket={@socket}
      />
    </div>
    """
  end

  def handle_event("touch_one_field", _params, socket) do
    {:noreply, assign(socket, payload: Map.update!(socket.assigns.payload, :counter, &(&1 + 1)))}
  end

  defp build_payload(counter) do
    %{
      counter: counter,
      rows: Enum.map(1..40, &%{id: &1, name: "row #{&1}", note: String.duplicate("x", 40)})
    }
  end
end
