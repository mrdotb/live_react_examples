defmodule LiveReactExamplesWeb.LiveDemoAssigns do
  @moduledoc """
  Assigns the current demo state.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  # A `live_render`'d child LiveView (e.g. an example preview embedded in
  # the example page) has a non-nil `parent_pid` and must not have this hook
  # attached: `attach_hook(..., :handle_params, ...)` on a child raises,
  # since children never receive `handle_params`. Skipping the attach here —
  # rather than requiring every child LiveView to defensively `detach_hook`
  # in its own `mount/3` — means a child module needs no plumbing at all to
  # be embedded safely.
  def on_mount(:default, _params, _session, %{parent_pid: nil} = socket) do
    socket = attach_hook(socket, :active_tab, :handle_params, &set_active_demo/3)
    {:cont, socket}
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}

  defp set_active_demo(_params, _url, socket) do
    demo =
      case {socket.view, socket.assigns.live_action} do
        {LiveReactExamplesWeb.LiveCounter, _} ->
          :counter

        {LiveReactExamplesWeb.LiveLogList, _} ->
          :log_list

        {LiveReactExamplesWeb.LiveFlashSonner, _} ->
          :flash_sonner

        {LiveReactExamplesWeb.LiveSSR, _} ->
          :ssr

        {LiveReactExamplesWeb.LiveHybridForm, _} ->
          :hybrid_form

        {LiveReactExamplesWeb.LiveSlot, _} ->
          :slot

        {LiveReactExamplesWeb.LiveContext, _} ->
          :context

        {LiveReactExamplesWeb.LiveLinkDemo, _} ->
          :link_demo

        {LiveReactExamplesWeb.LiveLinkUsage, _} ->
          :link_usage

        {LiveReactExamplesWeb.LiveStreamDemo, _} ->
          :stream_demo

        {_view, _live_action} ->
          nil
      end

    {:cont, assign(socket, demo: demo)}
  end
end
