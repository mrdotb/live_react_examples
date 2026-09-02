defmodule LiveReactExamplesWeb.Examples.HybridFormPreview do
  @moduledoc """
  Minimal working Hybrid Form example. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    form =
      to_form(%{"email" => "hello@mrdotb.com", "delay_between" => [4_000, 30_000]}, as: :settings)

    {:ok, assign(socket, form: form), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.simple_form id="settings-form" for={@form} phx-change="validate" phx-submit="submit">
      <.input field={@form[:email]} label="Email" />
      <.react
        name="examples/HybridForm"
        inputName="settings[delay_between]"
        value={@form[:delay_between].value}
        min={2_000}
        max={90_000}
        step={2_000}
        socket={@socket}
      />
      <:actions>
        <.button>Save</.button>
      </:actions>
    </.simple_form>
    """
  end

  def handle_event("validate", %{"settings" => settings}, socket) do
    form = to_form(settings, as: :settings, action: :validate)
    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", _params, socket) do
    {:noreply, socket}
  end
end
