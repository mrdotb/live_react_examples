defmodule LiveReactExamplesWeb.Examples.StreamsPreview do
  @moduledoc """
  Minimal working Streams example. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  @chatter [
    "turns out it was DNS. it's always DNS.",
    "works on my machine 🤷",
    "the bug fixed itself. I don't trust it.",
    "coffee count: 4. regrets: 0.",
    "ship it 🚢"
  ]

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:next_id, 1)
      |> stream(:messages, [%{id: 0, text: "hey, anyone here? 👋"}])

    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Streams" messages={@streams.messages} socket={@socket} />
    """
  end

  # A brand new message is appended to the stream.
  def handle_event("add", params, socket) do
    id = socket.assigns.next_id

    socket =
      socket
      |> assign(:next_id, id + 1)
      |> stream_insert(:messages, %{id: id, text: message_text(params)})

    {:noreply, socket}
  end

  # `update_only: true` patches a message already on the page, without
  # moving it or re-inserting it if it's gone.
  def handle_event("edit", %{"id" => id} = params, socket) do
    message = %{id: id, text: message_text(params)}
    {:noreply, stream_insert(socket, :messages, message, update_only: true)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:noreply, stream_delete(socket, :messages, %{id: id})}
  end

  # `reset: true` throws the whole conversation away and starts a new one.
  def handle_event("replace_all", _params, socket) do
    id = socket.assigns.next_id

    messages =
      @chatter
      |> Enum.shuffle()
      |> Enum.take(3)
      |> Enum.with_index(id)
      |> Enum.map(fn {text, index} -> %{id: index, text: text} end)

    socket =
      socket
      |> assign(:next_id, id + length(messages))
      |> stream(:messages, messages, reset: true)

    {:noreply, socket}
  end

  defp message_text(%{"text" => text}) do
    case String.trim(text) do
      "" -> Enum.random(@chatter)
      text -> text
    end
  end

  defp message_text(_params), do: Enum.random(@chatter)
end
