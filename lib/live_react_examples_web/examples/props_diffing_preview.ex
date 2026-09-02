defmodule LiveReactExamplesWeb.Examples.PropsDiffingPreview do
  @moduledoc """
  The same component twice, bound to the same large payload: once with prop
  diffing on (the default) and once with `diff={false}`. Changing one field
  sends a single-field JSON patch to the diffed instance and the whole payload
  again to the other.

  Each instance measures what actually crossed the wire, by comparing its own
  `data-props` and `data-props-diff` attributes against their previous values.
  Reporting the *size* of `data-props` would be misleading: on a diffed
  component it holds the first snapshot and never changes again, so both
  instances would show a near-identical number while meaning entirely
  different things. What separates them is which attribute changed.
  """

  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, payload: build_payload(0)), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <.button phx-click="touch_one_field">Change one field</.button>

      <p class="text-sm text-[color:var(--text-muted)]">
        Each instance reports how many bytes actually changed on its wrapper element
        for the last update, and the running total. The diffed instance receives a
        small <code>data-props-diff</code>
        patch; the other receives the whole <code>data-props</code>
        payload again every time.
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
