defmodule LiveReactExamplesWeb.Examples.EncoderPreview.DemoUser do
  @moduledoc """
  A struct with a field that must never reach the browser. `@derive`
  decides what is serialisable; anything omitted is absent from the
  payload rather than merely hidden — the encoder never even looks at it.
  """
  @derive {LiveReact.Encoder, except: [:api_token]}
  defstruct [:name, :email, :api_token]
end

defmodule LiveReactExamplesWeb.Examples.EncoderPreview do
  @moduledoc """
  Minimal working custom encoder. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page
  chrome.
  """
  use LiveReactExamplesWeb, :live_view

  alias LiveReactExamplesWeb.Examples.EncoderPreview.DemoUser

  def mount(_params, _session, socket) do
    user = %DemoUser{
      name: "Ada Lovelace",
      email: "ada@example.com",
      api_token: "super-secret-never-sent"
    }

    {:ok, assign(socket, :user, user), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Encoder" user={@user} socket={@socket} />
    """
  end
end
