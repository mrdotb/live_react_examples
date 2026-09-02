defmodule LiveReactExamplesWeb.Examples.PropsDiffingPreview do
  @moduledoc """
  The same component twice, bound to the same large payload: once with prop
  diffing on (the default) and once with `diff={false}`. Changing one field
  sends a single-field JSON patch to the diffed instance and the whole
  payload again to the other — a contrast that is invisible on the wire
  without opening a network inspector, so this preview computes and shows
  the byte counts itself, independently of LiveReact's internals, right on
  the page.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    payload = build_payload(0)

    {:ok,
     assign(socket,
       payload: payload,
       full_bytes: byte_size(Jason.encode!(payload)),
       patch_bytes: byte_size(Jason.encode!(%{counter: payload.counter}))
     ), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <.button phx-click="touch_one_field">Change one field</.button>

      <p class="text-sm text-muted-foreground">
        Last update: the diffed instance received a <strong>{@patch_bytes}-byte</strong>
        patch naming just <code>counter</code>; the undiffed instance received the whole
        <strong>{@full_bytes}-byte</strong>
        payload again.
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
    payload = Map.update!(socket.assigns.payload, :counter, &(&1 + 1))

    {:noreply,
     assign(socket,
       payload: payload,
       full_bytes: byte_size(Jason.encode!(payload)),
       patch_bytes: byte_size(Jason.encode!(%{counter: payload.counter}))
     )}
  end

  defp build_payload(counter) do
    %{
      counter: counter,
      rows: Enum.map(1..40, &%{id: &1, name: "row #{&1}", note: String.duplicate("x", 40)})
    }
  end
end
