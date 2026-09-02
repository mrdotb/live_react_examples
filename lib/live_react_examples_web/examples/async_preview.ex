defmodule LiveReactExamplesWeb.Examples.AsyncPreview do
  @moduledoc """
  Minimal working async assign. This module's source is displayed verbatim
  on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:mode, :ok) |> load_stats(), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex gap-2">
        <button type="button" class="rounded-md border px-3 py-1" phx-click="reload">
          Reload
        </button>
        <button type="button" class="rounded-md border px-3 py-1" phx-click="fail">
          Simulate failure
        </button>
      </div>

      <%!-- diff={false}: the AsyncResult swaps state wholesale (loading -> ok
      or failed), so there is nothing worth patching — send the whole
      value every time instead of a diff. --%>
      <.react name="examples/Async" stats={@stats} diff={false} socket={@socket} />
    </div>
    """
  end

  def handle_event("reload", _params, socket) do
    {:noreply, socket |> assign(:mode, :ok) |> load_stats()}
  end

  def handle_event("fail", _params, socket) do
    {:noreply, socket |> assign(:mode, :error) |> load_stats()}
  end

  defp load_stats(socket) do
    mode = socket.assigns.mode

    assign_async(socket, :stats, fn ->
      Process.sleep(400)

      case mode do
        :ok -> {:ok, %{stats: %{stars: 1234, downloads: 98_765}}}
        :error -> {:error, "the upstream service is unavailable"}
      end
    end)
  end
end
