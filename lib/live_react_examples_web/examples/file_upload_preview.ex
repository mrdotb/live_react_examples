defmodule LiveReactExamplesWeb.Examples.FileUploadPreview do
  @moduledoc """
  Minimal working file upload. This module's source is displayed verbatim on
  the example page, so it deliberately contains no page chrome.

  `consume_uploaded_entries/3` below never writes the uploaded file
  anywhere — it reads the client's own filename and discards the rest. A
  public demo site has no business persisting whatever a visitor uploads to
  it.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:uploaded_names, [])
     |> allow_upload(:avatar, accept: ~w(.png .jpg .jpeg), max_entries: 3), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react
      name="examples/FileUpload"
      avatar={@uploads.avatar}
      uploaded_names={@uploaded_names}
      socket={@socket}
    />
    """
  end

  def handle_event("submit", _params, socket) do
    uploaded_names =
      consume_uploaded_entries(socket, :avatar, fn %{path: _path}, entry ->
        {:ok, entry.client_name}
      end)

    {:noreply, update(socket, :uploaded_names, &(&1 ++ uploaded_names))}
  end
end
